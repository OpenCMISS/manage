# Small script to run source management tasks as custom targets.
#
# Check:
#     See if the CMakeLists.txt file is there, and if not, invoke the download target    
# Download:
#     This implements the actual download work for the "download" target when Git is disabled (DISABLE_GIT) 
if (MODE STREQUAL "Check")
    # Passed variables are: SRC_DIR, BIN_DIR, TARGET_PREFIX and COMPONENT
    if (NOT EXISTS "${SRC_DIR}/CMakeLists.txt")
        execute_process(
	    COMMAND ${CMAKE_COMMAND} -E make_directory "${SRC_DIR}"
            COMMAND ${CMAKE_COMMAND} --build "${BIN_DIR}" --target ${TARGET_PREFIX}${COMPONENT}_download
            RESULT_VARIABLE RES
            ERROR_VARIABLE ERR
        )
        if (NOT RES EQUAL 0)
            message(FATAL_ERROR "Error downloading ${COMPONENT}: ${ERR}")
        endif()
    endif()
elseif (MODE STREQUAL "Download")
    # Passed variables are: TARGET, URL
    include("${CMAKE_CURRENT_LIST_DIR}/OCFunctionDownloadAndExtract.cmake")
    DownloadAndExtract(${URL} "${TARGET}")
endif ()
