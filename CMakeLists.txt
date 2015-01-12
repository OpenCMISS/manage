CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)

#include(CMakeScripts/FunctionDefinitions.cmake)
#PRINT_VARS()
#return()

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

# This ensures that CMake is new enough before anything
include(CMakeCheck)

########################################################################
# Start actual setup
CMAKE_MINIMUM_REQUIRED(VERSION 3.0 FATAL_ERROR)
project(OpenCMISS-Setup VERSION 1.0 LANGUAGES C CXX Fortran)
if (NOT WIN32 AND NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE RELEASE)
    message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
endif()

########################################################################
# Read configuration (defaults & local)
# If no configuration dir is passed, use the current build location
if(NOT OPENCMISS_CONFIG_DIR)
    SET(OPENCMISS_CONFIG_DIR ${CMAKE_CURRENT_BINARY_DIR})
endif()
include(CreateLocalConfig)

# This includes the configuration, both default and local
include(OpenCMISSConfig)

# ABI detection
#if (NOT ABI)
    # Rough detection if not specified..
#    if (${CMAKE_SYSTEM_PROCESSOR} MATCHES 64)
#        SET(ABI 64)
#    else()
#        SET(ABI 32)
#    endif()
#endif()
#foreach(lang C CXX Fortran)
#    SET(CMAKE_${lang}_FLAGS "-m${ABI} ${CMAKE_${lang}_FLAGS}")
#endforeach()

include(ExternalProject)

########################################################################
# Utilities (Wrappers, MPI, ...)
include(Utilities)
if(BUILDING_MPI)
    return()
endif()

if(OCM_USE_MT)
    find_package(OpenMP REQUIRED)
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
get_filename_component(BUILDNAME ${CMAKE_CURRENT_BINARY_DIR} NAME)

########################################################################
# Build tree location for components
SET(OPENCMISS_COMPONENTS_BINARY_DIR ${OPENCMISS_ROOT}/build/${BUILDNAME}/${ARCHITECTURE_PATH})

########################################################################
# Install dir
# Extra path segment for single configuration case - will give release/debug/...
get_build_type_extra(BUILDTYPEEXTRA)
# everything from the OpenCMISS main project goes into install/
SET(OPENCMISS_COMPONENTS_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/${BUILDNAME}/${ARCHITECTURE_PATH}/${BUILDTYPEEXTRA})

########################################################################
# Collect the common arguments for any package/component
include(CollectComponentDefinitions)
#message(STATUS "OpenCMISS components common definitions:\n${COMPONENT_COMMON_DEFS}")

include(OCMSetupBuildMacros)
########################################################################
# Dependencies
include(Dependencies)

########################################################################
# Iron
include(Iron)