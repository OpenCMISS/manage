# Script mode for collecting log files
if (DEFINED LOG_DIR AND EXISTS "${LOG_DIR}")
    file(GLOB LOGS "${LOG_DIR}/*.log")
    file(COPY ${LOGS} DESTINATION ${SUPPORT_DIR})

elseif(BUILD_STAMP)
    string(TIMESTAMP NOW "%Y-%m-%d, %H:%M")
    file(APPEND "${LOGFILE}" "Build of OpenCMISS component ${COMPONENT_NAME} started at ${NOW}\r\n")

# Script mode for creating the support zip file    
elseif(CREATE_ZIP)

    set(SUPPORT_ZIP "${CMAKE_CURRENT_BINARY_DIR}/buildinfo.zip")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar c ${SUPPORT_ZIP} --format=zip
            -- 
            "${SUPPORT_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}/export"
            "${CMAKE_CURRENT_BINARY_DIR}/CMakeCache.txt"
            "${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSLocalConfig.cmake"
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
    endif()
else()

    # The export vars script will also collect these variables!
    if (GIT_FOUND)
        git_get_revision(OPENCMISS_MANAGE_GIT_REVISON)
        git_get_branch(OPENCMISS_MANAGE_GIT_BRANCH)
    endif()

    function(exportVars FILE)
        string(TIMESTAMP NOW)
        file(WRITE ${FILE} "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
OpenCMISS Support variable dump file, ${NOW}
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

")
        get_cmake_property(_variableNames VARIABLES)
        set(VARS_LATER )
        file(APPEND ${FILE} "OpenCMISS related variables:\r\n")
        foreach (_variableName ${_variableNames})
            if (_variableName MATCHES "^(OC_|OPENCMISS|OCM)")
                file(APPEND ${FILE} "${_variableName}=${${_variableName}}\r\n")
            else()
                list(APPEND VARS_LATER ${_variableName})
            endif()
        endforeach()
        file(APPEND ${FILE} "\r\nOther CMake variables:\r\n")
        foreach (_variableName ${VARS_LATER})
            if (NOT _variableName MATCHES "_PLATFORM_CONTENT$")
                file(APPEND ${FILE} "${_variableName}=${${_variableName}}\r\n")
            endif()
        endforeach()
    endfunction()

    # Need to export current variables directly - obviously wont work in called script
    exportVars("${OC_SUPPORT_DIR}/Variables.txt")
    
    set(_SUPPORT_DEPS )
    if (OC_CREATE_LOGS)
        # This is a dummy target, to which all single components add a "POST_BUILD" hook
        # to collect their respective log files. Using PRE_BUILD directly on "support"
        # does not work everywhere (only with Win/VS)
        add_custom_target(collect_logs
            COMMAND ${CMAKE_COMMAND} -E echo "--"
            COMMENT "Support: Collected log files from build directories"
        )
        set(_SUPPORT_DEPS DEPENDS collect_logs)
    endif()
    
    # Fall back to the OPENCMISS_BUILD_SUPPORT_EMAIL if no install email is set.
    if (NOT OPENCMISS_INSTALLATION_SUPPORT_EMAIL)
        set(OPENCMISS_INSTALLATION_SUPPORT_EMAIL ${OPENCMISS_BUILD_SUPPORT_EMAIL})
    endif()
    
    add_custom_target(support
        ${_SUPPORT_DEPS}
        COMMAND ${CMAKE_COMMAND}
            -DCREATE_ZIP=YES
            -DEMAIL=${OC_INSTALL_SUPPORT_EMAIL}
            -DSUPPORT_DIR=${OC_SUPPORT_DIR}
            -P ${CMAKE_CURRENT_LIST_FILE}
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Generating support files archive"
    )
endif()
