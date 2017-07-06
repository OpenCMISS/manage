
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
exportVars("${OPENCMISS_SUPPORT_DIR}/Variables.txt")

if (OC_CREATE_LOGS)
    # This is a dummy target, to which all single components add a "POST_BUILD" hook
    # to collect their respective log files. Using PRE_BUILD directly on "support"
    # does not work everywhere (only with Win/VS)
    add_custom_target(collect_logs
        COMMAND ${CMAKE_COMMAND} -E echo "Collected log files."
        COMMENT "Support: Collecting log files from build directories"
    )
else ()
    add_custom_target(collect_logs
        COMMAND ${CMAKE_COMMAND} -E echo "Log files disabled ==> no logs collected."
        COMMENT "Support: Collecting log files from build directories"
    )
endif ()

