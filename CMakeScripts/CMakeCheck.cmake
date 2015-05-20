SET(CMAKE_MIN_VERSION_MAJ 3.2)
SET(CMAKE_MIN_VERSION ${CMAKE_MIN_VERSION_MAJ}.0-rc1)

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

if (WIN32)
    if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
        message(STATUS "Your CMake version is ${CMAKE_VERSION}.\n"
                            "At least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                            "Please download & install from http://www.cmake.org/download/\n")
        set(CMAKE_COMPATIBLE NO)
    endif()
    if (NOT HTTPS_SUCCESS)
        message(STATUS "Your CMake ${CMAKE_VERSION} up to date but does not support https downloads (SSL not builtin).\n"
                            "Please download & install from http://www.cmake.org/download/\n")
        set(CMAKE_COMPATIBLE NO)                               
    endif()
else()
    # check for cmake version, ssl support and if OpenSSL is installed
    if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
            message(STATUS "Your CMake version is ${CMAKE_VERSION}, but at least version ${CMAKE_MIN_VERSION} is required to build OpenCMISS.\n"
                                "You can either:\n"
                                " - Have your administrator install or update CMake ${CMAKE_MIN_VERSION} (or newer) with SSL support.\n"
                                " - Build the target 'cmake'. This attempts to automatically download & compile a new CMake version for you.\n"
                                "\n"
                                "In any case, you need to re-invoke the CMake configuration step using the new CMake version.")
            # Prepare "cmake" target that builds a new CMake version here
            add_custom_target(cmake
                COMMAND ${CMAKE_COMMAND}
                    -DCMAKE_MIN_VERSION_MAJ=${CMAKE_MIN_VERSION_MAJ}
                    -DCMAKE_MIN_VERSION=${CMAKE_MIN_VERSION}
                    -DOPENCMISS_ROOT=${OPENCMISS_ROOT}
                    -P ${OPENCMISS_MANAGE_DIR}/CMakeScripts/CMakeBuild.cmake  
            )
            set(CMAKE_COMPATIBLE NO)
    endif()
endif()
