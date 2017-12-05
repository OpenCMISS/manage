########################################################
# Welcome to the OpenCMISS build system!
########################################################
# This script realises the top-level generation phase.
# All it does is making sure you have the minimum cmake version available (if not, you can have us build for you)
# and generates the actual main build project for any choice of compiler/toolchain and MPI combination you'd like.
#
# The easiest thing to do is nothing: CMake will detect the system's default setup and try to use that.
# Otherwise, here's what you can configure at this stage:
# 
# Configuration options
# ########################################################
# Specify any of the following variables on the command line via -DVARNAME=VALUE or set them in your CMake GUI.
# The values in brackets indicate the default values, where [] denotes not set and | separates alternatives.
#
# ============== General ================
#
# EVEL: []|<any value>
#     If you want to initialize your OpenCMISS installation to developer defaults, define the EVEL variable to any value.
#     It's not a typo, the command line for this results in -DEVEL=<myvalue> :-)
#
# ============== Toolchain ==============
# 
# OPENCMISS_TOOLCHAIN: []|gnu|clang|mingw|intel|ibm
#    Usually you dont need to tell CMake which compilers to use.
#    If you change compilers here, YOU SHOULD KNOW WHY!!!
#
#    gnu,mingw: gcc,g++ and gfortran compilers
#    clang    : CLang c,c++ compilers and gfortran
#    intel    : icc, icpc, ifort compilers
#    ibm      : xlc, xlC, xlf95 compilers
#    Note that this variable will be used case-insensitive.
#    If you have a toolchain that differs from the above choices, please use the next
#    method and also let us know what you are using: users@opencmiss.org
#
# CMAKE_<lang>_COMPILER: []|gcc (binary name)|/usr/local/mygcc/bin/gcc (absolute path)
#    If this does not cover you needs, you can specify each compiler using the CMAKE_<lang>_COMPILER variables,
#    where <lang> can be each of "C","CXX" or "Fortran".
#
# If you still fail to have CMake successfully configure OpenCMISS with non-default compilers,
# please contact the OpenCMISS Team at users@opencmiss.org.
#
# ============== MPI ====================
#
# OPENCMISS_MPI_IMPLEMENTATION: []|mpich|mpich2|openmpi|mvapich2|intel|msmpi|none
#    MPI is a crucial part of OpenCMISS and defaults to be used.
#    You should not have to specify a specific MPI implementation, as CMake will find your system default automatically.
#     
#    The selection "none" will build OpenCMISS without MPI,
#    which is intended for future use but not implemented yet.
#
# OPENCMISS_MPI_BUILD_TYPE: [Release]|Debug|...
#    The MPI build type can be chosen independently from the OpenCMISS build type.
#    For debug builds, OpenCMISS will build its own version of the selected (or default) MPI implementation
#    as the detection of system debug builds is not reliable (yet)
#
# MPI_HOME: []|~/software/openmpi-1.8.3_install (absolute path to mpi installation)
#    You can also specify a custom MPI root directory in case the detection mechanisms fail.
#    Using this setting will override any other setting and have CMake look there EXCLUSIVELY.
#
# MPI_<lang>_COMPILER: []|mpicc (wrapper binary name)|/usr/local/bin/mpicc (absolute path to wrapper binary)
#    Further, you can specify an explicit mpi compiler wrapper (full path or just the binary name) for each language,
#    where <lang> can be each of "C","CXX" or "Fortran".
#    This can be used independently of (but possibly with) the MPI_HOME setting.
#
# =========== Instrumentation ===========
#
# INSTRUMENTATION: |[none]|scorep|vtune
#    Specify any code instrumentation systems for use in performance analysis.
#
#    none  : no instrumentation
#    scorep: score-p instrumentation
#    vtune : Intel vtune instrumentation (only available with Intel compilers)
#    Note that this variable will be used case-insensitive.
#    If no instrumentation is specified none will be used as the default.
#

########################################################
# If your cmake is older than 3.4 - goodbye. 
cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

# Check bare minimum configuration
# OPENCMISS_CMAKE_MODULE_PATH must be set 
if (NOT DEFINED OPENCMISS_CMAKE_MODULE_PATH)
  message(FATAL_ERROR "OPENCMISS_CMAKE_MODULE_PATH is not defined.")
endif ()
if (NOT EXISTS "${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCToolchainCompilers.cmake")
    message(FATAL_ERROR "'${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCToolchainCompilers.cmake' does not exists.  The OpenCMISS CMake modules may not be installed/available.")
endif ()
set(OPENCMISS_CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}" CACHE INTERNAL "Internalise the module path so that it is available for CMake GUIs." FORCE)

