CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)

SET(OPENCMISS_SETUP_DIR ${CMAKE_CURRENT_SOURCE_DIR})
# The default opencmiss root is the parent directory of /setup
if (NOT OPENCMISS_ROOT)
    SET(OPENCMISS_ROOT ${OPENCMISS_SETUP_DIR}/..)
endif()
get_filename_component(OPENCMISS_ROOT ${OPENCMISS_ROOT} ABSOLUTE)
message(STATUS "Having OpenCMISS root at ${OPENCMISS_ROOT}")

# Set up include path
LIST(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_SETUP_DIR}
    ${OPENCMISS_SETUP_DIR}/CMakeFindModuleWrappers
    ${OPENCMISS_SETUP_DIR}/CMakeModules
    ${OPENCMISS_SETUP_DIR}/CMakeScripts
    ${OPENCMISS_SETUP_DIR}/Config)
  
# This ensures that CMake is new enough before anything else is done
include(CMakeCheck)

########################################################################
# Read configuration (defaults & local)
# If no configuration dir is passed, use the current build location
if(NOT OPENCMISS_CONFIG_DIR)
    SET(OPENCMISS_CONFIG_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()
# Create a local config file if not exists
include(CreateLocalConfig)

# This includes the configuration, both default and local
include(OpenCMISSConfig)

# Between reading the config and starting the setup project.. this is the time for compiler stuff!
include(ToolchainSetup)

########################################################################
# Start actual setup
CMAKE_MINIMUM_REQUIRED(VERSION 3.2.0-rc1 FATAL_ERROR)
project(OpenCMISS-Setup VERSION 1.0 LANGUAGES C CXX Fortran)
if (NOT WIN32 AND CMAKE_BUILD_TYPE STREQUAL "")
    SET(CMAKE_BUILD_TYPE RELEASE)
    message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
endif()

include(ExternalProject)

########################################################################
# Utilities (Wrappers, MPI-pre-check, ...)
include(Utilities)

# Multithreading
if(OCM_USE_MT)
    find_package(OpenMP REQUIRED)
endif()

# MPI
if(OCM_USE_MPI)
    include(MPIChecks)
endif()

########################################################################
# Checks for known issues
if (CMAKE_COMPILER_IS_GNUC AND MPI STREQUAL intel)
    message(FATAL_ERROR "Invalid compiler/MPI combination: Cannot build with GNU compiler and Intel MPI.")
endif()

########################################################################
# General paths & preps
include(OCMSetupArchitecture)
get_architecture_path(ARCHITECTURE_PATH)
# this is the <kickoff> part / main build tree configuration part 
# DISABLED - kickoff
#get_filename_component(BUILDNAME ${CMAKE_CURRENT_BINARY_DIR} NAME)

########################################################################
# Build tree location for components
SET(OPENCMISS_COMPONENTS_BINARY_DIR ${OPENCMISS_ROOT}/build/${ARCHITECTURE_PATH})
# DISABLED - kickoff
#SET(OPENCMISS_COMPONENTS_BINARY_DIR ${OPENCMISS_ROOT}/build/${BUILDNAME}/${ARCHITECTURE_PATH})

########################################################################
# Install dir
# Extra path segment for single configuration case - will give release/debug/...
get_build_type_extra(BUILDTYPEEXTRA)
# everything from the OpenCMISS main project goes into install/
SET(OPENCMISS_COMPONENTS_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/${ARCHITECTURE_PATH}/${BUILDTYPEEXTRA})
# DISABLED - kickoff
#SET(OPENCMISS_COMPONENTS_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/${BUILDNAME}/${ARCHITECTURE_PATH}/${BUILDTYPEEXTRA})

########################################################################
# Collect the common arguments for any package/component
include(CollectComponentDefinitions)
#message(STATUS "OpenCMISS components common definitions:\n${COMPONENT_COMMON_DEFS}")

SET(_OCM_REQUIRED_SOURCES )
SET(_OCM_NEED_INITIAL_SOURCE_DOWNLOAD NO)

include(OCMSetupBuildMacros)
########################################################################
# Dependencies
include(Dependencies)

########################################################################
# Iron
include(Iron)

# Finally, create the download target that depends on all other downloads
SET(_OCM_SOURCE_UPDATE_TARGETS )
SET(_OCM_SOURCE_DOWNLOAD_TARGETS )
foreach(_COMP ${_OCM_REQUIRED_SOURCES})
    LIST(APPEND _OCM_SOURCE_UPDATE_TARGETS ${_COMP}_SRC-update)
    LIST(APPEND _OCM_SOURCE_DOWNLOAD_TARGETS ${_COMP}_SRC-download)
endforeach()
add_custom_target(update
    DEPENDS ${_OCM_SOURCE_UPDATE_TARGETS}
)
# I already foresee that we will have to have "download" and "update" targets for the less insighted user.
# So lets just give it to them. Does the same as external project has initial download and update steps.
add_custom_target(download 
    DEPENDS ${_OCM_SOURCE_DOWNLOAD_TARGETS}
)