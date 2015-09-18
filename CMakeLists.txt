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

# ==============================
# Developer setup
# ==============================
# If you want to initialize your OpenCMISS installation to developer defaults,
# add the line "-DEVIL=666" (not a typo!) to your initial cmake call. Done.

########################################################
# If your cmake is older than 2.6 - goodbye. 
cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)
# Set the manage directory
SET(OPENCMISS_MANAGE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
# The default opencmiss root is the parent directory of "manage"
SET(OPENCMISS_ROOT "${OPENCMISS_MANAGE_DIR}/.." CACHE PATH "Root directory for OpenCMISS.")
if (ROOT)
    SET(OPENCMISS_ROOT "${ROOT}" CACHE PATH "Root directory for OpenCMISS." FORCE)
endif(ROOT)
get_filename_component(OPENCMISS_ROOT ${OPENCMISS_ROOT} ABSOLUTE)

# Set up include path required at this stage
list(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts
    ${OPENCMISS_MANAGE_DIR}/CMakeModules
    ${OPENCMISS_MANAGE_DIR}/Config)

# This ensures that CMake is new enough before anything else is done
# If its too old, the script will stop with an appropriate error message.
# The option is to either come up with a sufficiently new version yourself,
# or to build cmake using the (then generated) "cmake" target.
include(OCCMakeCheck)
# Need to make this outside the include as the return is intended for the main level
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
cmake_minimum_required(VERSION ${OPENCMISS_CMAKE_MIN_VERSION} FATAL_ERROR)
project(OpenCMISS-Generate-Build C)

# See if we have a specified toolchain
if (DEFINED TOOLCHAIN)
    string(TOLOWER ${TOOLCHAIN} TOOLCHAIN)
    set(TC_PART ${TOOLCHAIN})
else()
    # if unspecified but we're on MINGW, use that instead of "default"
    if (MINGW)
        set(TC_PART mingw) 
    else()
        set(TC_PART default) # "default" name
    endif()
endif()

# MPI
include(OCMPIPreflight)

# This is the main build file location for each compiler/mpi combination.
# We need to have different base folders for MPI in release/debug modes.
string(TOLOWER "${MPI_BUILD_TYPE}" _MPI_BUILD_TYPE)
set(BUILD_IDENT compiler.${TC_PART}-mpi.${MPI}.${_MPI_BUILD_TYPE}) # dont care, take anything to combine stuff
unset(_MPI_BUILD_TYPE)
set(MAIN_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${BUILD_IDENT}")
file(MAKE_DIRECTORY "${MAIN_BINARY_DIR}")

# # Create a local config file at target folder if not exists
include(OCCreateLocalConfig)

# Configure the main build CMakeLists.txt
if (TOOLCHAIN)
    SET(TOOLCHAIN_DEF "set(TOOLCHAIN ${TOOLCHAIN})")
endif()
if (MPI_HOME)
    SET(MPI_HOME_DEF "set(MPI_HOME ${MPI_HOME})")
endif()
configure_file(
    "${OPENCMISS_MANAGE_DIR}/Templates/CMakeLists.main.template.cmake" # from
    "${MAIN_BINARY_DIR}/CMakeLists.txt" # to
    @ONLY # only @-tags
)

# This makes sure the configure step for the current main project is run at the beginning;
# later the build call to the main project will detect for itself if new builds are necessary.
#add_custom_command(OUTPUT ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake
add_custom_command(OUTPUT "${MAIN_BINARY_DIR}/configure_stamp"
    COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
    COMMAND ${CMAKE_COMMAND} -E touch "${MAIN_BINARY_DIR}/configure_stamp"
    WORKING_DIRECTORY "${MAIN_BINARY_DIR}"
    COMMENT "Initializing OpenCMISS configuration ${BUILD_IDENT}"
)
# This creates the main target 
add_custom_target(${BUILD_IDENT} ALL
    DEPENDS "${MAIN_BINARY_DIR}/configure_stamp"
    # Invoke main build
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target install
    # Invoke feature tests
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target featuretests
    COMMENT "Building OpenCMISS configuration ${BUILD_IDENT}"
)

# Convenience/Maintenance targets
# Add target that executes the update command of the generated main build.
# This is not global, as different configurations might use only a fraction of the sources,
# and each of them only wants their choices updated.
add_custom_target(update
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target update
)
# Forward examples target, test and support
add_custom_target(examples
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target EXAMPLES
)
add_custom_target(examples-test
    DEPENDS examples
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target examples-test
)
add_custom_target(support
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target support
)

# DANGER ZONE
add_custom_target(reset_current
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target reset
    COMMAND ${CMAKE_COMMAND} -E copy ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake ../backup_localconfig.tmp
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${BUILD_IDENT}
    COMMAND ${CMAKE_COMMAND} -E copy ../backup_localconfig.tmp ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake
    COMMAND ${CMAKE_COMMAND} -E remove ../backup_localconfig.tmp
    COMMENT "Resetting ${BUILD_IDENT}: Blowing away build files, preserving OpenCMISSLocalConfig"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
)
add_custom_target(reset_current_mpionly
    COMMAND ${CMAKE_COMMAND} --build "${MAIN_BINARY_DIR}" --target reset_mpionly
    COMMAND ${CMAKE_COMMAND} -E copy ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake ../backup_localconfig.tmp
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${BUILD_IDENT}
    COMMAND ${CMAKE_COMMAND} -E copy ../backup_localconfig.tmp ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake
    COMMAND ${CMAKE_COMMAND} -E remove ../backup_localconfig.tmp
    COMMENT "Resetting ${BUILD_IDENT}: Blowing away MPI-related build files, preserving OpenCMISSLocalConfig"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
)
add_custom_target(utter_destruction
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_ROOT}/build"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_ROOT}/install"
    COMMAND ${CMAKE_COMMAND} -E copy ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake ../backup_localconfig.tmp
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${BUILD_IDENT}
    COMMAND ${CMAKE_COMMAND} -E copy ../backup_localconfig.tmp ${BUILD_IDENT}/OpenCMISSLocalConfig.cmake
    COMMAND ${CMAKE_COMMAND} -E remove ../backup_localconfig.tmp
    COMMENT "BAM! Deleting build & install folders. Only keeping OpenCMISSLocalConfig from last configuration in ${BUILD_IDENT}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
)

# The Devil's part!
# Used if one defines -DEVIL on the command line. Just a convenience hack to have
# OpenCMISS copy the developer defaults config file over.
if (DEFINED EVIL OR EVIL)
    if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OpenCMISSDeveloper.cmake")
        configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/Templates/OpenCMISSDeveloper.template.cmake"
            "${CMAKE_CURRENT_SOURCE_DIR}/OpenCMISSDeveloper.cmake"
            COPYONLY)
        set(EVIL_MESSAGE "Being a Developer! Evilness level: ${EVIL}. Copied the OpenCMISSDeveloper template.")
    else()
        set(EVIL_MESSAGE "OpenCMISSDeveloper script already copied. Not overwriting.")
    endif()
