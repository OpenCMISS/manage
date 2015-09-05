if (CALLED_AS_SCRIPT)


else()

    function(exportVars FILE)
        file(WRITE ${FILE} "OpenCMISS Support Variable dump\r\n")
        get_cmake_property(_variableNames VARIABLES)
        foreach (_variableName ${_variableNames})
            file(APPEND ${FILE} "${_variableName}=${${_variableName}}\r\n")
        endforeach()
    endfunction()

    set(SUPPORT_DIR ${CMAKE_CURRENT_BINARY_DIR}/support)
    # Need to export current variables directly - obviously wont work in called script
    exportVars("${SUPPORT_DIR}/variables.txt")    
    
    add_custom_target(support
        COMMAND ${CMAKE_COMMAND} 
            -DCALLED_AS_SCRIPT=YES
            -DSUPPORT_DIR=${SUPPORT_DIR}
            -P ${CMAKE_CURRENT_LIST_FILE}
    )
endif()
