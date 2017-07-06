
set(SUPPORT_ZIP "${CMAKE_CURRENT_BINARY_DIR}/configbuildinfo.zip")
execute_process(COMMAND ${CMAKE_COMMAND} -E tar c ${SUPPORT_ZIP} --format=zip
        --
        "${SUPPORT_DIR}"
        "${CONFIG_DIR}/export"
        "${CONFIG_DIR}/CMakeCache.txt"
        "${OPENCMISS_LOCAL_CONFIG_LOCATION}"
        RESULT_VARIABLE RES
        ERROR_VARIABLE ERR
)
if (RES)
    message(FATAL_ERROR "Creating ZIP file failed: ${ERR}")
else()
    message(STATUS "
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Ready to get help!
@
@ We've created a configuration and build report at
@ ${SUPPORT_ZIP}
@
@ Please send an eMail to ${EMAIL},
@ describing briefly what happened or bothers you and attach the above file.
@
@ This way, we can track down the problem faster and help you be on your way with OpenCMISS!
@
@ No confidential data is collected or being sent at any stage.
@
@
@ Your OpenCMISS development team.
@ http://opencmiss.org
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
")
endif ()
