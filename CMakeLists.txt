
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

include(OCToolchainCompilers)

getToolchain(CURRENT_TOOLCHAIN)

set(OPENCMISS_TOOLCHAIN ${CURRENT_TOOLCHAIN} STRING "Specify the toolchain mnemonic.")
