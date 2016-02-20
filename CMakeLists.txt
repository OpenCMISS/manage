########################################################
# Welcome to the OpenCMISS build system!
########################################################
# This script realises the top-level setup/generation phase.
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
# ROOT: [Parent of the manage directory containing this file]
#    Set this to any directory that you want to contain OpenCMISS sources, build- and install trees.
#
# EVEL: []|<any value>
#     If you want to initialize your OpenCMISS installation to developer defaults, define the EVEL variable to any value.
#     It's not a typo, the command line for this results in -DEVEL=<myvalue> :-)
#
# ============== Toolchain ==============
# 
# TOOLCHAIN: []|gnu|clang|mingw|intel|ibm
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
# MPI: []|mpich|mpich2|openmpi|mvapich2|intel|none
#    MPI is a crucial part of OpenCMISS and defaults to be used.
#    You should not have to specify a specific MPI implementation, as CMake will find your system default automatically.
#     
#    The selection "none" will build OpenCMISS without MPI,
#    which is intended for future use but not implemented yet.
#
# MPI_BUILD_TYPE: [RELEASE]|DEBUG|...
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

########################################################
# If your cmake is older than 2.6 - goodbye. 
cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)
# Set the manage directory
set(OPENCMISS_MANAGE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
# The default opencmiss root is the parent directory of "manage"
set(OPENCMISS_ROOT "${OPENCMISS_MANAGE_DIR}/.." CACHE PATH "Root directory for OpenCMISS.")
if (ROOT)
    SET(OPENCMISS_ROOT "${ROOT}" CACHE PATH "Root directory for OpenCMISS." FORCE)
endif(ROOT)
get_filename_component(OPENCMISS_ROOT ${OPENCMISS_ROOT} ABSOLUTE)

# Set up include path required at this stage
list(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts
    ${OPENCMISS_MANAGE_DIR}/Config
    ${OPENCMISS_MANAGE_DIR})

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

# OPENCMISS_CMAKE_MIN_VERSION is defined in OCCMakeCheck
cmake_minimum_required(VERSION ${OPENCMISS_CMAKE_MIN_VERSION} FATAL_ERROR)

# Need to set the compilers before any project call
include(OCToolchainCompilers)

########################################################################
# Ready to start the "build project"
project(OpenCMISS VERSION 1.3 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

include(OCMiscFunctionsMacros)

# Create a local config file if not exists
include(OCCreateLocalConfig)

# Pre-check for Python and Swig availability so that bindings will be built automatically (unless explicitly specified)
find_package(PythonInterp ${PYTHON_VERSION} QUIET)
find_package(PythonLibs QUIET)
find_package(SWIG QUIET)
if (PYTHONINTERP_FOUND AND PYTHONLIBS_FOUND AND SWIG_FOUND)
    set(OC_PYTHON_PREREQ_FOUND YES)
    # Already check for the virtualenv - this is the default way if found.
    find_program(VIRTUALENV_EXECUTABLE virtualenv)
else()
    set(OC_PYTHON_PREREQ_FOUND NO)
endif()
    
# This includes the configuration, both default and local
include(OpenCMISSConfig)

# Start log file for config run
string(TIMESTAMP NOW "%Y-%m-%d, %H:%M")
log("Starting configuration in ${CMAKE_CURRENT_BINARY_DIR} at ${NOW}")

if (NOT WIN32 OR MINGW)
    if (CMAKE_BUILD_TYPE STREQUAL "")
        SET(CMAKE_BUILD_TYPE RELEASE)
        message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using RELEASE.")
    endif()
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
if(NOT MPI STREQUAL none)
    include(OCMPIConfig)
endif()

# Toolchain flags
#
# Needs to be after MPI config as the mnemonic is used inside that script, too
include(OCToolchainFlags)

# Checks for known issues as good as possible
# TODO: move this to the generator script?!
#if (CMAKE_COMPILER_IS_GNUC AND MPI STREQUAL intel)
#    message(FATAL_ERROR "Invalid compiler/MPI combination: Cannot build with GNU compiler and Intel MPI.")
#endif()

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
# Checks if conditions for a sdk/central installation of opencmiss are given and augments the prefix path
# by a matching remote one
# If the according remote directory does not exist or any package is not build there, it will be built
# locally.
include(OCCheckSDKInstallation)

###################### 
# Collect the common arguments for any package/component
include(OCCollectComponentDefinitions)

# Those list variables will be filled by the build macros
SET(_OC_SELECTED_COMPONENTS )

########################################################################
# Python binding stuff
include(OCPythonBindings)

########################################################################
# Support - get help!
include(OCSupport)

########################################################################
# Actual external project configurations

# Dependencies, Iron, ...
include(OCConfigureComponents)

########################################################################
# Installation and support
include(OCInstall)
include(OCPackaging)

########################################################################
# Testing
# Need to enable testing in order for any add_test calls (see OCComponentSetupMacros) to work
add_subdirectory(Tests)

########################################################################
# Misc targets for convenience
include(OCMainTargets)

########################################################################
# IDE Stuff
source_group(CMake FILES CMakeLists.txt CMakeCache.txt)

# Print a neat summary
message(STATUS "@@@@@@@@@@@@@@@@@@@ SUMMARY @@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ OPENCMISS_ROOT: ${OPENCMISS_ROOT}")
if (OPENCMISS_SDK_INSTALL_DIR)
    message(STATUS "@ OPENCMISS_SDK_INSTALL_DIR: ${OPENCMISS_SDK_INSTALL_DIR}")
endif()
message(STATUS "@ MPI implementation: ${MPI}")
if (MPI_HOME)
    message(STATUS "@ MPI HOME: ${MPI_HOME}")
endif()
if (TOOLCHAIN)
    message(STATUS "@ TOOLCHAIN: ${TOOLCHAIN}")
endif()
message(STATUS "@")
printnextsteps()

log("Finished configuration in ${CMAKE_CURRENT_BINARY_DIR}")