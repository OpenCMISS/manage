if (NOT EXISTS "${CONFIG_PATH}")
    make_directory("${CONFIG_PATH}")
endif ()

execute_process(
    COMMAND "${CMAKE_COMMAND}" -E remove "${DOLLAR_SYMBOL}{STAMP_FILE}"
    COMMAND "${CMAKE_COMMAND}" -E remove "${DOLLAR_SYMBOL}{BUILD_STAMP_FILE}"
    COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" ${CONFIGURATION_SETTINGS} "${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig"
    WORKING_DIRECTORY "${CONFIG_PATH}"
    RESULT_VARIABLE RESULT
    )

if ("${DOLLAR_SYMBOL}{RESULT}" STREQUAL "0")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CONFIG_PATH}/stamp"
        COMMAND "${CMAKE_COMMAND}" -E touch "${DOLLAR_SYMBOL}{STAMP_FILE}"
        )
    set(RESULT_MESSAGE "Configuration successful: ${CONFIG_PATH}")
else ()
    set(RESULT_MESSAGE "Failed to create configuration")
    message(SEND_ERROR "${RESULT_MESSAGE}")
endif ()

message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ ${DOLLAR_SYMBOL}{RESULT_MESSAGE}")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
