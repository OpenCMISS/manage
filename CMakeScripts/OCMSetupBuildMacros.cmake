MACRO(ADD_COMPONENT COMPONENT_NAME)
    # Get lowercase folder name from project name
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME) 
    
    # set source directory
    SET(COMPONENT_SOURCE ${OPENCMISS_ROOT}/src/${SUBGROUP_PATH}/${FOLDER_NAME})
    SET(COMPONENT_DEFS ${COMPONENT_COMMON_DEFS})
    
    # Complete build dir with debug/release AFTER everything else (consistent with windows)
    get_build_type_extra(BUILDTYPEEXTRA)
    
    # Check which build dir is required - depending on whether this component can be built against mpi
    list(FIND OPENCMISS_COMPONENTS_WITHMPI ${COMPONENT_NAME} COMP_WITH_MPI)
    if (COMP_WITH_MPI GREATER -1)
        SET(COMPONENT_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/${SUBGROUP_PATH}/${FOLDER_NAME}/${BUILDTYPEEXTRA})
        LIST(APPEND COMPONENT_DEFS -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI})
    else()
        SET(COMPONENT_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/${SUBGROUP_PATH}/${FOLDER_NAME}/${BUILDTYPEEXTRA})
        LIST(APPEND COMPONENT_DEFS -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX})
    endif()
    
    message(STATUS "Configuring build of ${COMPONENT_NAME} in ${COMPONENT_BUILD_DIR}...")
    
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

	GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${COMPONENT_BUILD_DIR} TRUE)

    SET(DOWNLOAD_CMDS )
    # Developer mode
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
            set(_UPDATE_COMMAND UPDATE_COMMAND ${GIT_EXECUTABLE} pull)
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
            DOWNLOAD_DIR ${COMPONENT_SOURCE}/src-download
            #URL https://github.com/${GITHUB_ORGANIZATION}/${FOLDER_NAME}/archive/${${COMPONENT_NAME}_BRANCH}.zip
            ################@TEMP@#################
            URL ${${COMPONENT_NAME}_REPO}/archive/${${COMPONENT_NAME}_BRANCH}.zip
            ################@TEMP@#################
        )
    endif()
    
    # Log settings
    if (OCM_CREATE_LOGS)
        set(_LOGFLAG 1)
    else()
        set(_LOGFLAG 0)
    endif()
    
    # Add source download/update project
    LIST(APPEND _OCM_REQUIRED_SOURCES ${COMPONENT_NAME})
    ExternalProject_Add(${COMPONENT_NAME}_SRC
        PREFIX ${OPENCMISS_ROOT}/src/download/
        EXCLUDE_FROM_ALL 1
        TMP_DIR ${OPENCMISS_ROOT}/src/download/tmp
        STAMP_DIR ${OPENCMISS_ROOT}/src/download/stamps
        #--Download step--------------
        ${DOWNLOAD_CMDS}
        SOURCE_DIR ${COMPONENT_SOURCE}
        ${_UPDATE_COMMAND}
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
        STEP_TARGETS download update
        LOG_DOWNLOAD ${_LOGFLAG}
    )
    
	ExternalProject_Add(${COMPONENT_NAME}
		DEPENDS ${${COMPONENT_NAME}_DEPS}
		PREFIX ${COMPONENT_BUILD_DIR}
		LIST_SEPARATOR ${OCM_LIST_SEPARATOR}
		TMP_DIR ${COMPONENT_BUILD_DIR}/ep_tmp
		STAMP_DIR ${COMPONENT_BUILD_DIR}/ep_stamps
		
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
		SOURCE_DIR ${COMPONENT_SOURCE}
		BINARY_DIR ${COMPONENT_BUILD_DIR}
		CMAKE_ARGS ${COMPONENT_DEFS}
		
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
        set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${COMPONENT_BUILD_DIR}/CMakeCache.txt)
    endif()
	
	# Add extra step that makes sure the source files at least exist at the first run.
	# Triggers build of ${COMPONENT_NAME}_SRC if not found.
	# Adding the DEPENDS line also takes care to re-build the component whenever the main cmakelists.txt changes.
	#
	# This could be added as DOWNLOAD_COMMAND inside the ExternalProject_Add above, however, this feels cleaner
	# and can be commented out easier
	ExternalProject_Add_Step(${COMPONENT_NAME} check_sources
	        COMMAND ${CMAKE_COMMAND}
                -DTARGET=${COMPONENT_NAME}_SRC-download
                -DFOLDER=${COMPONENT_SOURCE}
                -DBINDIR=${CMAKE_CURRENT_BINARY_DIR}
                -P ${OPENCMISS_MANAGE_DIR}/CMakeScripts/CheckSourceExists.cmake
            DEPENDERS configure
	)
	# Add convenience direct-access clean target for component
	add_custom_target(${COMPONENT_NAME}-clean
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${COMPONENT_BUILD_DIR}/ep_stamps/*-configure 
	    COMMAND ${CMAKE_COMMAND} --build ${COMPONENT_BUILD_DIR} --target clean
	)
	# Add convenience direct-access update target for component
	# (This just invokes the ${COMPONENT_NAME}_SRC-update target exposed in the source external project,
	# essentially allowing to call ${COMPONENT_NAME}-update instead of ${COMPONENT_NAME}_SRC-update)
	add_custom_target(${COMPONENT_NAME}-update
	    #COMMAND ${CMAKE_COMMAND} -E remove -f ${COMPONENT_BUILD_DIR}/ep_stamps/*-configure 
	    COMMAND ${CMAKE_COMMAND} --build ${COMPONENT_BUILD_DIR} --target ${COMPONENT_NAME}_SRC-update
	)
	# Add convenience direct-access forced build target for component
	add_custom_target(${COMPONENT_NAME}-build
	    COMMAND ${CMAKE_COMMAND} -E remove -f ${COMPONENT_BUILD_DIR}/ep_stamps/*-build 
	    COMMAND ${CMAKE_COMMAND} --build ${COMPONENT_BUILD_DIR} --target install
	)
	if (BUILD_TESTS)
    	# Add convenience direct-access test target for component
    	add_custom_target(${COMPONENT_NAME}-test
    	    COMMAND ${CMAKE_COMMAND} --build ${COMPONENT_BUILD_DIR} --target test
    	)
    	# Add a global test to run the external project's tests
    	add_test(${COMPONENT_NAME}-test ${CMAKE_COMMAND} --build ${COMPONENT_BUILD_DIR} --target test)
	endif()
	
	# Be a tidy kiwi
	UNSET( BUILD_COMMAND )
	UNSET( INSTALL_COMMAND )
	
	# Add the dependency information for other downstream packages that might use this one
	ADD_DOWNSTREAM_DEPS(${COMPONENT_NAME})
    #message(STATUS "Dependencies of ${COMPONENT_NAME}: ${${COMPONENT_NAME}_DEPS}")
    
ENDMACRO()

MACRO(ADD_DOWNSTREAM_DEPS PACKAGE)
    if (${PACKAGE}_FWD_DEPS)
        #message(STATUS "Package ${PACKAGE} has forward dependencies: ${${PACKAGE}_FWD_DEPS}")
        foreach(FWD_DEP ${${PACKAGE}_FWD_DEPS})
            #message(STATUS "adding ${PACKAGE} to fwd-dep ${FWD_DEP}_DEPS")  
            LIST(APPEND ${FWD_DEP}_DEPS ${PACKAGE})
        endforeach()
    endif()
ENDMACRO()

macro(GET_BUILD_COMMANDS BUILD_CMD_VAR INSTALL_CMD_VAR DIR PARALLEL)
    
    SET( BUILD_CMD ${CMAKE_COMMAND} --build ${DIR})
    SET( INSTALL_CMD ${CMAKE_COMMAND} --build ${DIR} --target install)
    
    if(PARALLEL_BUILDS AND ${PARALLEL})
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

	SET(${BUILD_CMD_VAR} ${BUILD_CMD})
	SET(${INSTALL_CMD_VAR} ${INSTALL_CMD})
endmacro()
