set(OC_TARGET_VIRTUALENV )
if (IRON_WITH_Python_BINDINGS OR ZINC_WITH_Python_BINDINGS)
    if (NOT OC_PYTHON_PREREQ_FOUND)
        log("Python bindings were requested for Iron or Zinc but the prerequisites are not met.\nPython, Python development libraries and Swig are required.\nSee http://www.opencmiss.org/documentation for more information." ERROR)
    endif()

    if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
        # This is already checked for earlier (in the main CMakeLists script before including OpenCMISSConfig)
        # - however, we leave it here to be self-contained should the scripts be re-arranged some time
        find_program(VIRTUALENV_EXECUTABLE virtualenv)
        if (NOT VIRTUALENV_EXECUTABLE)
            log("Could not find virtualenv executable. Check your environment PATH settings or disable the OC_PYTHON_BINDINGS_USE_VIRTUALENV option." ERROR)
        endif()
        set(OC_VIRTUALENV_SUBPATH "virtual_environments")
    endif()
    
    function(genBindingInfoFile BTYPE)
        # OPENCMISS_INSTALL_ROOT_PYTHON is defined in OCPaths.cmake
        if (NOT EXISTS "${OPENCMISS_INSTALL_ROOT_PYTHON}")
          file(MAKE_DIRECTORY ${OPENCMISS_INSTALL_ROOT_PYTHON})
        endif ()
        string(TOLOWER ${BTYPE} BTYPE)
        string(REPLACE "/" "_" _APATH "${ARCHITECTURE_PATH_MPI}")
        set(VIRTUALENV_INFO_FILE ${OPENCMISS_INSTALL_ROOT_PYTHON}/bindings_${_APATH}_${BTYPE}.py)
        getCompilerPathElem(COMPILER)
        string(TOLOWER ${MPI_BUILD_TYPE} MPI_BUILD_TYPE)
        set(LIBRARY_PATH )
        foreach(_PATH ${OPENCMISS_LIBRARY_PATH})
            file(TO_NATIVE_PATH "${_PATH}" _NATIVE)
            list(APPEND LIBRARY_PATH "${_NATIVE}")
        endforeach()
        set(IS_VIRTUALENV false)
        if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
            set(IS_VIRTUALENV true)
        endif()
        configure_file(
            "${OPENCMISS_MODULE_PATH}/Templates/python_virtualenv.in.py"
            "${VIRTUALENV_INFO_FILE}" 
            @ONLY
        )
    endfunction()
    
    set(VENV_CREATION_COMMANDS )
    if (CMAKE_HAVE_MULTICONFIG_ENV)
        foreach(BTYPE ${CMAKE_CONFIGURATION_TYPES})
            string(TOLOWER ${BTYPE} BTYPE)
            set(OC_TARGET_VIRTUALENV ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}/${OC_VIRTUALENV_SUBPATH}/${BTYPE})
            genBindingInfoFile(${BTYPE})
        
            # For multiconfig builds, we need to create all the possible virtual environments
            # at once, as CMake currently does not allow generator expressions in add_custom_command's OUTPUT part,
            # see https://cmake.org/Bug/view.php?id=13840
            if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
                list(APPEND VENV_CREATION_COMMANDS
                    COMMAND ${VIRTUALENV_EXECUTABLE} --system-site-packages "${OC_TARGET_VIRTUALENV}"
                )
            endif()
        endforeach()
        # Set to the directory without build type - zinc/iron will know if they're in a multiconf-environment
        # and create the correct path for installation within their own cmake logic
        set(OC_TARGET_VIRTUALENV ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}/${OC_VIRTUALENV_SUBPATH})
    else()
        set(OC_TARGET_VIRTUALENV ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/${OC_VIRTUALENV_SUBPATH})
        genBindingInfoFile(${CMAKE_BUILD_TYPE})
        
        if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
            set(VENV_CREATION_COMMANDS COMMAND ${VIRTUALENV_EXECUTABLE} --system-site-packages "${OC_TARGET_VIRTUALENV}")
        endif()
    endif()
    
    if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
        set(OC_VENV_STAMPFILE ${OC_TARGET_VIRTUALENV}/virtualenv.install)
        add_custom_command(OUTPUT ${OC_VENV_STAMPFILE}
            ${VENV_CREATION_COMMANDS}
            COMMAND ${CMAKE_COMMAND} -E touch "${OC_VENV_STAMPFILE}"
        )
        add_custom_target(virtualenv_install ALL
            DEPENDS ${OC_VENV_STAMPFILE}
        )
    endif()
endif()