# Set up include path required at this stage
list(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers
    ${OPENCMISS_CMAKE_MODULE_PATH}
    ${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS
)

if (NOT DEFINED OPENCMISS_TOOLCHAIN)
    message(FATAL_ERROR "OPENCMISS_TOOLCHAIN is not defined.")
endif ()
set(OPENCMISS_TOOLCHAIN ${OPENCMISS_TOOLCHAIN} CACHE INTERNAL "Internalise the toolchain so that it is un-available for CMake GUIs." FORCE)

# Need to set the compilers before any project call
include(OCToolchainCompilers)
setCMakeCompilersForToolchain(${OPENCMISS_TOOLCHAIN})
########################################################################
# Ready to start the "build project"
# It is intended that this version number is kept in sync with the OpenCMISS-Manage project.
project(OpenCMISS-Manage-Configuration VERSION 1.3.0 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

set(CMAKE_INSTALL_PREFIX /georges/house) # Can't point this somewhere sensible as it is used later on when finding modules.

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_CURRENT_SOURCE_DIR}/Modules
    ${CMAKE_CURRENT_SOURCE_DIR}/Scripts
    ${SHARED_MODULES_PATH}
    ${SHARED_SETTINGS_PATH}
)

# Pre-check for Python and Swig availability so that bindings will be built automatically (unless explicitly specified)
find_package(PythonInterp ${PYTHON_VERSION} QUIET)
find_package(PythonLibs QUIET)
find_package(SWIG QUIET)

if (SWIG_FOUND)
	message(STATUS "Language bindings are possible.")
	if (PYTHONLIBS_FOUND)
		message(STATUS "Python language bindings are possible.")
	else ()
		message(STATUS "Python library development files not found.  No Python language bindings will be created.")
	endif ()
else ()
	message(STATUS "SWIG not found. It is not possible to create any language bindings.")
endif ()

if (PYTHONINTERP_FOUND AND PYTHONLIBS_FOUND AND SWIG_FOUND)
    set(OC_PYTHON_PREREQ_FOUND YES)
    # Already check for the virtualenv - this is the default way if found.
    find_program(VIRTUALENV_EXECUTABLE virtualenv)
else()
    set(OC_PYTHON_PREREQ_FOUND NO)
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Utilities and external packages
include(ExternalProject)
include(OCEnvironmentChecks)
include(OCComponentSetupMacros)
include(OCArchitecturePathFunctions)

# Define variables used throughout
include(OCVariables)
include(OCMultiConfigEnvironment)

# General paths & preps
include(OCPaths)
include(OCComponentVersions)

# Introduce miscellaneous helper functions and macros
include(OCMiscFunctions)
include(OCDetermineMPIFunctions)

