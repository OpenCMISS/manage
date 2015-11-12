# Make sure a localconfig file exists
if (NOT EXISTS ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
    include(Variables)
    SET(OC_USE_SYSTEM_FLAGS )
    SET(OC_USE_FLAGS )
    if (WIN32)
        SET(_NL "\r\n")
    else()
        SET(_NL "\n")
    endif()
    foreach(COMPONENT ${OPENCMISS_COMPONENTS})
        if (NOT ${COMPONENT} IN_LIST OC_MANDATORY_COMPONENTS)
            # Some components are disabled by default. add option for opposite action here
            set(_VALUE NO)
            if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT)
                set(_VALUE YES)
            endif()
            # Prepare the option to disable/enable here.
            SET(OC_USE_FLAGS "${OC_USE_FLAGS}#set(OC_USE_${COMPONENT} ${_VALUE})${_NL}")
        endif()
        # Some components are looked for on the system by default. add option for opposite action here
        LIST(FIND OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT ${COMPONENT} _COMP_POS)
        SET(_VALUE YES)
        if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT)
            SET(_VALUE NO)
        endif()
        SET(OC_USE_SYSTEM_FLAGS "${OC_USE_SYSTEM_FLAGS}#set(OC_SYSTEM_${COMPONENT} ${_VALUE})${_NL}")
    endforeach()
    configure_file(${OPENCMISS_MANAGE_DIR}/Templates/OpenCMISSLocalConfig.template.cmake
        ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
    unset(_NL)
    unset(OC_USE_SYSTEM_FLAGS)
    unset(OC_USE_FLAGS)
    
    # Extra development part - allows to set localconfig variables directly
    if (DEFINED DIRECT_VARS)
        file(APPEND ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake
            "# Directly forwarded variables:\r\n"
        )
        foreach(VARNAME ${DIRECT_VARS})
            file(APPEND ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake
                "set(${VARNAME} ${${VARNAME}})\r\n"
            )
        endforeach()
    endif()
    if (OPENCMISS_REMOTE_INSTALL_DIR)
        get_filename_component(OPENCMISS_REMOTE_INSTALL_DIR "${OPENCMISS_REMOTE_INSTALL_DIR}" ABSOLUTE)
        if (EXISTS "${OPENCMISS_REMOTE_INSTALL_DIR}")
            file(APPEND ${MAIN_BINARY_DIR}/OpenCMISSLocalConfig.cmake
                "set(OPENCMISS_REMOTE_INSTALL_DIR \"${OPENCMISS_REMOTE_INSTALL_DIR}\")\r\n"
            )
        else()
            message(FATAL_ERROR "Remote installation directory not found: ${OPENCMISS_REMOTE_INSTALL_DIR}")
        endif()
    endif()
endif()
