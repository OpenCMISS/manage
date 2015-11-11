set(OC_SUPPORT_DIR ${CMAKE_CURRENT_BINARY_DIR}/support)
string(TIMESTAMP NOW)
file(WRITE "${OC_SUPPORT_DIR}/build.log" "Starting configuration in ${CMAKE_CURRENT_BINARY_DIR} at ${NOW}\r\n")

set(OPENCMISS_CMAKE_MIN_VERSION @OPENCMISS_CMAKE_MIN_VERSION@)
cmake_minimum_required(VERSION ${OPENCMISS_CMAKE_MIN_VERSION} FATAL_ERROR)

########################################################################
# These values will be put in place at generation phase.
# They could've also been passed over as command line definitions, however,
# this would allow to mess with them later. As this is the top level CMakeLists.txt
# for this specific compiler/mpi choice and sub-external projects rely on this
# choice, it's hard-coded rather than being modifiable (externally).
set(OPENCMISS_ROOT @OPENCMISS_ROOT@)
set(OPENCMISS_MANAGE_DIR @OPENCMISS_MANAGE_DIR@)
########################################################################

# Set up include path
list(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_MANAGE_DIR}
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts
    ${OPENCMISS_MANAGE_DIR}/Config)

# This includes the configuration, both default and local
include(OpenCMISSConfig)

########################################################################
@TOOLCHAIN_DEF@
set(MPI @MPI@)
set(OC_SYSTEM_MPI @SYSTEM_MPI@)
set(MPI_BUILD_TYPE @MPI_BUILD_TYPE@)
@MPI_HOME_DEF@
########################################################################

# Need to set the compilers before any project call
include(OCToolchainCompilers)

########################################################################
# Ready to start the "build project"
project(OpenCMISS VERSION ${OPENCMISS_VERSION} LANGUAGES C CXX Fortran)

# Need to set the compiler flags after any project call - this ensures the cmake platform values
# are used, too.
include(OCToolchainFlags)

if ((NOT WIN32 OR MINGW) AND CMAKE_BUILD_TYPE STREQUAL "")
    SET(CMAKE_BUILD_TYPE RELEASE)
    message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
endif()

include(ExternalProject)
include(OCArchitecturePath)
include(OCComponentSetupMacros)

########################################################################
# Utilities and external packages

include(OCInstallFindModuleWrappers)
# Add CMakeModules directory after wrapper module directory (set in above script)
# This folder is also exported to the install tree upon "make install" and
# then used within the FindOpenCMISS.cmake module script
list(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_MANAGE_DIR}/CMakeModules
)

# No point in building ZINC if there's no OpenGL around
if (OC_USE_ZINC)
    find_package(OpenGL QUIET)
    if (NOT OPENGL_FOUND)
        set(OC_USE_ZINC NO)
        message(WARNING "OpenCMISS: No OpenGL found, cannot build Zinc. Disabling.")
    endif()
endif()
# Pre-check for Python availability so that bindings will be built automatically (unless explicitly specified)
# The FOUND flag is used (at least) at OCConfigureComponents/IRON
find_package(PythonInterp ${PYTHON_VERSION} QUIET)
if (NOT DEFINED IRON_WITH_Python_BINDINGS)
    set(IRON_WITH_Python_BINDINGS ${PYTHONINTERP_FOUND})
endif()

# Git is used by default to clone source repositories, unless disabled
if (NOT DISABLE_GIT)
    find_package(Git)
    if (NOT GIT_FOUND)
        message(STATUS "ATTENTION: Could not find Git. Falling back to download sources as .zip files.")
    endif()
endif()

include(OCDetectFortranMangling)

# Multithreading
if(OC_MULTITHREADING)
    find_package(OpenMP REQUIRED)
endif()

########################################################################
# MPI
# Unless we said to not have MPI or MPI_HOME is given, see that it's available.
if(NOT (DEFINED MPI_HOME OR MPI STREQUAL none))
    include(OCMPIConfig)
endif()
# Note:
# If MPI_HOME is set, we'll just pass it on to the external projects where the
# FindMPI.cmake module is going to look exclusively there.
# The availability of an MPI implementation at MPI_HOME was made sure
# in the MPIPreflight.cmake script upon generation time of this script.

# Checks for known issues as good as possible
# TODO: move this to the generator script?!
if (CMAKE_COMPILER_IS_GNUC AND MPI STREQUAL intel)
    message(FATAL_ERROR "Invalid compiler/MPI combination: Cannot build with GNU compiler and Intel MPI.")
endif()

########################################################################
# General paths & preps
set(ARCHITECTURE_PATH .)
set(ARCHITECTURE_PATH_MPI .)
if (OC_USE_ARCHITECTURE_PATH)
    getArchitecturePath(ARCHITECTURE_PATH ARCHITECTURE_PATH_MPI)
