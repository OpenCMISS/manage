########################################################################################################################
# This is the main function that adds an OpenCMISS component to the build tree.
#
# Consumes all sorts of global variables, where SUBGROUP_PATH and GITHUB_ORGANIZATION are the ones 
# subsequently changed between function calls in ConfigureComponents 
function(addAndConfigureLocalComponent COMPONENT_NAME)
    # Get lowercase folder name from project name
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME)

    # Keep track of self-build components (thus far only used for "update" target)
    #list(APPEND _OC_SELECTED_COMPONENTS ${COMPONENT_NAME})
    # Need this since it's a function
    set(_OC_SELECTED_COMPONENTS ${_OC_SELECTED_COMPONENTS} ${COMPONENT_NAME} PARENT_SCOPE)

    ##############################################################
    # Compute directories
    if (COMPONENT_NAME STREQUAL "IRON" OR COMPONENT_NAME STREQUAL "ZINC")
        if (OPENCMISS_ZINC_SOURCE_DIR OR OPENCMISS_IRON_SOURCE_DIR)
            set(COMPONENT_SOURCE_DIR "${OPENCMISS_${COMPONENT_NAME}_SOURCE_DIR}")
        else ()
            set(COMPONENT_SOURCE_DIR "${OPENCMISS_LIBRARIES_SOURCE_DIR}/${FOLDER_NAME}")
        endif ()
    else ()
        set(COMPONENT_SOURCE_DIR "${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${FOLDER_NAME}")
    endif ()

    # Check which build dir is required - depending on whether this component can be built against mpi
    if (COMPONENT_NAME STREQUAL "IRON")
        if (OPENCMISS_IRON_BINARY_DIR)
            set(BUILD_DIR_BASE "${OPENCMISS_IRON_BINARY_DIR}")
            set(_INSTALL_PREFIX ${OPENCMISS_IRON_INSTALL_PREFIX})
        else ()
            set(BUILD_DIR_BASE "${OPENCMISS_LIBRARIES_BINARY_MPI_DIR}")
            set(_INSTALL_PREFIX ${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX})
        endif ()
    elseif (COMPONENT_NAME STREQUAL "ZINC")
        if (OPENCMISS_ZINC_BINARY_DIR)
            set(BUILD_DIR_BASE "${OPENCMISS_ZINC_BINARY_DIR}")
            set(_INSTALL_PREFIX ${OPENCMISS_ZINC_INSTALL_PREFIX})
        else ()
            set(BUILD_DIR_BASE "${OPENCMISS_LIBRARIES_BINARY_NO_MPI_DIR}")
            set(_INSTALL_PREFIX ${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX})
        endif ()
    elseif (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        set(BUILD_DIR_BASE "${OPENCMISS_DEPENDENCIES_BINARY_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX})
    else()
        set(BUILD_DIR_BASE "${OPENCMISS_DEPENDENCIES_BINARY_NO_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX})
    endif()
    # Complete build dir with debug/release AFTER everything else (consistent with windows)
    if (OPENCMISS_LIBRARIES_ONLY AND (OPENCMISS_IRON_BINARY_DIR OR OPENCMISS_ZINC_BINARY_DIR))
        set(COMPONENT_BUILD_DIR ${BUILD_DIR_BASE}/${BUILD_TYPE_PATH_ELEM})
    else ()
        if (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_RELEASE_ONLY AND NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
            set(COMPONENT_BUILD_DIR ${BUILD_DIR_BASE}/${FOLDER_NAME}/release)
        else ()
            set(COMPONENT_BUILD_DIR ${BUILD_DIR_BASE}/${FOLDER_NAME}/${BUILD_TYPE_PATH_ELEM})
        endif ()
    endif ()
    # Expose the current build directory outside the function - used only for Iron and Zinc yet 
    set(${COMPONENT_NAME}_BINARY_DIR ${COMPONENT_BUILD_DIR} PARENT_SCOPE)

    ##############################################################
    # Verifications
    if(COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITH_F90 AND NOT CMAKE_Fortran_COMPILER_SUPPORTS_F90)
        log("Your Fortran compiler ${CMAKE_Fortran_COMPILER} does not support the Fortran 90 standard,
            which is required to build the OpenCMISS component ${COMPONENT_NAME}" ERROR)
    endif()

    ##############################################################
    # Collect component definitions
    set(COMPONENT_DEFS
        ${COMPONENT_COMMON_DEFS} 
        -DCMAKE_INSTALL_PREFIX:PATH=${_INSTALL_PREFIX}
    )

    if (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_RELEASE_ONLY AND NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
        list(APPEND COMPONENT_DEFS -DCMAKE_BUILD_TYPE=Release)
    elseif (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
        list(APPEND COMPONENT_DEFS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
    endif ()

    # Shared or static?
    list(APPEND COMPONENT_DEFS -DBUILD_SHARED_LIBS=${${COMPONENT_NAME}_SHARED})

    # OpenMP multithreading
    if(COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITH_OPENMP)
        list(APPEND COMPONENT_DEFS
            -DWITH_OPENMP=${OC_MULTITHREADING}
        )
    endif()

    if (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        # Set the MPI Executable we have found.
        list(APPEND COMPONENT_DEFS
            -DMPIEXEC_EXECUTABLE=${MPIEXEC_EXECUTABLE}
            -DMPI_VERSION=${MPI_VERSION})
    endif ()
    foreach(lang C CXX Fortran)
        # check if MPI compilers should be forwarded/set
        # so that the local FindMPI uses that
        if(COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
            # Set the MPI compiler we have found for this language.
            if(MPI_${lang}_COMPILER)
                list(APPEND COMPONENT_DEFS
                    -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                )
            endif()
        endif()
        list(APPEND COMPONENT_DEFS
            -DCMAKE_${lang}_COMPILER=${CMAKE_${lang}_COMPILER}
        )
        # Define compiler flags
        if (CMAKE_${lang}_FLAGS)
            list(APPEND COMPONENT_DEFS
                -DCMAKE_${lang}_FLAGS=${CMAKE_${lang}_FLAGS}
            )
        endif()
        # Also forward build-type specific flags
        foreach(BUILDTYPE RELEASE DEBUG)
            if (CMAKE_${lang}_FLAGS_${BUILDTYPE})
                list(APPEND COMPONENT_DEFS
                    -DCMAKE_${lang}_FLAGS_${BUILDTYPE}=${CMAKE_${lang}_FLAGS_${BUILDTYPE}}
                )
            endif()
        endforeach()
    endforeach()

    # Forward any other variables
    foreach(extra_def ${ARGN})
        list(APPEND COMPONENT_DEFS -D${extra_def})
    endforeach()
    log("OpenCMISS component ${COMPONENT_NAME} extra args:\n${COMPONENT_DEFS}" DEBUG)

    # Create the external projects
    createExternalProjects(${COMPONENT_NAME} "${COMPONENT_SOURCE_DIR}" "${COMPONENT_BUILD_DIR}" "${COMPONENT_DEFS}")

    # Create some convenience targets like clean, update etc
    addConvenienceTargets(${COMPONENT_NAME} "${COMPONENT_BUILD_DIR}" "${COMPONENT_SOURCE_DIR}")

    # Add the dependency information for other downstream packages that might use this one
    addDownstreamDependencies(${COMPONENT_NAME} TRUE)

endfunction()

########################################################################################################################
function(createExternalProjects COMPONENT_NAME SOURCE_DIR BINARY_DIR DEFS)

    log("Configuring build of '${COMPONENT_NAME} ${${COMPONENT_NAME}_VERSION}' in ${BINARY_DIR}...")

    getBuildCommands(BUILD_COMMAND INSTALL_COMMAND ${BINARY_DIR} TRUE)

    if (COMPONENT_NAME STREQUAL "EXAMPLES")
        # Special hack for the examples - we want the build to continue even if some examples wont compile.
        # TODO remove later.    
        set(INSTALL_COMMAND ${CMAKE_COMMAND} -E echo "Nothing to install for OpenCMISS examples.")
        if (UNIX)
            list(APPEND BUILD_COMMAND "-i")
        endif()
    #else()
    #    set(INSTALL_COMMAND INSTALL_COMMAND ${INSTALL_COMMAND})
    endif()

    # Log settings
    if (OC_CREATE_LOGS)
        set(_LOGFLAG 1)
    else()
        set(_LOGFLAG 0)
    endif()  

    log("Adding ${COMPONENT_NAME} with DEPS=${${COMPONENT_NAME}_DEPS}" VERBOSE)
    ExternalProject_Add(${OC_EP_PREFIX}${COMPONENT_NAME}
        DEPENDS ${${COMPONENT_NAME}_DEPS}
        PREFIX ${BINARY_DIR}
        LIST_SEPARATOR ${OC_LIST_SEPARATOR}
        TMP_DIR ${BINARY_DIR}/${OC_EXTPROJ_TMP_DIR}
        STAMP_DIR ${BINARY_DIR}/${OC_EXTPROJ_STAMP_DIR}

        #--Download step--------------
        # Ideal solution - include in the external project that also builds.
        # Still a mess with mixed download/build stamp files and even though the UPDATE_DISCONNECTED command
        # skips the update command the configure etc dependency chain is yet executed each time :-(
        #${DOWNLOAD_CMDS}
        #UPDATE_DISCONNECTED 1 # Dont update without being asked. New feature of CMake 3.2.0-rc1

        # Need empty download command, otherwise creation of external project fails with "no download info"
        DOWNLOAD_COMMAND ""

        #--Configure step-------------
        # CONFIGURE_COMMAND "" # Do nothing remove soon
        CMAKE_COMMAND ${CMAKE_COMMAND} --no-warn-unused-cli # disables warnings for unused cmdline options
        SOURCE_DIR ${SOURCE_DIR}
        BINARY_DIR ${BINARY_DIR}
        CMAKE_ARGS ${DEFS}

        #--Build step-----------------
        BUILD_COMMAND ${BUILD_COMMAND}
        #--Install step---------------
        # currently set as extra arg (above), somehow does not work
        #INSTALL_DIR ${CMAKE_INSTALL_PREFIX} 
        INSTALL_COMMAND ${INSTALL_COMMAND}
        # Logging
        LOG_CONFIGURE ${_LOGFLAG}
        LOG_BUILD ${_LOGFLAG}
        LOG_INSTALL ${_LOGFLAG}
    )
    set_target_properties(${OC_EP_PREFIX}${COMPONENT_NAME} PROPERTIES FOLDER "ExternalProjects")

    # See OpenCMISSInstallationConfig.cmake
    if (OC_CLEAN_REBUILDS_COMPONENTS)
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BINARY_DIR}/CMakeCache.txt)
    endif()

    doSupportStuff(${COMPONENT_NAME} "${SOURCE_DIR}" "${BINARY_DIR}" "${DEFS}")

endfunction()

include(OCFunctionComponentTargets)

function(getBuildCommands BUILD_CMD_VAR INSTALL_CMD_VAR DIR PARALLEL)

    set(BUILD_CMD ${CMAKE_COMMAND} --build "${DIR}")
    set(INSTALL_CMD ${CMAKE_COMMAND} --build "${DIR}" --target install)
    if (OPENCMISS_HAVE_MULTICONFIG_ENV)
        if (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_RELEASE_ONLY)
            list(APPEND BUILD_CMD --config Release)
            list(APPEND INSTALL_CMD --config Release)
        else ()
            list(APPEND BUILD_CMD --config $<CONFIG>)
            list(APPEND INSTALL_CMD --config $<CONFIG>)
        endif ()
    endif()

    if(PARALLEL_BUILDS AND PARALLEL)
        include(ProcessorCount)
        ProcessorCount(NUM_PROCESSORS)
        if (NUM_PROCESSORS EQUAL 0)
            set(NUM_PROCESSORS 1)
        #else()
        #    MATH(EXPR NUM_PROCESSORS ${NUM_PROCESSORS}+4)
        endif()

        if (CMAKE_GENERATOR MATCHES "^Visual Studio")
            set(GENERATOR_MATCH_VISUAL_STUDIO TRUE)
        elseif(CMAKE_GENERATOR MATCHES "^NMake Makefiles$")
            set(GENERATOR_MATCH_NMAKE TRUE)
        elseif(CMAKE_GENERATOR MATCHES "^Unix Makefiles$"
            OR CMAKE_GENERATOR MATCHES "^MinGW Makefiles$"
            OR CMAKE_GENERATOR MATCHES "^MSYS Makefiles$")
            set(GENERATOR_MATCH_MAKE TRUE)
        endif()

        if(GENERATOR_MATCH_MAKE OR GENERATOR_MATCH_NMAKE)
            list(APPEND BUILD_CMD -- "-j${NUM_PROCESSORS}")
            list(APPEND INSTALL_CMD -- "-j${NUM_PROCESSORS}")
        elseif(GENERATOR_MATCH_VISUAL_STUDIO)
            #list(APPEND BUILD_CMD -- /MP)
            #list(APPEND INSTALL_CMD -- /MP)
        endif()
    endif()

    set(${BUILD_CMD_VAR} ${BUILD_CMD} PARENT_SCOPE)
    set(${INSTALL_CMD_VAR} ${INSTALL_CMD} PARENT_SCOPE)
endfunction()

# IN_PARENT_SCOPE: Set results in PARENT_SCOPE.
#   Thus far used here in addAndConfigureLocalComponent and in OCMPIConfig.cmake for MPI
macro(addDownstreamDependencies COMPONENT_NAME IN_PARENT_SCOPE)
    if (${COMPONENT_NAME}_FWD_DEPS)
        log("Component ${COMPONENT_NAME} has forward dependencies: ${${COMPONENT_NAME}_FWD_DEPS}" VERBOSE)
        # Add all new forward dependencies of component
        foreach(FWD_DEP ${${COMPONENT_NAME}_FWD_DEPS})
            log("Adding ${COMPONENT_NAME} to ${FWD_DEP}_DEPS" VERBOSE)  
            list(APPEND ${FWD_DEP}_DEPS "${OC_EP_PREFIX}${COMPONENT_NAME}")
            # Propagate the changed variable to outside this function - its a function
            if (${IN_PARENT_SCOPE})
                set(${FWD_DEP}_DEPS ${${FWD_DEP}_DEPS} PARENT_SCOPE)
            endif()
        endforeach()
    endif()
endmacro()

function(doSupportStuff NAME SRC BIN DEFS)
    # Write support log file
    set(SUPPORT_FILE "${OPENCMISS_SUPPORT_DIR}/${NAME}-buildconfig.txt")
    string(TIMESTAMP NOW)
    file(WRITE "${SUPPORT_FILE}" "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Automatically generated OpenCMISS support file, ${NOW}
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

Build configuration file for OpenCMISS component ${NAME}-${${NAME}_VERSION}

Source directory '${SRC}'
Build directory '${BIN}'

Configure definitions:
")
    foreach(_DEF ${DEFS})
        file(APPEND "${SUPPORT_FILE}" "${_DEF}\r\n")
    endforeach()

    # Only create log-collecting commands if we create them 
    if (OC_CREATE_LOGS)
        # Using PRE_BUILD directly for target support does not work :-| See docs.
        # So we have an extra target in between. 
        add_custom_target(${OC_SM_PREFIX}${NAME}_collect_log
            COMMAND ${CMAKE_COMMAND}
                -DLOG_DIR=${BIN}/${OC_EXTPROJ_STAMP_DIR}
                -DSUPPORT_DIR=${OPENCMISS_SUPPORT_DIR} 
                -P ${PROJECT_SOURCE_DIR}/Scripts/OCCollectLogs.cmake
            COMMENT "Support: Collecting ${COMPONENT_NAME} log files"
        )
        add_dependencies(collect_logs ${OC_SM_PREFIX}${NAME}_collect_log)
        set_target_properties(${OC_SM_PREFIX}${NAME}_collect_log PROPERTIES FOLDER "Internal")
    endif()

    add_custom_target(${OC_SM_PREFIX}${NAME}_build_log
        COMMAND ${CMAKE_COMMAND}
            -DCOMPONENT_NAME=${NAME}
            -DLOGFILE="${OC_BUILD_LOG}"
            -P ${PROJECT_SOURCE_DIR}/Scripts/OCBuildStamp.cmake
        COMMENT "Support: Creating ${COMPONENT_NAME} buildlog"             
        WORKING_DIRECTORY "${OPENCMISS_SUPPORT_DIR}")
    add_dependencies(${OC_EP_PREFIX}${NAME} ${OC_SM_PREFIX}${NAME}_build_log)
    set_target_properties(${OC_SM_PREFIX}${NAME}_build_log PROPERTIES FOLDER "Internal")
endfunction()
