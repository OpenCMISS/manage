make_directory(${CONFIG_PATH})
execute_process(
    COMMAND "${CMAKE_COMMAND}" ${CONFIGURATION_SETTINGS} "${CMAKE_CURRENT_SOURCE_DIR}/config"
    WORKING_DIRECTORY ${CONFIG_PATH}
    )