endif()

# Print a neat summary
message(STATUS "@@@@@@@@@@@@@@@@@@@ SETUP SUMMARY @@@@@@@@@@@@@@@@@@@")
message(STATUS "*")
message(STATUS "* OPENCMISS_ROOT: ${OPENCMISS_ROOT}")
if (OPENCMISS_REMOTE_INSTALL_DIR)
    message(STATUS "* OPENCMISS_REMOTE_INSTALL_DIR: ${OPENCMISS_REMOTE_INSTALL_DIR}")
endif()
message(STATUS "* OPENCMISS_MANAGE_DIR: ${OPENCMISS_MANAGE_DIR}")
message(STATUS "* Main build directory: ${MAIN_BINARY_DIR}")
message(STATUS "* MPI implementation: ${MPI}")
if (MPI_HOME)
    message(STATUS "* MPI HOME: ${MPI_HOME}")
endif()
if (TOOLCHAIN)
    message(STATUS "* TOOLCHAIN: ${TOOLCHAIN}")
endif()
if (DEFINED EVIL)
    message(STATUS "* ${EVIL_MESSAGE}")
endif()
message(STATUS "*")
message(STATUS "@@@@@@@@@@@@@@@@@@@ NEXT STEPS @@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "*")
message(STATUS "* Change ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake according to your setup/needs")
if (DEFINED EVIL)
    message(STATUS "* Change ${CMAKE_CURRENT_SOURCE_DIR}/OpenCMISSDeveloper.cmake according to your developing setup/needs (Overrides anything in OpenCMISSLocalConfig!)")        
endif()
message(STATUS "* Run your native build command (e.g. '${CMAKE_MAKE_PROGRAM}') to start the build process")
message(STATUS "* Refer to ${OPENCMISS_MANAGE_DIR}/OpenCMISSBuildEnvironment.docx.pdf for customization instructions")
message(STATUS "*")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