endif()
# Build tree location for components (with/without mpi)
SET(OPENCMISS_COMPONENTS_BINARY_DIR "${OPENCMISS_ROOT}/build/${ARCHITECTURE_PATH}")
SET(OPENCMISS_COMPONENTS_BINARY_DIR_MPI "${OPENCMISS_ROOT}/build/${ARCHITECTURE_PATH_MPI}")
# Install dir
# Extra path segment for single configuration case - will give release/debug/...
getBuildTypePathElem(BUILDTYPEEXTRA)
########### everything from the OpenCMISS main project goes into install/
# This is also used in Install.cmake to place the opencmiss config files.
set(OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE "${OPENCMISS_INSTALL_ROOT}/${ARCHITECTURE_PATH}")
# This is the install prefix for all components without mpi
set(OPENCMISS_COMPONENTS_INSTALL_PREFIX "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}/${BUILDTYPEEXTRA}")
# This is the install path for mpi-aware components
set(OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE "${OPENCMISS_INSTALL_ROOT}/${ARCHITECTURE_PATH_MPI}")
set(OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}/${BUILDTYPEEXTRA}")

######################
# The COMMON_PACKAGE_CONFIG_DIR contains the cmake-generated target config files consumed by find_package(... CONFIG).
# Those are "usually" placed under the lib/ folders of the installation tree, however, the OpenCMISS build system
# install trees also have the build type as subfolders. As the config-files generated natively create differently named files
# for each build type, they can be collected in a common subfolder. As the build type subfolder-element is the last in line,
# we simply use the parent folder of the component's CMAKE_INSTALL_PREFIX to place the cmake package config files.
# ATTENTION: this is (still) not usable. While older cmake versions deleted other-typed config files, they are now kept at least.
# However, having the config file OUTSIDE the install prefix path still does not work correctly, and the fact that
# we need to be able to determine build types for examples/iron/dependencies separately requires separate folders, for now.
SET(COMMON_PACKAGE_CONFIG_DIR cmake)
#SET(COMMON_PACKAGE_CONFIG_DIR ../cmake)
# The path where find_package calls will find the cmake package config files for any opencmiss component
set(OPENCMISS_PREFIX_PATH
    "${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}" 
    "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/${COMMON_PACKAGE_CONFIG_DIR}"
)
# Also add
#list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH})
# This is where the libraries will be put.
set(OPENCMISS_LIBRARY_PATH
    "${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/lib"
    "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/lib"
)
# If we have an explicit MPI_HOME, add this to the library path (+/lib)
if (MPI_HOME)
    list(APPEND OPENCMISS_LIBRARY_PATH "${MPI_HOME}/lib")
endif()

######################
# Checks if conditions for a remote installation of opencmiss are given and augments the prefix path
# by a matching remote one
# If the according remote directory does not exist or any package is not build there, it will be built
# locally.
include(OCCheckRemoteInstallation)

###################### 
# Collect the common arguments for any package/component
include(OCCollectComponentDefinitions)

# Those list variables will be filled by the build macros
SET(_OC_SELECTED_COMPONENTS )

########################################################################
# Support - get help!
include(OCSupport)

########################################################################
# Actual external project configurations

# Dependencies, Iron, ...
include(OCConfigureComponents)

# Examples
include(OCAddExamplesProject)

########################################################################
# Installation and support
include(OCInstall)

########################################################################
# Testing
# Need to enable testing in order for any add_test calls (see OCComponentSetupMacros) to work
enable_testing()
include(OCFeatureTests)


########################################################################
# Misc targets for convenience
# update: Updates the whole source tree
# reset: Blows away the current build and installation trees

# Create a download target that depends on all other downloads
set(_OC_SOURCE_UPDATE_TARGETS )
set(_OC_COLLECT_LOG_TARGETS )
foreach(_COMP ${_OC_SELECTED_COMPONENTS})
    list(APPEND _OC_SOURCE_UPDATE_TARGETS ${_COMP}-update)
    list(APPEND _OC_COLLECT_LOG_TARGETS _${_COMP}-collectlogs)
endforeach()
add_custom_target(update
    DEPENDS ${_OC_SOURCE_UPDATE_TARGETS}
)
add_custom_target(reset
    DEPENDS reset_mpionly reset_featuretests
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_BINARY_DIR}"
    COMMAND ${CMAKE_COMMAND} -E remove "${OC_SUPPORT_DIR}/build.log"
    COMMENT "Removing directories:
        ->${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}
        ->${OPENCMISS_COMPONENTS_BINARY_DIR}"
)
add_custom_target(reset_mpionly
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}"
    COMMENT "Removing directories:
        ->${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}
        ->${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}"
)

string(TIMESTAMP NOW)
file(APPEND "${OC_SUPPORT_DIR}/build.log" "Finished configuration in ${CMAKE_CURRENT_BINARY_DIR} at ${NOW}
-------------------------------------------
")




