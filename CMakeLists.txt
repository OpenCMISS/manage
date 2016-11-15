
########################################################
# If your cmake is older than 3.4 - goodbye. 
cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

########################################################################
# Ready to start the "build project"
project(OpenCMISS-Manage VERSION 1.0.0 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

# Determine if the OpenCMISSInstallationConfig should be considered finalised or not.
if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/config OR EXISTS ${CMAKE_CURRENT_BINARY_DIR}/configs)
    set(_INSTALLATION_CONFIG_FINALISED TRUE)
else ()
    set(_INSTALLATION_CONFIG_FINALISED FALSE)
endif ()

# The default opencmiss root is the grandparent directory of "manage"
if (NOT DEFINED OPENCMISS_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
    if (NOT DEFINED OPENCMISS_LIBRARIES_ROOT AND NOT DEFINED OPENCMISS_DEPENDENCIES_ROOT AND NOT DEFINED OPENCMISS_CMAKE_MODULES_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
        # Standard installation scenario and the module path can be found relative to this directory
        get_filename_component(OPENCMISS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
    endif ()
    if (NOT DEFINED OPENCMISS_CMAKE_MODULES_PATH)
        # Standard installation scenario and the module path can be found relative to this directory
        get_filename_component(OPENCMISS_CMAKE_MODULES_PATH "${CMAKE_CURRENT_LIST_DIR}/../../install/share/cmake" REALPATH) 
    endif ()
endif ()

if (DEFINED OPENCMISS_ROOT)
    if (_INSTALLATION_CONFIG_FINALISED)
        unset(OPENCMISS_ROOT CACHE)
    else ()
        set(OPENCMISS_ROOT ${OPENCMISS_ROOT} CACHE PATH "Root location for building OpenCMISS from source.")
        set(OPENCMISS_ROOT_CONFIG OpenCMISSRoot)
        set(OPENCMISS_OWN_MPI_CONFIG OpenCMISSOwnMPIRoot)
    endif ()
else ()
    if (_INSTALLATION_CONFIG_FINALISED)
        unset(OPENCMISS_LIBRARIES_ROOT CACHE)
        unset(OPENCMISS_DEPENDENCIES_ROOT CACHE)
        unset(OPENCMISS_CMAKE_MODULES_ROOT CACHE)
    else ()
        set(OPENCMISS_LIBRARIES_ROOT ${OPENCMISS_LIBRARIES_ROOT} CACHE PATH "Root location for building OpenCMISS libraries from source.")
        set(OPENCMISS_DEPENDENCIES_ROOT ${OPENCMISS_DEPENDENCIES_ROOT} CACHE PATH "Root location for building OpenCMISS dependencies from source.")
        set(OPENCMISS_CMAKE_MODULES_ROOT ${OPENCMISS_CMAKE_MODULES_ROOT} CACHE PATH "Root location for building OpenCMISS cmake modules from source.")
        set(OPENCMISS_ROOT_CONFIG OpenCMISSIndependentRoots)
        set(OPENCMISS_OWN_MPI_CONFIG OpenCMISSOwnMPIIndependentRoots)
    endif ()
endif ()

# OPENCMISS_MODULE_PATH must be set
set(OPENCMISS_CMAKE_MODULES_PATH ${OPENCMISS_CMAKE_MODULES_PATH} CACHE PATH "Location of the OpenCMISS CMake modules.")

if (NOT EXISTS "${OPENCMISS_CMAKE_MODULES_PATH}/Modules/OCArchitecturePathFunctions.cmake")
    message(FATAL_ERROR "'${OPENCMISS_CMAKE_MODULES_PATH}/Modules/OCArchitecturePathFunctions.cmake' does not exists.  The OpenCMISS CMake modules may not be installed/available.")
endif ()

if (NOT WIN32 OR MINGW)
    if (CMAKE_BUILD_TYPE STREQUAL "")
        set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
        message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using Release.")
    endif()
endif()

list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_CMAKE_MODULES_PATH}/Modules)

set(CONFIGURED_FILES_DIR ${CMAKE_CURRENT_BINARY_DIR}/ConfiguredFiles)
list(APPEND CMAKE_MODULE_PATH ${CONFIGURED_FILES_DIR})
if (NOT _INSTALLATION_CONFIG_FINALISED)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Templates/${OPENCMISS_OWN_MPI_CONFIG}.template.cmake ${CONFIGURED_FILES_DIR}/OpenCMISSOwnMPI.cmake @ONLY)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Templates/${OPENCMISS_ROOT_CONFIG}.template.cmake ${CONFIGURED_FILES_DIR}/OpenCMISSRoots.cmake @ONLY)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Templates/OpenCMISSInstallationConfig.template.cmake ${CONFIGURED_FILES_DIR}/OpenCMISSInstallationConfig.cmake)
endif ()

include(OCArchitecturePathFunctions)
include(OCMiscFunctionsMacros)

# Path for own MPI BUILD?
include(OpenCMISSOwnMPI)

include(OCToolchainCompilers)
include(OCDetermineMPI)

########################################################################
# Architecture paths
set(ARCHITECTURE_PATH_NOMPI .)
set(ARCHITECTURE_PATH_MPI .)
if (OC_USE_ARCHITECTURE_PATH)
    getArchitecturePath(ARCHITECTURE_PATH_NOMPI ARCHITECTURE_PATH_MPI)
endif()

# This includes the configuration, both default and local
#include(OpenCMISSConfig)

# Hide some of the variables in the interface that we don't want to see.
tidyUpVariables()

getToolchain(CURRENT_TOOLCHAIN)

set(OPENCMISS_TOOLCHAIN ${CURRENT_TOOLCHAIN} CACHE STRING "Specify the toolchain mnemonic.")
set(OPENCMISS_MPI ${MPI} CACHE STRING "Specify the MPI mnemonic")

if (OC_USE_ARCHITECTURE_PATH)
    set(PLURAL_S s)
else ()
    set(PLURAL_S)
endif ()

# Variable used in make_config command
set(CONFIG_PATH ${CMAKE_CURRENT_BINARY_DIR}/config${PLURAL_S}/${ARCHITECTURE_PATH_MPI})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Templates/make_config.in.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/Scripts/make_config.cmake)

add_custom_target(make_config
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/Scripts/make_config.cmake
    )

message(STATUS "")
message(STATUS "OPENCMISS_TOOLCHAIN: ${OPENCMISS_TOOLCHAIN}")
message(STATUS "OPENCMISS_MPI: ${OPENCMISS_MPI}")
message(STATUS "ARCHITECTURE_PATH_MPI: ${ARCHITECTURE_PATH_MPI}")
message(STATUS "")
