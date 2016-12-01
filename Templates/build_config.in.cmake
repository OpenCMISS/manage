execute_process(
    COMMAND ${BUILD_CONFIG_COMMAND}
    WORKING_DIRECTORY "${CONFIG_PATH}"
    RESULT_VARIABLE RESULT
    )

if ("${DOLLAR_SYMBOL}{RESULT}" STREQUAL "0")
    exucute_process(
        COMMAND "${CMAKE_COMMAND}" -E touch "${CONFIG_PATH}/stamp/build_config.stamp"
        )
    set(RESULT_MESSAGE "Build successful: ${CONFIG_PATH}")
else ()
    set(RESULT_MESSAGE "Failed to build configuration")
endif ()

message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ ${DOLLAR_SYMBOL}{RESULT_MESSAGE}")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