set(OPENCMISS_CONFIG_DIR ${OPENCMISS_CONFIG_DIR} CACHE PATH "Location of OpenCMISSLocalConfig.cmake to use for this configuration.")
if (OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(OPENCMISS_LOCAL_CONFIG ${PROJECT_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
else ()
    get_filename_component(OPENCMISS_LOCAL_CONFIG "${PROJECT_BINARY_DIR}/../OpenCMISSLocalConfig.cmake" ABSOLUTE)
endif ()

# Create a local config file if it does not exist.
include(OCCreateLocalConfig)

# Load configuration files.
include(OCConfig)

# Create a list of all the required components.
include(OCDetermineRequiredComponents)

foreach( _COMP ${OC_REQUIRED_COMPONENTS})
    set(${COMPONENT_NAME}_SHARED ${BUILD_SHARED_LIBS})
endforeach()

if (OPENCMISS_HAVE_MULTICONFIG_ENV)
	mark_as_advanced(CMAKE_CONFIGURATION_TYPES)
else ()
    # This isn't configurable at this stage it is configured at the config creation time
    #set(OPENCMISS_BUILD_TYPE CACHE STRING "Choose the type of build to configure, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
    set(CMAKE_BUILD_TYPE ${OPENCMISS_BUILD_TYPE} CACHE INTERNAL "Internalise CMAKE_BUILD_TYPE manipulate through OPENCMISS_BUILD_TYPE instead." FORCE)
endif ()

# Hide some of the variables in the interface that we don't want to see.
tidy_gui_variables()

# The build system creates a build log in order to ease the support process.
string(TIMESTAMP NOW "%Y-%m-%d_%H-%M")
set(OC_BUILD_LOG ${OPENCMISS_SUPPORT_DIR}/configure_builds_${NOW}.log)
log("Starting configuration in ${CMAKE_CURRENT_BINARY_DIR} at ${NOW}")

# Add directory to module path
# Add CMakeModules directory after wrapper module directory
list(APPEND OPENCMISS_COMPONENT_MODULE_PATH
    ${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS
    ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers
    ${OPENCMISS_CMAKE_MODULE_PATH}
)

# No point in building ZINC if there's no OpenGL around
find_package(OpenGL QUIET)
if (NOT OPENGL_FOUND AND OC_USE_ZINC)
    set(OC_USE_ZINC NO)
    message(WARNING "OpenCMISS: No OpenGL found, cannot build Zinc. Disabling.")
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

# MPI
# Unless we said to not have MPI, see that it's available.
if (OPENCMISS_MPI_INSTALLATION STREQUAL none)
    # Do nothing.
else ()
    include(OCSelectMPI)
endif ()

########################################################################
# Architecture paths
# First extra path segment for single configuration case - will give release/debug/...
getBuildTypePathElem(BUILD_TYPE_PATH_ELEM)

# Second architecture path for configuration passed in through command line
set(ARCHITECTURE_NO_MPI_PATH ${ARCH_NO_MPI_PATH})
set(ARCHITECTURE_MPI_PATH ${ARCH_MPI_PATH})

include(${OPENCMISS_ROOTS_FILE})

include(OCComponentsReport)

#
# Setup build of MPI if required
include(OCBuildMPI)
if (OPENCMISS_MPI_IMPLEMENTATION STREQUAL none)
    set(OC_USE_MPI FALSE)
else ()
    set(OC_USE_MPI TRUE)
endif ()

# Toolchain flags
#
# Needs to be after MPI config as the mnemonic is used inside that script, too
include(OCToolchainFlags)

#
# Set virtualenv install prefix
set(OCL_VIRTUALENV_INSTALL_PREFIX "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/virtual_environments")

######################
# The COMMON_PACKAGE_CONFIG_DIR contains the cmake-generated target config files consumed by find_package(... CONFIG).
# Those are "usually" placed under the lib/ folders of the installation tree, however, the OpenCMISS build system
# install trees also have the build type as subfolders. As the config-files generated natively create differently named files
# for each build type, they can be collected in a common subfolder. As the build type subfolder-element is the last in line,
# we simply use the parent folder of the component's CMAKE_INSTALL_PREFIX to place the cmake package config files.
# ATTENTION: this is (still) not usable. While older cmake versions deleted other-typed config files, they are now kept at least.
# However, having the config file OUTSIDE the install prefix path still does not work correctly, and the fact that
# we need to be able to determine build types for examples/iron/dependencies separately requires separate folders, for now.
set(COMMON_PACKAGE_CONFIG_DIR cmake)

# The path where find_package calls will find the cmake package config files for any opencmiss component
if (OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX)
    list(APPEND OPENCMISS_PREFIX_PATH_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_DEPENDENCIES_CMAKE_CONFIG_PATH "${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX}/lib")
    list(APPEND OPENCMISS_BINARIES_PATH_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX}/bin")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_PREFIX_PATH_MPI}")
    list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_LIBRARY_PATH_MPI}")
endif ()
if (OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX)
    list(APPEND OPENCMISS_PREFIX_PATH_NO_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_DEPENDENCIES_CMAKE_CONFIG_PATH "${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH_NO_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}/lib")
    list(APPEND OPENCMISS_BINARIES_PATH_NO_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}/bin")
    set(OPENCMISS_DEPENDENCIES_INSTALL_PREFIX "${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_PREFIX_PATH_NO_MPI}")
    list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_LIBRARY_PATH_NO_MPI}")
endif ()
if (OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX)
    list(APPEND OPENCMISS_PREFIX_PATH_MPI "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH_MPI "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/lib")
    list(APPEND OPENCMISS_BINARIES_PATH_MPI "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/bin")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}/lib")
endif ()
if (OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX)
    list(APPEND OPENCMISS_PREFIX_PATH_NO_MPI "${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH_NO_MPI "${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX}/lib")
    list(APPEND OPENCMISS_BINARIES_PATH_NO_MPI "${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX}/bin")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX}/lib")
endif ()
if (OPENCMISS_LIBRARIES_ONLY)
    list(APPEND OPENCMISS_PREFIX_PATH_NO_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX}${ARCHITECTURE_NO_MPI_PATH}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_PREFIX_PATH_MPI "${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX}${ARCHITECTURE_MPI_PATH}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX}${ARCHITECTURE_NO_MPI_PATH}/${COMMON_PACKAGE_CONFIG_DIR}")
    list(APPEND OPENCMISS_PREFIX_PATH "${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX}${ARCHITECTURE_MPI_PATH}/${COMMON_PACKAGE_CONFIG_DIR}")
    if (OPENCMISS_ZINC_INSTALL_PREFIX)
        list(APPEND OPENCMISS_LIBRARY_PATH_NO_MPI "${OPENCMISS_ZINC_INSTALL_PREFIX}/lib")
        list(APPEND OPENCMISS_BINARIES_PATH_NO_MPI "${OPENCMISS_ZINC_INSTALL_PREFIX}/bin")
        list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_ZINC_INSTALL_PREFIX}/lib")
    endif ()
    if (OPENCMISS_IRON_INSTALL_PREFIX)
        list(APPEND OPENCMISS_LIBRARY_PATH_MPI "${OPENCMISS_IRON_INSTALL_PREFIX}/lib")
        list(APPEND OPENCMISS_BINARIES_PATH_MPI "${OPENCMISS_IRON_INSTALL_PREFIX}/bin")
        list(APPEND OPENCMISS_LIBRARY_PATH "${OPENCMISS_IRON_INSTALL_PREFIX}/lib")
    endif ()
