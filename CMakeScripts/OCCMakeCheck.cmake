# Need separate versioning as cmake 2.6 cannot handle "VERSION_LESS" yet
SET(CMAKE_MIN_MAJOR_VERSION 3)
SET(CMAKE_MIN_MINOR_VERSION 4)
SET(CMAKE_MIN_PATCH_VERSION 0)
SET(OPENCMISS_CMAKE_MIN_VERSION ${CMAKE_MIN_MAJOR_VERSION}.${CMAKE_MIN_MINOR_VERSION}.${CMAKE_MIN_PATCH_VERSION})

message(STATUS "Checking CMake version..")
# Assume we're good until found otherwise
set(CMAKE_COMPATIBLE YES)

# check if system cmake has ssl support (dependent on whatever current version is running it!)
string(REPLACE "." "_" _CMAKE_VERSION_UNDERSCORE "${CMAKE_VERSION}")
set(_HTTPS_CHECK_VAR "CMAKE_${_CMAKE_VERSION_UNDERSCORE}_HAS_HTTPS")
if (NOT ${_HTTPS_CHECK_VAR}) 
    message("Checking CMake HTTPS support ...")
    set(CMAKE_HTTPS_TEST_URL "https://raw.githubusercontent.com/OpenCMISS/manage/v1.0/README.rst")
    set(CMAKE_HTTPS_TEST_DOWNLOAD_PATH "${OPENCMISS_ROOT}/build/cmake_https_test_download.txt")
    file(DOWNLOAD ${CMAKE_HTTPS_TEST_URL} ${CMAKE_HTTPS_TEST_DOWNLOAD_PATH} STATUS https_status TIMEOUT 60 INACTIVITY_TIMEOUT 60)
    list(GET https_status 0 HTTPS_TEST_DOWNLOAD_ERROR_CODE)
    list(GET https_status 1 HTTPS_TEST_DOWNLOAD_ERROR_STRING)
    # https download was successful
    if (HTTPS_TEST_DOWNLOAD_ERROR_CODE EQUAL 0)
        set(${_HTTPS_CHECK_VAR} YES CACHE BOOL "Checks if CMake ${CMAKE_VERSION} is build with SSL support")
    endif(HTTPS_TEST_DOWNLOAD_ERROR_CODE EQUAL 0)
    # remove the test file as it will be created either way
    file(REMOVE ${CMAKE_HTTPS_TEST_DOWNLOAD_PATH})
    if (${_HTTPS_CHECK_VAR})
        message("Checking CMake HTTPS support ... done")
    else()
        message("Checking CMake HTTPS support ... failed")
    endif()
endif(NOT ${_HTTPS_CHECK_VAR})

# Check version
set(CMAKE_UPTODATE YES)
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

if(WIN32)
    if (NOT CMAKE_UPTODATE)
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake version is ${CMAKE_VERSION}.\n"
                " At least version ${OPENCMISS_CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                " Please download & install from http://www.cmake.org/download/\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        set(CMAKE_COMPATIBLE NO)
    endif(NOT CMAKE_UPTODATE)
    if (NOT ${_HTTPS_CHECK_VAR})
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake ${CMAKE_VERSION} does not support https downloads (SSL not builtin).\n"
                " Please download & install from http://www.cmake.org/download/\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
        set(CMAKE_COMPATIBLE NO)                               
    endif(NOT ${_HTTPS_CHECK_VAR})
else(WIN32)
    # check for cmake version, ssl support and if OpenSSL is installed
    if (NOT CMAKE_UPTODATE)
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake version is ${CMAKE_VERSION}, but at least version ${OPENCMISS_CMAKE_MIN_VERSION} is required to build OpenCMISS.\n")
        set(CMAKE_COMPATIBLE NO)
    endif(NOT CMAKE_UPTODATE)
    if (NOT ${_HTTPS_CHECK_VAR})
        message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                " Your CMake ${CMAKE_VERSION} does not support https downloads (SSL not builtin).\n")
        set(CMAKE_COMPATIBLE NO)                               
    endif(NOT ${_HTTPS_CHECK_VAR})
    if (NOT CMAKE_COMPATIBLE)
        message(" You can either:\n"
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
                -DCMAKE_MINIMUM_REQUIRED_VERSION=2.6
                -P ${OPENCMISS_MANAGE_DIR}/CMakeScripts/ScriptCMakeBuild.cmake
        )
    endif(NOT CMAKE_COMPATIBLE)
endif(WIN32)
