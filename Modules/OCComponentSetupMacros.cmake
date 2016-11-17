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
        set(COMPONENT_SOURCE "${OPENCMISS_LIBRARIES_SOURCE_DIR}/${FOLDER_NAME}")
    else ()
        set(COMPONENT_SOURCE "${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${FOLDER_NAME}")
    endif ()

    # Check which build dir is required - depending on whether this component can be built against mpi
    if (COMPONENT_NAME STREQUAL "IRON")
        set(BUILD_DIR_BASE "${OPENCMISS_LIBRARIES_BINARY_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX})
    elseif (COMPONENT_NAME STREQUAL "ZINC")
        set(BUILD_DIR_BASE "${OPENCMISS_LIBRARIES_BINARY_NO_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_LIBRARIES_INSTALL_NO_MPI_PREFIX})
    elseif (COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        set(BUILD_DIR_BASE "${OPENCMISS_DEPENDENCIES_BINARY_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_DEPENDENCIES_INSTALL_MPI_PREFIX})
    else()
        set(BUILD_DIR_BASE "${OPENCMISS_DEPENDENCIES_BINARY_NO_MPI_DIR}")
        set(_INSTALL_PREFIX ${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX})
    endif()
    # Complete build dir with debug/release AFTER everything else (consistent with windows)
    set(COMPONENT_BUILD_DIR ${BUILD_DIR_BASE}/${FOLDER_NAME}/${BUILD_TYPE_PATH_ELEM})
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
    SET(COMPONENT_DEFS
        ${COMPONENT_COMMON_DEFS} 
        -DCMAKE_INSTALL_PREFIX:STRING=${_INSTALL_PREFIX}
        )
    
    # Shared or static?
    list(APPEND COMPONENT_DEFS -DBUILD_SHARED_LIBS=${${COMPONENT_NAME}_SHARED})
    
    # OpenMP multithreading
    if(COMPONENT_NAME IN_LIST OPENCMISS_COMPONENTS_WITH_OPENMP)
        list(APPEND COMPONENT_DEFS
            -DWITH_OPENMP=${OC_MULTITHREADING}
        )
    endif()
    
    # check if MPI compilers should be forwarded/set
    # so that the local FindMPI uses that
    if(${COMPONENT_NAME} IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        # Pass on settings and take care to undefine them if no longer used at this level
        if (MPI)
            list(APPEND COMPONENT_DEFS -DMPI=${MPI})
        else()
            list(APPEND COMPONENT_DEFS -UMPI)
        endif()
        if (MPI_HOME)
            list(APPEND COMPONENT_DEFS -DMPI_HOME=${MPI_HOME})
        else()
            LIST(APPEND COMPONENT_DEFS -UMPI_HOME)
        endif()
        # Override (=defined later in the args list) Compilers with MPI compilers
        # for all components that may use MPI
        # This takes precedence over the first definition of the compilers
        # collected in COMPONENT_COMMON_DEFS
        foreach(lang C CXX Fortran)
            if(MPI_${lang}_COMPILER)
                list(APPEND COMPONENT_DEFS
                    # Directly specify the compiler wrapper as compiler!
                    # That is a perfect workaround for the "finding MPI after compilers have been initialized" problem
                    # that occurs when building a component directly. 
                    -DCMAKE_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                    # Also specify the MPI_ versions so that FindMPI is faster (checks them directly)
                    -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                )
            endif()
        endforeach()
    else()
        # No MPI: simply set the same compilers.
        foreach(lang C CXX Fortran)
            list(APPEND COMPONENT_DEFS
                -DCMAKE_${lang}_COMPILER=${CMAKE_${lang}_COMPILER}
            )
        endforeach()
    endif()
    
    # Forward any other variables
    foreach(extra_def ${ARGN})
        list(APPEND COMPONENT_DEFS -D${extra_def})
    endforeach()
    log("OpenCMISS component ${COMPONENT_NAME} extra args:\n${COMPONENT_DEFS}" DEBUG)
    
    ##############################################################
    # Create actual external projects
    
    # Create the external projects
    createExternalProjects(${COMPONENT_NAME} "${COMPONENT_SOURCE}" "${COMPONENT_BUILD_DIR}" "${COMPONENT_DEFS}")
    
    # Create some convenience targets like clean, update etc
    addConvenienceTargets(${COMPONENT_NAME} "${COMPONENT_BUILD_DIR}" "${COMPONENT_SOURCE}")
    
    # Add the dependency information for other downstream packages that might use this one
    addDownstreamDependencies(${COMPONENT_NAME} TRUE)
    
endfunction()

########################################################################################################################
function(addSourceManagementTargets COMPONENT_NAME BINARY_DIR SOURCE_DIR)
    # Convention: github repo is the lowercase equivalent of the component name
    string(TOLOWER ${COMPONENT_NAME} REPO_NAME)
    
    # Git clone mode
    if(GIT_FOUND)
        # Construct the repository name 
        if (NOT ${COMPONENT_NAME}_REPO)
            if(GITHUB_USERNAME)
                SET(_GITHUB_USERNAME ${GITHUB_USERNAME})
            else()
                SET(_GITHUB_USERNAME ${GITHUB_ORGANIZATION})
            endif()
            if (GITHUB_USE_SSL)
                SET(GITHUB_PROTOCOL "git@github.com:")
            else()
                SET(GITHUB_PROTOCOL "https://github.com/")
            endif()
            set(${COMPONENT_NAME}_REPO ${GITHUB_PROTOCOL}${_GITHUB_USERNAME}/${REPO_NAME})
        endif()
        
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_download
            COMMAND ${GIT_EXECUTABLE} clone ${${COMPONENT_NAME}_REPO} .
            COMMAND ${GIT_EXECUTABLE} checkout ${${COMPONENT_NAME}_BRANCH}
            COMMENT "Cloning ${COMPONENT_NAME} sources"
            WORKING_DIRECTORY "${SOURCE_DIR}"
        )
        
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update
            DEPENDS ${OC_SM_PREFIX}${COMPONENT_NAME}_sources
            COMMAND ${GIT_EXECUTABLE} pull
            COMMAND ${GIT_EXECUTABLE} checkout ${${COMPONENT_NAME}_BRANCH}
            COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/${OC_EXTPROJ_STAMP_DIR}/*-build
            COMMENT "Updating ${COMPONENT_NAME} sources"
            WORKING_DIRECTORY "${SOURCE_DIR}"
        )
            
    # Fallback: Download the current version branch as zip
    else()
        # Unless explicitly specified, use the GitHub repository location
        if (NOT ${COMPONENT_NAME}_REPO)
            set(${COMPONENT_NAME}_REPO https://github.com/${GITHUB_ORGANIZATION}/${REPO_NAME})
        endif()
        
        set(_FILENAME ${${COMPONENT_NAME}_BRANCH}.tar.gz)
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_download
            COMMAND ${CMAKE_COMMAND}
                -DMODE=Download
                -DURL=${${COMPONENT_NAME}_REPO}/archive/${_FILENAME}
                -DTARGET="${SOURCE_DIR}/${_FILENAME}"
                -P ${MANAGE_MODULE_PATH}/Scripts/OCSourceManager.cmake
            COMMENT "Downloading ${COMPONENT_NAME} sources"
        )
        
        # For tarballs, update is the same as download!
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update
            DEPENDS ${OC_SM_PREFIX}${REPO_NAME}_download
            COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/${OC_EXTPROJ_STAMP_DIR}/*-build
            COMMENT "Updating ${COMPONENT_NAME} sources"
        )
    endif()
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_download PROPERTIES FOLDER "Source management")
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_update PROPERTIES FOLDER "Source management")
    
    # Add extra target that makes sure the source files are being present
    # Triggers build of ${OC_SM_PREFIX}${REPO_NAME}_download if the directory does not exist or 
    # no CMakeLists.txt is found in the target source directory.
    add_custom_target(${OC_SM_PREFIX}${COMPONENT_NAME}_sources
        COMMAND ${CMAKE_COMMAND}
            -DMODE=Check
            -DCOMPONENT=${REPO_NAME}
            -DSRC_DIR=${SOURCE_DIR}
            -DBIN_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -P ${MANAGE_MODULE_PATH}/Scripts/OCSourceManager.cmake
        COMMENT "Checking ${COMPONENT_NAME} sources are present"
    )
    set_target_properties(${OC_SM_PREFIX}${COMPONENT_NAME}_sources PROPERTIES FOLDER "Internal")
    
    add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update_force
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${SOURCE_DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${SOURCE_DIR}"
        COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${OC_SM_PREFIX}${REPO_NAME}_download
        COMMENT "Forced update of ${COMPONENT_NAME} - removing and downloading"
    )
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_update_force PROPERTIES FOLDER "Source management")
    
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
        
    addSourceManagementTargets(${COMPONENT_NAME} ${BINARY_DIR} ${SOURCE_DIR})
    
    # Log settings
    if (OC_CREATE_LOGS)
        set(_LOGFLAG 1)
    else()
        set(_LOGFLAG 0)
    endif()  
    
    log("Adding ${COMPONENT_NAME} with DEPS=${${COMPONENT_NAME}_DEPS}" VERBOSE)
    ExternalProject_Add(${OC_EP_PREFIX}${COMPONENT_NAME}
        DEPENDS ${${COMPONENT_NAME}_DEPS} ${OC_SM_PREFIX}${COMPONENT_NAME}_sources
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
    CONFIGURE_COMMAND "" # Do nothing remove soon
        CMAKE_COMMAND "" # ${CMAKE_COMMAND} --no-warn-unused-cli # disables warnings for unused cmdline options
        SOURCE_DIR ${SOURCE_DIR}
        BINARY_DIR ${BINARY_DIR}
        CMAKE_ARGS "" # ${DEFS}
        
        #--Build step-----------------
        BUILD_COMMAND "" # ${BUILD_COMMAND}
        #--Install step---------------
        # currently set as extra arg (above), somehow does not work
        #INSTALL_DIR ${CMAKE_INSTALL_PREFIX} 
        INSTALL_COMMAND "" # ${INSTALL_COMMAND}
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
    if (CMAKE_HAVE_MULTICONFIG_ENV)
        list(APPEND BUILD_CMD --config $<CONFIG>)
        list(APPEND INSTALL_CMD --config $<CONFIG>)
    endif()
    
    if(PARALLEL_BUILDS AND PARALLEL)
        include(ProcessorCount)
        ProcessorCount(NUM_PROCESSORS)
        if (NUM_PROCESSORS EQUAL 0)
            SET(NUM_PROCESSORS 1)
        #else()
        #    MATH(EXPR NUM_PROCESSORS ${NUM_PROCESSORS}+4)
        endif()
        
        if (CMAKE_GENERATOR MATCHES "^Visual Studio")
            SET(GENERATOR_MATCH_VISUAL_STUDIO TRUE)
        elseif(CMAKE_GENERATOR MATCHES "^NMake Makefiles$")
            SET(GENERATOR_MATCH_NMAKE TRUE)
        elseif(CMAKE_GENERATOR MATCHES "^Unix Makefiles$"
            OR CMAKE_GENERATOR MATCHES "^MinGW Makefiles$"
            OR CMAKE_GENERATOR MATCHES "^MSYS Makefiles$")
            SET(GENERATOR_MATCH_MAKE TRUE)
        endif()
        
        if(GENERATOR_MATCH_MAKE OR GENERATOR_MATCH_NMAKE)
            LIST(APPEND BUILD_CMD -- "-j${NUM_PROCESSORS}")
            LIST(APPEND INSTALL_CMD -- "-j${NUM_PROCESSORS}")
        elseif(GENERATOR_MATCH_VISUAL_STUDIO)
            #LIST(APPEND BUILD_CMD -- /MP)
            #LIST(APPEND INSTALL_CMD -- /MP)
        endif()
    endif()

    SET(${BUILD_CMD_VAR} ${BUILD_CMD} PARENT_SCOPE)
    SET(${INSTALL_CMD_VAR} ${INSTALL_CMD} PARENT_SCOPE)
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
                -P ${OPENCMISS_MODULE_PATH}/CMakeScripts/OCSupport.cmake
            COMMENT "Support: Collecting ${COMPONENT_NAME} log files"
        )
        add_dependencies(collect_logs ${OC_SM_PREFIX}${NAME}_collect_log)
        set_target_properties(${OC_SM_PREFIX}${NAME}_collect_log PROPERTIES FOLDER "Internal")
    endif()
    
    add_custom_target(${OC_SM_PREFIX}${NAME}_build_log
        COMMAND ${CMAKE_COMMAND}
            -DBUILD_STAMP=YES 
            -DCOMPONENT_NAME=${NAME}
            -DLOGFILE="${OC_BUILD_LOG}"
            -P ${OPENCMISS_MODULE_PATH}/CMakeScripts/OCSupport.cmake
        COMMENT "Support: Creating ${COMPONENT_NAME} buildlog"             
        WORKING_DIRECTORY "${OPENCMISS_SUPPORT_DIR}")
    add_dependencies(${OC_EP_PREFIX}${NAME} ${OC_SM_PREFIX}${NAME}_build_log)
    set_target_properties(${OC_SM_PREFIX}${NAME}_build_log PROPERTIES FOLDER "Internal")
endfunction()
