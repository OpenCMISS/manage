########################################################################################################################
# This is the main function that adds an OpenCMISS component to the build tree.
#
# Consumes all sorts of global variables, where SUBGROUP_PATH and GITHUB_ORGANIZATION are the ones 
# subsequently changed between function calls in ConfigureComponents 
function(addAndConfigureLocalComponent COMPONENT_NAME)
    # Get lowercase folder name from project name
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME)
    
    # Keep track of self-build components (thus far only used for "update" target)
    #list(APPEND _OCM_SELECTED_COMPONENTS ${COMPONENT_NAME})
    # Need this since it's a function
    set(_OCM_SELECTED_COMPONENTS ${_OCM_SELECTED_COMPONENTS} ${COMPONENT_NAME} PARENT_SCOPE)
    
    ##############################################################
    # Set source directory
    SET(COMPONENT_SOURCE ${OPENCMISS_ROOT}/src/${SUBGROUP_PATH}/${FOLDER_NAME})
    
    ##############################################################
    # Set build/binary directory
    
    # Complete build dir with debug/release AFTER everything else (consistent with windows)
    getBuildTypePathElem(BUILDTYPEEXTRA)
    
    # Check which build dir is required - depending on whether this component can be built against mpi
    if (${COMPONENT_NAME} IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        SET(COMPONENT_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/${SUBGROUP_PATH}/${FOLDER_NAME}/${BUILDTYPEEXTRA})
        LIST(APPEND COMPONENT_DEFS -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI})
    else()
        SET(COMPONENT_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/${SUBGROUP_PATH}/${FOLDER_NAME}/${BUILDTYPEEXTRA})
        LIST(APPEND COMPONENT_DEFS -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX})
    endif()
    
    ##############################################################
    # Collect component definitions
    SET(COMPONENT_DEFS ${COMPONENT_COMMON_DEFS})
    
    # OpenMP multithreading
    if(${COMPONENT_NAME} IN_LIST OPENCMISS_COMPONENTS_WITH_OPENMP)
        LIST(APPEND COMPONENT_DEFS
            -DWITH_OPENMP=${OCM_USE_MT}
        )
    endif()
    
    # check if MPI compilers should be forwarded/set
    # so that the local FindMPI uses that
    if(${COMPONENT_NAME} IN_LIST OPENCMISS_COMPONENTS_WITHMPI)
        # Pass on settings and take care to undefine them if no longer used at this level
        if (MPI)
            LIST(APPEND COMPONENT_DEFS -DMPI=${MPI})
        else()
            LIST(APPEND COMPONENT_DEFS -UMPI)
        endif()
        if (MPI_HOME)
            LIST(APPEND COMPONENT_DEFS -DMPI_HOME=${MPI_HOME})
        else()
            LIST(APPEND COMPONENT_DEFS -UMPI_HOME)
        endif()
        # Override Compilers with MPI compilers
        # for all components that may use MPI
        foreach(lang C CXX Fortran)
            if(MPI_${lang}_COMPILER)
                LIST(APPEND COMPONENT_DEFS
                    # Directly specify the compiler wrapper as compiler!
                    # That is a perfect workaround for the "finding MPI after compilers have been initialized" problem
                    # that occurs when building a component directly. 
                    -DCMAKE_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                    # Also specify the MPI_ versions so that FindMPI is faster
                    -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                )
            endif()
        endforeach()
    endif()
    
	# Forward any other variables
    foreach(extra_def ${ARGN})
        LIST(APPEND COMPONENT_DEFS -D${extra_def})
        #message(STATUS "${COMPONENT_NAME}: Using extra definition -D${extra_def}")
    endforeach()
    
    #message(STATUS "OpenCMISS component ${COMPONENT_NAME} extra args:\n${COMPONENT_DEFS}")
    
    ##############################################################
    # Create actual external projects
    
    # Create the external projects
    createExternalProjects(${COMPONENT_NAME} ${COMPONENT_SOURCE} ${COMPONENT_BUILD_DIR} ${COMPONENT_DEFS})
	
	# Create some convenience targets like clean, update etc
	addConvenienceTargets(${COMPONENT_NAME} ${COMPONENT_BUILD_DIR})
		
	# Add the dependency information for other downstream packages that might use this one
	addDownstreamDependencies(${COMPONENT_NAME})
    
