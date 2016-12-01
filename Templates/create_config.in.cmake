make_directory("${CONFIG_PATH}")
execute_process(
    COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" ${CONFIGURATION_SETTINGS} "${CMAKE_CURRENT_SOURCE_DIR}/config"
    WORKING_DIRECTORY "${CONFIG_PATH}"
    RESULT_VARIABLE RESULT
    )

if ("${DOLLAR_SYMBOL}{RESULT}" STREQUAL "0")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E touch "${CONFIG_PATH}/stamp/create_config.stamp"
        )
    set(RESULT_MESSAGE "Configuration successful: ${CONFIG_PATH}")
else ()
    set(RESULT_MESSAGE "Failed to create configuration")
endif ()

message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ ${DOLLAR_SYMBOL}{RESULT_MESSAGE}")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
