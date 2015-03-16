########################################################
# Welcome to the OpenCMISS build system!
########################################################
# This script realises the top-level setup/generation
# phase. All it does is making sure you have the minimum
# cmake version available (if not, it's build for you!)
# and generates the actual main build project for any
# choice of compiler/toolchain and MPI combination
# you'd like.
#
# The easiest thing to do is nothing: CMake will detect
# the system's default setup and try to use that.
#
# To select the toolchain, define the TOOLCHAIN variable
# (either via CMakeGUI or -D command line as one of the
# following: gnu intel ibm
#
# To select an MPI implementation, you can use the MPI
# variable the same way by choosing from: mpich mpich2
# openmpi mvapich2 intel none
#
# The selection "none" will build OpenCMISS without MPI,
# which is intended for future use but not implemented
# yet.
#
########################################################

CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
# We start a fake project here that will use any encountered C compiler here.
# It will NOT be used (unless we let cmake use its defaults), but starting a project is
# initializing a lot more CMake variables that ensure proper functionality of all cmake commands
# (e.g. find_library does not "work" if issued before a project command, as the CMAKE_FIND_LIBRARY_SUFFIXES are still empty)
project(opencmiss-generate-build C)

# Set the setup directory
SET(OPENCMISS_SETUP_DIR ${CMAKE_CURRENT_SOURCE_DIR})
# The default opencmiss root is the parent directory of /setup
if (NOT OPENCMISS_ROOT)
    SET(OPENCMISS_ROOT ${OPENCMISS_SETUP_DIR}/..)
endif()
get_filename_component(OPENCMISS_ROOT ${OPENCMISS_ROOT} ABSOLUTE)
message(STATUS "OpenCMISS root will be ${OPENCMISS_ROOT}")

# Set up include path required at this stage
LIST(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_SETUP_DIR}/CMakeScripts
    ${OPENCMISS_SETUP_DIR}/Config)

# This ensures that CMake is new enough before anything else is done
include(CMakeCheck)

# See if we have a specified toolchain
if (DEFINED TOOLCHAIN)
    string(TOLOWER ${TOOLCHAIN} TOOLCHAIN)
    SET(TC_PART ${TOOLCHAIN})
else()
    set(TC_PART default) # "default" name
endif()

# See if we have to suggest/detect MPI if not specified explicitly
# Note:
# This will make sure to have MPI set (also possible: "none" or "unknown")
option(ALLOW_SYSTEM_MPI "Prefer local system MPI implementations over own builds" YES)
include(MPIPreflight)

# This is the main build file location for each compiler/mpi combination.
SET(BUILD_IDENT compiler.${TC_PART}-mpi.${MPI}) # dont care, take anything to combine stuff
SET(MAIN_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${BUILD_IDENT}) # ${OPENCMISS_SETUP_DIR}
file(MAKE_DIRECTORY ${MAIN_BINARY_DIR})

# # Create a local config file at target folder if not exists
include(CreateLocalConfig)
CREATE_OPENCMISS_LOCALCONFIG(${MAIN_BINARY_DIR})

# Configure the main build CMakeLists.txt
if (TOOLCHAIN)
    SET(TOOLCHAIN_DEF "SET(TOOLCHAIN ${TOOLCHAIN})")
endif()
if (MPI_HOME)
    SET(MPI_HOME_DEF "SET(MPI_HOME ${MPI_HOME})")
endif()
configure_file(
    ${OPENCMISS_SETUP_DIR}/CMakeScripts/CMakeLists.main.template.cmake # from
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
