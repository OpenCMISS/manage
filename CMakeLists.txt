########################################################
# Welcome to the OpenCMISS build system!
########################################################
# This script realises the top-level setup/generation
# phase. All it does is making sure you have the minimum
# cmake version available (if not, you can have us build for you)
# and generates the actual main build project for any
# choice of compiler/toolchain and MPI combination
# you'd like.
#
# The easiest thing to do is nothing: CMake will detect
# the system's default setup and try to use that.
#
# ==============================
# Toolchain setup - details
# ==============================
# Usually you dont need to tell CMake which compilers to use.
# If you change compilers here, YOU SHOULD KNOW WHY!!!
# If by some chance you have to, first try to specify your
# desired toolchain via either CMakeGUI or -D command line
# as one of the following: 
# - gnu,mingw        # gcc,g++ and gfortran compilers
# - intel      # icc, icpc, ifort compilers
# - ibm        # xlc, xlC, xlf95 compilers
# Note that this variable will be used case-insensitive.
#
# If this does not cover you needs, you can specify each compiler using the CMAKE_<lang>_COMPILER variables,
# where <lang> can be each of "C","CXX" or "Fortran".
# For example, to have CMake use the GNU C compiler, set the binary name via e.g. 
# -DCMAKE_C_COMPILER gcc
# If that can not be found on CMake's PATH, you should specify an absolute path to the binary like
# -DCMAKE_C_COMPILER /usr/local/mygcc/bin/gcc
#
# If you still fail to have CMake successfully configure OpenCMISS with non-default compilers, please contact the OpenCMISS Team.
#
# ==============================
# MPI
# ==============================
# MPI is a crucial part of OpenCMISS and defaults to be used.
# You should not have to specify a specific MPI implementation, however, here
# are the options:
#
# To select an MPI implementation, you can use the MPI
# variable the same way by choosing from:
# mpich mpich2 openmpi mvapich2 intel none
#
# The selection "none" will build OpenCMISS without MPI,
# which is intended for future use but not implemented
# yet.
#
# To have MPI build in debug mode, set DEBUG_MPI=YES (Default: NO)
# This is only guaranteed to work for own MPI builds yet.
#
# - ALTERNATIVELY -
# You can also specify a custom MPI root directory to have CMake look there EXCLUSIVELY.
#SET(MPI_HOME ~/software/openmpi-1.8.3_install)

# - ALTERNATIVELY -
# Further, you can specify an explicit name of the compiler executable (full path or just the binary name)
# This can be used independently of (but possibly with) the MPI_HOME setting.
#SET(MPI_C_COMPILER mpicc)
#SET(MPI_CXX_COMPILER mpic++)
#SET(MPI_Fortran_COMPILER mpif77)

########################################################
# If your cmake is older than 2.6 - goodbye. 
CMAKE_MINIMUM_REQUIRED(VERSION 2.6.0 FATAL_ERROR)
# Set the manage directory
SET(OPENCMISS_MANAGE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
# The default opencmiss root is the parent directory of "manage"
SET(OPENCMISS_ROOT "${OPENCMISS_MANAGE_DIR}/.." CACHE PATH "Root directory for OpenCMISS.")
if (ROOT)
    SET(OPENCMISS_ROOT "${ROOT}" CACHE PATH "Root directory for OpenCMISS." FORCE)
endif(ROOT)
get_filename_component(OPENCMISS_ROOT ${OPENCMISS_ROOT} ABSOLUTE)

# Set up include path required at this stage
LIST(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts
    ${OPENCMISS_MANAGE_DIR}/Config)

# This ensures that CMake is new enough before anything else is done
# If its too old, the script will stop with an appropriate error message.
# The option is to either come up with a sufficiently new version yourself,
# or to build cmake using the (then generated) "cmake" target.
include(CMakeCheck)
if (NOT CMAKE_COMPATIBLE)
    return()
endif(NOT CMAKE_COMPATIBLE)
############################## END OF FULLY BACKWARDS-COMPATIBLE PART ###############################

# We start a fake project here that will use any encountered C compiler here.
# It will NOT be used (unless we let cmake use its defaults), but starting a project is
# initializing a lot more CMake variables that ensure proper functionality of all cmake commands
# (e.g. find_library does not "work" if issued before a project command, as the CMAKE_FIND_LIBRARY_SUFFIXES are still empty)
#
# The variable CMAKE_MIN_VERSION is set inside the CMakeCheck script
CMAKE_MINIMUM_REQUIRED(VERSION ${CMAKE_MIN_VERSION} FATAL_ERROR)
project(OpenCMISS-Generate-Build C)

# See if we have a specified toolchain
if (DEFINED TOOLCHAIN)
    string(TOLOWER ${TOOLCHAIN} TOOLCHAIN)
    SET(TC_PART ${TOOLCHAIN})
else()
    # if unspecified but we're on MINGW, use that instead of "default"
    if (MINGW)
        set(TC_PART mingw) 
    else()
        set(TC_PART default) # "default" name
    endif()
endif()

# MPI
if (DEFINED MPI)
    string(TOLOWER ${MPI} MPI)
endif()
# Whether to allow a system search for MPI implementations
option(SYSTEM_MPI "Allow to use a system MPI if found" YES)
option(DEBUG_MPI "Use DEBUG version of MPI (works only for own builds thus far)" NO)
if (DEBUG_MPI)
    set(MPI_BUILD_TYPE debug)
else()
    set(MPI_BUILD_TYPE release)
endif()
unset(_SYSMPI_DEF)
include(MPIPreflight)

# This is the main build file location for each compiler/mpi combination.
# We need to have different base folders for MPI in release/debug modes.
SET(BUILD_IDENT compiler.${TC_PART}-mpi.${MPI}.${MPI_BUILD_TYPE}) # dont care, take anything to combine stuff
SET(MAIN_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${BUILD_IDENT})
file(MAKE_DIRECTORY ${MAIN_BINARY_DIR})

# # Create a local config file at target folder if not exists
include(CreateLocalConfig)

# Configure the main build CMakeLists.txt
if (TOOLCHAIN)
    SET(TOOLCHAIN_DEF "SET(TOOLCHAIN ${TOOLCHAIN})")
endif()
if (MPI_HOME)
    SET(MPI_HOME_DEF "SET(MPI_HOME ${MPI_HOME})")
endif()
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${OPENCMISS_ROOT}/install CACHE STRING "OpenCMISS installation root" FORCE)
endif()
configure_file(
    ${OPENCMISS_MANAGE_DIR}/Templates/CMakeLists.main.template.cmake # from
    ${MAIN_BINARY_DIR}/CMakeLists.txt # to
    @ONLY # only @-tags
)

