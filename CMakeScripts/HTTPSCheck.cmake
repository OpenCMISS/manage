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
