set(PRINT_MESSAGE TRUE)
string(REPLACE "-<semi-colon>-" ";" BUILD_COMMAND "${DOLLAR_SYMBOL}{BUILD_COMMAND}")
if (NOT EXISTS "${DOLLAR_SYMBOL}{STAMP_FILE}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E remove "${DOLLAR_SYMBOL}{STAMP_FILE}"
        COMMAND ${DOLLAR_SYMBOL}{BUILD_COMMAND}
        WORKING_DIRECTORY "${CONFIG_PATH}"
        RESULT_VARIABLE RESULT
    )
else ()
    set(PRINT_MESSAGE FALSE)
endif ()

if ("${DOLLAR_SYMBOL}{RESULT}" STREQUAL "0")
    file(WRITE "${DOLLAR_SYMBOL}{STAMP_FILE}" 
"
set(ARCHITECTURE_MPI_PATH ${ARCHITECTURE_MPI_PATH})
set(ARCHITECTURE_NO_MPI_PATH ${ARCHITECTURE_NO_MPI_PATH})
set(CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH ${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH})
set(CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH ${CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH})
"
    )
    set(RESULT_MESSAGE "Build successful: ${CONFIG_PATH}")
else ()
    set(RESULT_MESSAGE "Failed to build configuration")
endif ()

if (PRINT_MESSAGE)
    message(STATUS "@")
    message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    message(STATUS "@")
    message(STATUS "@ ${DOLLAR_SYMBOL}{RESULT_MESSAGE}")
    message(STATUS "@")
    message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    message(STATUS "@")
endif ()