# Actual main project here
include(ExternalProject)
ExternalProject_Add(opencmiss_build_${BUILD_IDENT}
    PREFIX ${MAIN_BINARY_DIR}
    TMP_DIR ${MAIN_BINARY_DIR}/ep_tmp
    STAMP_DIR ${MAIN_BINARY_DIR}/ep_stamps
    DOWNLOAD_COMMAND ""
    CMAKE_COMMAND ${MY_CMAKE_COMMAND} # Set in Config/CMakeCheck.cmake, might be own build
    SOURCE_DIR ${MAIN_BINARY_DIR}
    BUILD_IN_SOURCE 1 # replaces the build command
    #CMAKE_ARGS ${BUILD_ARGS}
    INSTALL_COMMAND "" # no install on main build level
)

# Convenience/Maintenance targets
# Add target that executes the update command of the generated main build.
# This is not global, as different configurations might use only a fraction of the sources,
# and each of them only wants their choices updated.
add_custom_target(update
    COMMAND ${CMAKE_COMMAND} --build ${MAIN_BINARY_DIR} --target update
)
# Forward examples target
add_custom_target(examples
    COMMAND ${CMAKE_COMMAND} --build ${MAIN_BINARY_DIR} --target examples
)

if (UNIX)
    add_custom_target(reset_current
        COMMAND mv ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake ../backup_localconfig.tmp
        COMMAND rm -rf ${BUILD_IDENT}/*
        COMMAND mv ../backup_localconfig.tmp ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake
        COMMENT "Blowing away main build config files"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    add_custom_target(reset_all
        COMMAND rm -rf ${OPENCMISS_ROOT}/build ${OPENCMISS_ROOT}/install/
        COMMAND mv ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake ../backup_localconfig.tmp
        COMMAND rm -rf ${BUILD_IDENT}/*
        COMMAND mv ../backup_localconfig.tmp ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake
        COMMENT "Blowing away main build config files and build/ and install/ folders"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endif()

# This script dumps all available variables if invoked with "-DUMP=YES" :-)
include(OCMSupportHelper)

# Print a neat summary
message(STATUS "@@@@@@@@@@@@@@ TOOLCHAIN & MPI SETUP SUMMARY @@@@@@@@@@@@@@")
message(STATUS "*")
message(STATUS "* OPENCMISS_ROOT: ${OPENCMISS_ROOT}")
message(STATUS "* OPENCMISS_MANAGE_DIR: ${OPENCMISS_MANAGE_DIR}")
message(STATUS "* Main build directory: ${MAIN_BINARY_DIR}")
message(STATUS "* MPI implementation: ${MPI}")
if (MPI_HOME)
    message(STATUS "* MPI HOME: ${MPI_HOME}")
endif()
if (TOOLCHAIN)
    message(STATUS "* TOOLCHAIN: ${TOOLCHAIN}")
endif()
message(STATUS "*")
message(STATUS "@@@@@@@@@@@@@@@@@@@ NEXT STEPS @@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "*")
message(STATUS "* Change ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake according to your setup/needs")
message(STATUS "* Run your native build command (${CMAKE_MAKE_PROGRAM}) to start the build process")
message(STATUS "* Refer to ${OPENCMISS_MANAGE_DIR}/OpenCMISSBuildEnvironment.docx.pdf for customization instructions")
message(STATUS "*")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