endfunction()

########################################################################################################################
function(getExtProjDownloadUpdateCommands COMPONENT_NAME TARGET_SOURCE_DIR DL_VAR UP_VAR)
    # Convention: github repo is the lowercase equivalent of the component name
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME)
    
    # Git clone mode
    if (${OCM_GIT_CLONE_${COMPONENT_NAME}})
        find_package(Git)
        if(GIT_FOUND)
            #message(STATUS "GITHUB_ORGANIZATION=${GITHUB_ORGANIZATION}, GITHUB_USERNAME=${GITHUB_USERNAME}")
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
                set(${COMPONENT_NAME}_REPO ${GITHUB_PROTOCOL}${_GITHUB_USERNAME}/${FOLDER_NAME})
            endif()
            SET(DOWNLOAD_CMDS
                GIT_REPOSITORY ${${COMPONENT_NAME}_REPO}
                GIT_TAG ${${COMPONENT_NAME}_BRANCH}
            )
            set(${UP_VAR} UPDATE_COMMAND ${GIT_EXECUTABLE} pull PARENT_SCOPE)
            #message(STATUS "DOWNLOAD_CMDS=${DOWNLOAD_CMDS}")
        else()
            message(FATAL_ERROR "Could not find GIT. GIT is required if OCM_GIT_CLONE_${COMPONENT_NAME} is set.")
        endif()
    
    # Default: Download the current version branch as zip of no git clone flag is set
    else()
        ################@TEMP@#################
        # Temporary fix to also adhere to "custom" repository locations when in user mode.
        # Should be removed in final version.
        if (NOT ${COMPONENT_NAME}_REPO)
            SET(${COMPONENT_NAME}_REPO https://github.com/${GITHUB_ORGANIZATION}/${FOLDER_NAME})
        endif()
        ################@TEMP@#################
        SET(DOWNLOAD_CMDS
            DOWNLOAD_DIR ${TARGET_SOURCE_DIR}/src-download
            #URL https://github.com/${GITHUB_ORGANIZATION}/${FOLDER_NAME}/archive/${${COMPONENT_NAME}_BRANCH}.zip
            ################@TEMP@#################
            URL ${${COMPONENT_NAME}_REPO}/archive/${${COMPONENT_NAME}_BRANCH}.zip
            ################@TEMP@#################
        )
    endif()
endfunction()

########################################################################################################################

function(createExternalProjects COMPONENT_NAME SOURCE_DIR BINARY_DIR DEFS)

    message(STATUS "Configuring build of '${COMPONENT_NAME}' in ${BINARY_DIR}...")

    getBuildCommands(BUILD_COMMAND INSTALL_COMMAND ${BINARY_DIR} TRUE)

    getExtProjDownloadUpdateCommands(${COMPONENT_NAME} ${SOURCE_DIR} DOWNLOAD_COMMANDS UPDATE_COMMANDS)
    
    # Log settings
    if (OCM_CREATE_LOGS)
        set(_LOGFLAG 1)
    else()
        set(_LOGFLAG 0)
    endif()
    
    # Add source download/update project
    #
    # This is separate from the actual build project for the component, as we want to use the same
    # source for different builds/architecture paths (shared/static, different MPI)
    ExternalProject_Add(${COMPONENT_NAME}_SRC
        PREFIX ${OPENCMISS_ROOT}/src/download/
        EXCLUDE_FROM_ALL 1
        TMP_DIR ${OPENCMISS_ROOT}/src/download/tmp
        STAMP_DIR ${OPENCMISS_ROOT}/src/download/stamps
        #--Download step--------------
        ${DOWNLOAD_COMMANDS}
        SOURCE_DIR ${SOURCE_DIR}
        ${UPDATE_COMMANDS}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        STEP_TARGETS download update
        LOG_DOWNLOAD ${_LOGFLAG}
    )
    
    # Add extra target that makes sure the source files are being present
	# Triggers build of ${COMPONENT_NAME}_SRC if no CMakeLists.txt is found in the target source directory.
	add_custom_target(CHECK_${COMPONENT_NAME}_SOURCES 
	        COMMAND ${CMAKE_COMMAND}
                -DCOMPONENT=${COMPONENT_NAME}
                -DFOLDER=${SOURCE_DIR}
                -DBINDIR=${CMAKE_CURRENT_BINARY_DIR}
                -DSTAMP_DIR=${OPENCMISS_ROOT}/src/download/stamps
                -P ${OPENCMISS_MANAGE_DIR}/CMakeScripts/CheckSourceExists.cmake
            COMMENT "Checking ${COMPONENT_NAME} sources are present"
    )  
    
	ExternalProject_Add(${COMPONENT_NAME}
		DEPENDS ${${COMPONENT_NAME}_DEPS} CHECK_${COMPONENT_NAME}_SOURCES
		PREFIX ${BINARY_DIR}
		LIST_SEPARATOR ${OCM_LIST_SEPARATOR}
		TMP_DIR ${BINARY_DIR}/ep_tmp
		STAMP_DIR ${BINARY_DIR}/ep_stamps
		
		#--Download step--------------
		# Ideal solution - include in the external project that also builds.
		# Still a mess with mixed download/build stamp files and even though the UPDATE_DISCONNECTED command
		# skips the update command the configure etc dependency chain is yet executed each time :-(
        #${DOWNLOAD_CMDS}
        #UPDATE_DISCONNECTED 1 # Dont update without being asked. New feature of CMake 3.2.0-rc1
		
        # Need empty download command, otherwise creation of external project fails with "no download info"
		DOWNLOAD_COMMAND ""
		
		#--Configure step-------------
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
		
	# See OpenCMISSDeveloper.cmake
	if (OCM_CLEAN_REBUILDS_COMPONENTS)
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${BINARY_DIR}/CMakeCache.txt)
    endif()
endfunction()

function(addDownstreamDependencies COMPONENT_NAME)
    if (${COMPONENT_NAME}_FWD_DEPS)
        #message(STATUS "Component ${COMPONENT_NAME} has forward dependencies: ${${COMPONENT_NAME}_FWD_DEPS}")
        # Initialize with current values
        set(_DEPS ${${FWD_DEP}_DEPS})
        # Add all new forward dependencies of component
        foreach(FWD_DEP ${${COMPONENT_NAME}_FWD_DEPS})
            #message(STATUS "adding ${COMPONENT_NAME} to fwd-dep ${FWD_DEP}_DEPS")  
            LIST(APPEND _DEPS ${COMPONENT_NAME})
        endforeach()
        # Update in parent scope
        set(${FWD_DEP}_DEPS ${_DEPS} PARENT_SCOPE)
    endif()
    #message(STATUS "Dependencies of ${COMPONENT_NAME}: ${${COMPONENT_NAME}_DEPS}")
endfunction()

function(addConvenienceTargets COMPONENT_NAME BINARY_DIR)
    # Add convenience direct-access clean target for component
	add_custom_target(${COMPONENT_NAME}-clean
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/ep_stamps/*-configure 
	    COMMAND ${CMAKE_COMMAND} --build ${BINARY_DIR} --target clean
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/CMakeCache.txt
	)
	# Add convenience direct-access update target for component
	# (This just invokes the ${COMPONENT_NAME}_SRC-update target exposed in the source external project,
	# essentially allowing to call ${COMPONENT_NAME}-update instead of ${COMPONENT_NAME}_SRC-update)
	add_custom_target(${COMPONENT_NAME}-update
	    #COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/ep_stamps/*-configure 
	    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR} --target ${COMPONENT_NAME}_SRC-update
	)
	# Add convenience direct-access forced build target for component
	add_custom_target(${COMPONENT_NAME}-build
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/ep_stamps/*-build 
	    COMMAND ${CMAKE_COMMAND} --build ${BINARY_DIR} --target install
	)
	if (BUILD_TESTS)
    	# Add convenience direct-access test target for component
    	add_custom_target(${COMPONENT_NAME}-test
    	    COMMAND ${CMAKE_COMMAND} --build ${BINARY_DIR} --target test
    	)
    	# Add a global test to run the external project's tests
    	add_test(${COMPONENT_NAME}-test ${CMAKE_COMMAND} --build ${BINARY_DIR} --target test)
	endif()
endfunction()

function(getBuildCommands BUILD_CMD_VAR INSTALL_CMD_VAR DIR PARALLEL)
    
    SET( BUILD_CMD ${CMAKE_COMMAND} --build ${DIR})
    SET( INSTALL_CMD ${CMAKE_COMMAND} --build ${DIR} --target install)
    
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
