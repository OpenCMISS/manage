cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

# Check bare minimum configuration
# OPENCMISS_CMAKE_MODULE_PATH must be set
if (NOT DEFINED OPENCMISS_CMAKE_MODULE_PATH)
  message(FATAL_ERROR "OPENCMISS_CMAKE_MODULE_PATH is not defined.")
endif ()
if (NOT EXISTS "${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCToolchainCompilers.cmake")
    message(FATAL_ERROR "'${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCToolchainCompilers.cmake' does not exists.  The OpenCMISS CMake modules may not be installed/available.")
endif ()

# Set up include path required at this stage
list(APPEND CMAKE_MODULE_PATH
    ${OPENCMISS_CMAKE_MODULE_PATH}/Modules/OpenCMISS
    )

# Need to set the compilers before any project call
include(OCToolchainCompilers)
setCMakeCompilersForToolchain(${TOOLCHAIN})

########################################################################
# Ready to start the "build project"
project(OpenCMISS-Manage-Configuration VERSION 1.3 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)

include(OCArchitecturePathFunctions)

getCompilerPartArchitecturePath(COMPILER_PART)

message("COMPILER_PART=${COMPILER_PART}")