endif ()

list(REMOVE_DUPLICATES OPENCMISS_PREFIX_PATH_MPI)
list(REMOVE_DUPLICATES OPENCMISS_PREFIX_PATH_NO_MPI)
list(REMOVE_DUPLICATES OPENCMISS_PREFIX_PATH)
list(REMOVE_DUPLICATES OPENCMISS_LIBRARY_PATH_MPI)
list(REMOVE_DUPLICATES OPENCMISS_LIBRARY_PATH_NO_MPI)
list(REMOVE_DUPLICATES OPENCMISS_LIBRARY_PATH)
list(REMOVE_DUPLICATES OPENCMISS_BINARIES_PATH_MPI)
list(REMOVE_DUPLICATES OPENCMISS_BINARIES_PATH_NO_MPI)

# If we have an explicit MPI_HOME, add this to the library path (+/lib)
if (MPI_HOME)
    list(APPEND OPENCMISS_LIBRARY_PATH "${MPI_HOME}/lib")
endif()

######################
# Checks if conditions for a sdk/central installation of opencmiss are given and augments the prefix path
# by a matching remote one
# If the according remote directory does not exist or any package is not built there, it will be built
# locally.
include(OCCheckSDKInstallation)

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

########################################################################
# Testing
# Need to enable testing in order for any add_test calls (see OCComponentSetupMacros) to work
add_subdirectory(Tests)

########################################################################
# Examples
# Need to enable testing in order for any add_test calls (see OCComponentSetupMacros) to work
add_subdirectory(Examples)

# Installation of general opencmiss configuration helper scripts.
include(OCInstall)

########################################################################
# IDE Stuff
source_group(CMake FILES CMakeLists.txt CMakeCache.txt)

if ("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
    set(BUILD_ARCH 64)
else ()
    set(BUILD_ARCH 32)
endif ()

set(BUILD_CONFIG_FILE "${CMAKE_CURRENT_BINARY_DIR}/stamp/build_config.cmake")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/build.in.config"
    ${BUILD_CONFIG_FILE}
)

# Print a neat summary
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@ SUMMARY @@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
if (OPENCMISS_SDK_INSTALL_DIR)
    message(STATUS "@ OPENCMISS_SDK_INSTALL_DIR: ${OPENCMISS_SDK_INSTALL_DIR}")
endif ()
message(STATUS "@ MPI implementation: ${OPENCMISS_MPI_IMPLEMENTATION}")
if (MPI_HOME)
    message(STATUS "@ MPI HOME: ${MPI_HOME}")
endif ()
if (OPENCMISS_TOOLCHAIN)
    message(STATUS "@ TOOLCHAIN: ${OPENCMISS_TOOLCHAIN}")
endif ()
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@ NEXT STEPS @@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ - Change ${OPENCMISS_LOCAL_CONFIG} according to your setup/needs")
message(STATUS "@ - Build the 'opencmiss' target (e.g. '${CMAKE_MAKE_PROGRAM} opencmiss') to start the build process")
message(STATUS "@")
message(STATUS "@ Having trouble? Follow the galaxy hitchhiker's advice:")
message(STATUS "@ DONT PANIC ... and:")
message(STATUS "@ - Refer to http://staging.opencmiss.org/documentation/cmake/docs/config/index.html for customization instructions")
message(STATUS "@ - Build the 'support' target to get help! (e.g. '${CMAKE_MAKE_PROGRAM} support')")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")

log("Finished configuration in ${CMAKE_CURRENT_BINARY_DIR}")

