# Need separate versioning as cmake 2.6 cannot handle "VERSION_LESS" yet
SET(CMAKE_MIN_MAJOR_VERSION 3)
SET(CMAKE_MIN_MINOR_VERSION 3)
SET(CMAKE_MIN_PATCH_VERSION 0-rc1)
SET(OPENCMISS_CMAKE_MIN_VERSION ${CMAKE_MIN_MAJOR_VERSION}.${CMAKE_MIN_MINOR_VERSION}.${CMAKE_MIN_PATCH_VERSION})

message(STATUS "Checking CMake version..")
# Assume we're good until found otherwise
set(CMAKE_COMPATIBLE YES)

# check if system cmake has ssl support
SET(CMAKE_HTTPS_TEST_URL "https://github.com/OpenCMISS-Utilities/gtest/blob/master/README.md")
SET(CMAKE_HTTPS_TEST_DOWNLOAD_PATH "${OPENCMISS_ROOT}/build/cmake_https_test_download.txt")
file(DOWNLOAD ${CMAKE_HTTPS_TEST_URL} ${CMAKE_HTTPS_TEST_DOWNLOAD_PATH} STATUS https_status TIMEOUT 60 INACTIVITY_TIMEOUT 60)
list(GET https_status 0 HTTPS_TEST_DOWNLOAD_ERROR_CODE)
list(GET https_status 1 HTTPS_TEST_DOWNLOAD_ERROR_STRING)
# https download was successful
if (HTTPS_TEST_DOWNLOAD_ERROR_CODE EQUAL 0)
    SET(HTTPS_SUCCESS 1)
else()
    SET(HTTPS_SUCCESS 0)
endif()
# remove the test file as it will be created either way
file(REMOVE ${CMAKE_HTTPS_TEST_DOWNLOAD_PATH})

# Check version
set(CMAKE_UPTODATE YES)
#if (CMAKE_MAJOR_VERSION LESS CMAKE_MIN_MAJOR_VERSION OR (CMAKE_MAJOR_VERSION EQUAL CMAKE_MIN_MAJOR_VERSION AND (CMAKE_MINOR_VERSION LESS CMAKE_MIN_MINOR_VERSION OR (CMAKE_MINOR_VERSION EQUAL CMAKE_MIN_MINOR_VERSION AND CMAKE_PATCH_VERSION LESS CMAKE_MIN_PATCH_VERSION))))
if (CMAKE_MAJOR_VERSION LESS CMAKE_MIN_MAJOR_VERSION)
    set(CMAKE_UPTODATE NO)
elseif(CMAKE_MAJOR_VERSION EQUAL CMAKE_MIN_MAJOR_VERSION)
    if (CMAKE_MINOR_VERSION LESS CMAKE_MIN_MINOR_VERSION)
        set(CMAKE_UPTODATE NO)
    elseif(CMAKE_MINOR_VERSION EQUAL CMAKE_MIN_MINOR_VERSION AND CMAKE_PATCH_VERSION LESS CMAKE_MIN_PATCH_VERSION)
        set(CMAKE_UPTODATE NO)
    endif()
endif()
# CMAKE_VERSION exists starting at version 2.6.3 :-(
if (NOT DEFINED CMAKE_VERSION)
  set(CMAKE_VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION})
endif(NOT DEFINED CMAKE_VERSION)

if (WIN32)
    if (NOT CMAKE_UPTODATE)
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake version is ${CMAKE_VERSION}.\n"
                " At least version ${OPENCMISS_CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                " Please download & install from http://www.cmake.org/download/\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        set(CMAKE_COMPATIBLE NO)
    endif(NOT CMAKE_UPTODATE)
    if (NOT HTTPS_SUCCESS)
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake ${CMAKE_VERSION} up to date but does not support https downloads (SSL not builtin).\n"
                " Please download & install from http://www.cmake.org/download/\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        set(CMAKE_COMPATIBLE NO)                               
    endif(NOT HTTPS_SUCCESS)
else()
    # check for cmake version, ssl support and if OpenSSL is installed
    if (NOT CMAKE_UPTODATE)
            message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                    " Your CMake version is ${CMAKE_VERSION}, but at least version ${OPENCMISS_CMAKE_MIN_VERSION} is required to build OpenCMISS.\n"
                    " You can either:\n"
                    " - Have your administrator install or update CMake ${OPENCMISS_CMAKE_MIN_VERSION} (or newer) with SSL support.\n"
                    " - Build the target 'cmake'. This attempts to automatically download & compile a new CMake version for you.\n"
                    " In any case, you need to re-invoke the CMake configuration step using the new CMake binary.\n"
                    "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            # Prepare "cmake" target that builds a new CMake version here
            add_custom_target(cmake
                COMMAND ${CMAKE_COMMAND}
                    -DCMAKE_MIN_MAJOR_VERSION=${CMAKE_MIN_MAJOR_VERSION}
                    -DCMAKE_MIN_MINOR_VERSION=${CMAKE_MIN_MINOR_VERSION}
                    -DCMAKE_MIN_PATCH_VERSION=${CMAKE_MIN_PATCH_VERSION}
                    -DOPENCMISS_CMAKE_MIN_VERSION=${OPENCMISS_CMAKE_MIN_VERSION}
                    -DOPENCMISS_ROOT=${OPENCMISS_ROOT}
                    -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
                    -P ${OPENCMISS_MANAGE_DIR}/CMakeScripts/OCCMakeBuild.cmake  
            )
            set(CMAKE_COMPATIBLE NO)
    endif(NOT CMAKE_UPTODATE)
endif()
