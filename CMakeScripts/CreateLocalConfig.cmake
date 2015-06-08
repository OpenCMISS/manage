# Make sure a localconfig file exists
if (NOT EXISTS ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
    include(Variables)
    SET(OCM_USE_SYSTEM_FLAGS )
    SET(OCM_USE_FLAGS )
    if (WIN32)
        SET(_NL "\r\n")
    else()
        SET(_NL "\n")
    endif()
    foreach(OCM_COMP ${OPENCMISS_COMPONENTS})
        # Some components are disabled by default. add option for opposite action here
        LIST(FIND OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT ${OCM_COMP} _COMP_POS)
        set(_VALUE NO)
        if (_COMP_POS GREATER -1)
            set(_VALUE YES)
        endif()
        # Prepare the option to disable/enable here.
        SET(OCM_USE_FLAGS "${OCM_USE_FLAGS}#SET(OCM_USE_${OCM_COMP} ${_VALUE})${_NL}")
        
        # Some components are looked for on the system by default. add option for opposite action here
        LIST(FIND OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT ${OCM_COMP} _COMP_POS)
        SET(_VALUE YES)
        if (_COMP_POS GREATER -1)
            SET(_VALUE NO)
        endif()
        SET(OCM_USE_SYSTEM_FLAGS "${OCM_USE_SYSTEM_FLAGS}#SET(OCM_SYSTEM_${OCM_COMP} ${_VALUE})${_NL}")
    endforeach()
    configure_file(${OPENCMISS_MANAGE_DIR}/Templates/OpenCMISSLocalConfig.template.cmake
        ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
    unset(_NL)
    unset(OCM_USE_SYSTEM_FLAGS)
    unset(OCM_USE_FLAGS)
endif()
