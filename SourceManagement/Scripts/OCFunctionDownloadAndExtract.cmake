function(DownloadAndExtract URL TARGET)
    #message(STATUS "Called DownloadAndExtract(${URL}, ${TARGET})")
    
    get_filename_component(TARGET "${TARGET}" ABSOLUTE)
    get_filename_component(TARGET_NAME "${TARGET}" NAME)
    get_filename_component(TARGET_DIR "${TARGET}" DIRECTORY)
    
    # Make sure the target directory exists
    file(MAKE_DIRECTORY "${TARGET_DIR}")
    
    if (NOT EXISTS "${TARGET_DIR}")
        message(FATAL_ERROR "Failed creating directory '${TARGET_DIR}'.")
    endif()
    
    # Download
    #if(NOT EXISTS "${TARGET}")
    message(STATUS "Attempting to download ${URL} to ${TARGET}")
    file(DOWNLOAD ${URL} "${TARGET}"
        STATUS DL_STATUS LOG DL_LOG)
    list(GET DL_STATUS 0 DL_ERROR)
    list(GET DL_STATUS 1 DL_ERROR_STR)
    if (NOT DL_ERROR EQUAL 0)
        message(STATUS "CMake-internal download failed with error #${DL_ERROR}: ${DL_ERROR_STR}")
        # The download process seems to create a file which is deleted after some unknown time - 
        # the next check for existence however still thinks there's a file and the script does
        # not work correctly. Hence, we manually remove the file here before trying wget.
        file(REMOVE "${TARGET}")
        find_package(Wget QUIET)
        if (WGET_FOUND)
            message(STATUS "Trying WGet..")
            execute_process(
                COMMAND ${WGET_EXECUTABLE} --no-check-certificate -O "${TARGET}" ${URL}
                RESULT_VARIABLE DL_RES
                OUTPUT_VARIABLE DL_OUTPUT
                ERROR_VARIABLE DL_ERROR
                WORKING_DIRECTORY "${TARGET_DIR}"
            )
            if (NOT DL_RES EQUAL 0)
                message(STATUS "Download using WGet failed.
Output:
${DL_OUTPUT}
Error:
${DL_ERROR}")
            endif(NOT DL_RES EQUAL 0)
        endif(WGET_FOUND)
    endif(NOT DL_ERROR EQUAL 0)
    #endif(NOT EXISTS "${TARGET}")
    
    # If we dont have the file by now, its bad ...
    if(NOT EXISTS "${TARGET}")
        message(FATAL_ERROR "Could not download ${TARGET_NAME}.
Please manually download ${URL} to directory ${TARGET_DIR}. Sorry!")
    endif(NOT EXISTS "${TARGET}")
        
    # Extract
    message(STATUS "Extracting ${TARGET_NAME}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${TARGET} .
        RESULT_VARIABLE EX_RES
        OUTPUT_VARIABLE DL_OUTPUT
        ERROR_VARIABLE DL_ERROR
        WORKING_DIRECTORY ${TARGET_DIR}
    )
    
    # Cleanup
    file(REMOVE ${TARGET})
    
    if (NOT EX_RES EQUAL 0)
        message(FATAL_ERROR "Extracting tarball failed.
Command:
${CMAKE_COMMAND} -E tar xzf ${TARGET}
Output:
${DL_OUTPUT}
Error:
${DL_ERROR}")
    endif()
endfunction()
