
# The installation type is not defined until the first configuration has been set.
# Once the first configuration has been created the installation type cannot change.
file(GLOB_RECURSE _RESULTS RELATIVE "${CMAKE_CURRENT_BINARY_DIR}" create_config.stamp)
list(LENGTH _RESULTS _RES_LEN)
if (_RES_LEN EQUAL 0)
    set(_INSTALLATION_TYPE_DEFINED FALSE)
else ()
    set(_INSTALLATION_TYPE_DEFINED TRUE)
endif ()

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
    if (NOT _INSTALLATION_TYPE_DEFINED)
        message(STATUS "Finalising installation.")
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -DFINALISE_INSTALLATION=TRUE .
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        )
    endif ()
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
