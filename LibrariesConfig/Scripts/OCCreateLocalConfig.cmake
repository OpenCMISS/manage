if (NOT EXISTS ${OPENCMISS_LOCAL_CONFIG})
    log("Creating OpenCMISSLocalConfig file in ${PROJECT_BINARY_DIR}")
    set(OC_USE_SYSTEM_FLAGS )
    set(OC_USE_FLAGS )
    if (WIN32)
        set(_NL "\r\n")
    else()
        set(_NL "\n")
    endif()
    foreach(COMPONENT ${OPENCMISS_COMPONENTS})
        if (NOT ${COMPONENT} IN_LIST OPENCMISS_MANDATORY_COMPONENTS)
            # Some components are disabled by default. add option for opposite action here
            set(_VALUE OFF)
            if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT)
                set(_VALUE ON)
            endif()
            # Prepare the option to disable/enable here.
            set(OC_USE_FLAGS "${OC_USE_FLAGS}#set(OC_USE_${COMPONENT} ${_VALUE})${_NL}")
        endif()
        # Some components are looked for on the system by default. add option for opposite action here
        list(FIND OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT ${COMPONENT} _COMP_POS)
        set(_VALUE ON)
        if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT)
            set(_VALUE OFF)
        endif()
        set(OC_USE_SYSTEM_FLAGS "${OC_USE_SYSTEM_FLAGS}#set(${COMPONENT}_FIND_SYSTEM ${_VALUE})${_NL}")
    endforeach()
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Templates/OpenCMISSLocalConfig.template.cmake
        ${OPENCMISS_LOCAL_CONFIG})
    unset(OC_USE_SYSTEM_FLAGS)
    unset(OC_USE_FLAGS)
    
    if (OPENCMISS_SDK_INSTALL_DIR)
        get_filename_component(OPENCMISS_SDK_INSTALL_DIR "${OPENCMISS_SDK_INSTALL_DIR}" ABSOLUTE)
        if (EXISTS "${OPENCMISS_SDK_INSTALL_DIR}")
            file(APPEND "${OPENCMISS_LOCAL_CONFIG}" "set(OPENCMISS_SDK_INSTALL_DIR \"${OPENCMISS_SDK_INSTALL_DIR}\")${_NL}"
            )
        else()
            log("Remote installation directory not found: ${OPENCMISS_SDK_INSTALL_DIR}" ERROR)
        endif()
    endif()
    
    # Extra development part - allows to set localconfig variables directly
    if (DEFINED DIRECT_VARS)
        file(APPEND "${OPENCMISS_LOCAL_CONFIG}" "# Directly forwarded variables:${_NL}"
        )
        foreach(VARNAME ${DIRECT_VARS})
            file(APPEND "${OPENCMISS_LOCAL_CONFIG}" "set(${VARNAME} ${${VARNAME}})${_NL}"
            )
        endforeach()
    endif()
    unset(_NL)
endif()
