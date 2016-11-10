
########################################################
# If your cmake is older than 3.4 - goodbye. 
cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

########################################################################
# Ready to start the "build project"
project(OpenCMISS-Manage VERSION 1.0 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

set(OPENCMISS_MODULE_PATH ${OPENCMISS_MODULE_PATH} CACHE PATH "Location of the OpenCMISS CMake modules.")

list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH}/CMakeScripts)
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH}/Config)
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH}/CMakeModules)

# Start log file for config run
string(TIMESTAMP NOW "%Y-%m-%d, %H:%M")
log("Starting configuration in ${CMAKE_CURRENT_BINARY_DIR} at ${NOW}")

if (NOT WIN32 OR MINGW)
    if (CMAKE_BUILD_TYPE STREQUAL "")
        SET(CMAKE_BUILD_TYPE Release)
        message(STATUS "No CMAKE_BUILD_TYPE has been defined. Using Release.")
    endif()
endif()

include(OCArchitecturePathFunctions)
include(OCPaths)
include(OCMiscFunctionsMacros)
include(OCToolchainCompilers)
include(OCMPIConfig)

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
#include(OpenCMISSConfig)

getToolchain(CURRENT_TOOLCHAIN)

set(OPENCMISS_TOOLCHAIN ${CURRENT_TOOLCHAIN} CACHE STRING "Specify the toolchain mnemonic.")
set(OPENCMISS_MPI ${MPI} CACHE STRING "Specify the MPI mnemonic")


message(STATUS "")
message(STATUS "OPENCMISS_TOOLCHAIN: ${OPENCMISS_TOOLCHAIN}")
message(STATUS "OPENCMISS_MPI: ${OPENCMISS_MPI}")
message(STATUS "")
