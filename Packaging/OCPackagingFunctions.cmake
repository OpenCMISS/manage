function(GET_INSTALL_QUADS PACKAGE_TYPE VAR_NAME)

    set(_quads)
    # Find configurations that have successfully built.
    file(GLOB_RECURSE children RELATIVE ${CONFIG_BASE_DIR} ${CONFIG_BASE_DIR}/*build_config.stamp)
    foreach(_build_config_stamps ${children})
        file(TO_CMAKE_PATH "${_build_config_stamps}" _cmaked_build_config_stamps)
        get_filename_component(_build_config_dir ${_cmaked_build_config_stamps} DIRECTORY)
        get_filename_component(_config_dir ${_build_config_dir} DIRECTORY)
        set(_build_config ${_build_config_dir}/build.config)
        include(${CONFIG_BASE_DIR}/${_cmaked_build_config_stamps})
        include(${CONFIG_BASE_DIR}/${_build_config})

        list(APPEND _quads "${IRON_BINARY_DIR}" "Iron Runtime" Runtime "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
        list(APPEND _quads "${IRON_BINARY_DIR}" "Iron C bindings" CBindings "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
        list(APPEND _quads "${IRON_BINARY_DIR}" "Iron Python bindings" PythonBindings "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
        list(APPEND _quads "${ZINC_BINARY_DIR}" "Zinc Runtime" Runtime "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
        list(APPEND _quads "${ZINC_BINARY_DIR}" "Zinc Python bindings" PythonBindings "${CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH}")
        #list(APPEND _quads "${PROJECT_BINARY_DIR}" "OpenCMISSLibs Runtime files" Runtime /)
        if (WIN32)
            list(APPEND _quads "${IRON_BINARY_DIR}" "DLLs required by OpenCMISS Libraries" Redist "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
        endif ()
    
        if ("${PACKAGE_TYPE}" STREQUAL "sdk")
            list(APPEND _quads "${IRON_BINARY_DIR}" "Iron Development" Development "${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH}")
            list(APPEND _quads "${ZINC_BINARY_DIR}" "Zinc Development" Development "${CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH}")
            list(APPEND _quads "${CONFIG_BASE_DIR}/${_config_dir}" "OpenCMISSLibs Development" Development "/")
            list(APPEND _quads "${CMAKE_MODULES_BINARY_DIR}" "OpenCMISSLibs Development" CMakeFiles "/")
        endif ()
    
        if ("${PACKAGE_TYPE}" STREQUAL "developersdk")
            list(APPEND _quads "${PROJECT_BINARY_DIR}" "OpenCMISS Runtime files" Runtime /)
            list(APPEND _quads "${PROJECT_BINARY_DIR}" "OpenCMISS Development" Development /)
            list(APPEND _quads "${PROJECT_BINARY_DIR}" "OpenCMISS Development" DevelopmentSDK /)
            foreach(COMP ${_OC_SELECTED_COMPONENTS})
                if (NOT COMP STREQUAL IRON AND NOT COMP STREQUAL ZINC)
                    if (${COMP} IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
                        list(APPEND _quads "${${COMP}_BINARY_DIR}" ${COMP} ALL "${ARCHITECTURE_MPI_PATH}")
                    else()
                        list(APPEND _quads "${${COMP}_BINARY_DIR}" ${COMP} ALL "${ARCHITECTURE_NO_MPI_PATH}")
                    endif()
                endif()
            endforeach()
        endif ()
    endforeach()
    set(${VAR_NAME} ${_quads} PARENT_SCOPE)
endfunction()

function(GET_PACKAGE_SYSTEM_NAME _VAR_NAME)

    if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
        find_program(LSB_RELEASE lsb_release)
        if (LSB_RELEASE)
            execute_process(COMMAND ${LSB_RELEASE} -is
                OUTPUT_VARIABLE LSB_RELEASE_ID_SHORT
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            execute_process(COMMAND ${LSB_RELEASE} -rs
                OUTPUT_VARIABLE LSB_VERSION_ID_SHORT
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            set(PACKAGE_NAME ${LSB_RELEASE_ID_SHORT}-${LSB_VERSION_ID_SHORT})
        else ()
            set(PACKAGE_NAME ${CMAKE_SYSTEM_NAME})
        endif ()
    else ()
        set(PACKAGE_NAME ${CMAKE_SYSTEM_NAME})
    endif ()

    set(${_VAR_NAME} ${PACKAGE_NAME} PARENT_SCOPE)
endfunction()

