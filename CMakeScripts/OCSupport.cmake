# Script mode for collecting log files
if (DEFINED LOG_DIR AND EXISTS "${LOG_DIR}")
    file(GLOB LOGS "${LOG_DIR}/*.log")
    file(COPY ${LOGS} DESTINATION ${SUPPORT_DIR})

# Script mode for creating the support zip file    
elseif(CREATE_ZIP)
    set(SUPPORT_ZIP "${CMAKE_CURRENT_BINARY_DIR}/buildinfo.zip")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar c ${SUPPORT_ZIP} --format=zip
            -- 
            "${SUPPORT_DIR}"
            "${BUILD_DIR}/export"
            "${BUILD_DIR}/CMakeCache.txt"
            "${BUILD_DIR}/OpenCMISSLocalConfig.cmake"
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
        getGitRevision(OPENCMISS_MANAGE_GIT_REVISON)
        getGitBranch(OPENCMISS_MANAGE_GIT_BRANCH)
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
            file(APPEND ${FILE} "${_variableName}=${${_variableName}}\r\n")
        endforeach()
    endfunction()

    # Need to export current variables directly - obviously wont work in called script
    exportVars("${OC_SUPPORT_DIR}/Variables.txt")
    
    set(_SUPPORT_DEPS )
    if (OCM_CREATE_LOGS)
        add_custom_target(collect_logs
            COMMAND -E echo "Collecting log files from build directories"
        )
        set(_SUPPORT_DEPS DEPENDS collect_logs)
    endif()
    if (NOT DEFINED OC_INSTALL_SUPPORT_EMAIL)
        set(OC_INSTALL_SUPPORT_EMAIL users@list.opencmiss.org)
    endif()
    add_custom_target(support
        ${_SUPPORT_DEPS}
        COMMAND ${CMAKE_COMMAND}
            -DCREATE_ZIP=YES
            -DBUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -DEMAIL=${OC_INSTALL_SUPPORT_EMAIL}
            -DSUPPORT_DIR=${OC_SUPPORT_DIR}
            -P ${CMAKE_CURRENT_LIST_FILE}
        COMMENT "Generating support files archive"
    )
endif()
