find_program(GIT_EXECUTABLE git)
if (GIT_EXECUTABLE)
    if(WIN32)
        SET(GIT_COMMAND cmd /c ${GIT_EXECUTABLE})
    else()
        SET(GIT_COMMAND ${GIT_EXECUTABLE})
    endif()
endif()

MACRO(ADD_COMPONENT COMPONENT_NAME)
    
    # Get lowercase folder name from project name
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME) 
    
    # set source directory
    SET(COMPONENT_SOURCE ${OPENCMISS_ROOT}/src/${SUBGROUP_PATH}/${FOLDER_NAME})
    
    # Complete build dir with debug/release AFTER everything else (consistent with windows)
    get_build_type_extra(BUILDTYPEEXTRA)
    SET(COMPONENT_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/${SUBGROUP_PATH}/${FOLDER_NAME}/${BUILDTYPEEXTRA})
    
    message(STATUS "Building OpenCMISS component ${COMPONENT_NAME} in ${COMPONENT_BUILD_DIR}...")
    
    SET(COMPONENT_DEFS ${COMPONENT_COMMON_DEFS})
    
    # OpenMP multithreading
    foreach(DEP ${OPENCMISS_COMPONENTS_WITH_OPENMP})
        if(${DEP} STREQUAL ${COMPONENT_NAME})
            LIST(APPEND COMPONENT_DEFS
                -DWITH_OPENMP=${OCM_USE_MT}
            )
        endif()
    endforeach()
    
    # check if MPI compilers should be forwarded/set
    # so that the local FindMPI uses that
    foreach(DEP ${OPENCMISS_COMPONENTS_WITHMPI})
        if(${DEP} STREQUAL ${COMPONENT_NAME})
            if (MPI)
                LIST(APPEND COMPONENT_DEFS
                    -DMPI=${MPI}
                )
            endif()
            if (MPI_HOME)
                LIST(APPEND COMPONENT_DEFS
                    -DMPI_HOME=${MPI_HOME}
                )
            endif()
            foreach(lang C CXX Fortran)
                if(MPI_${lang}_COMPILER)
                    LIST(APPEND COMPONENT_DEFS
                        -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                    )
                endif()
            endforeach()
        endif()
    endforeach()
    
	# Forward any other variables
    foreach(extra_def ${ARGN})
        LIST(APPEND COMPONENT_DEFS -D${extra_def})
        #message(STATUS "${COMPONENT_NAME}: Using extra definition -D${extra_def}")
    endforeach()
    
    #message(STATUS "OpenCMISS component ${COMPONENT_NAME} extra args:\n${COMPONENT_DEFS}")

	GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${COMPONENT_BUILD_DIR} TRUE)
    #GET_SUBMODULE_STATUS(SUBMOD_STATUS REV_ID ${OpenCMISS_Dependencies_SOURCE_DIR} ${MODULE_PATH})

    SET(DOWNLOAD_CMDS )
    # Developer mode
    if (${${COMPONENT_NAME}_DEVEL})
        # Need git only for development modes. So scream here if not found!
        #if(NOT GIT_EXECUTABLE)
        #    message(FATAL_ERROR "Development of OpenCMISS components like ${COMPONENT_NAME} requires the GIT executable to be available to cmake (check PATH etc).")
        #endif()
        
        # Check if there already is a git repo at the source location
        #message(STATUS "Running ${GIT_COMMAND} in ${COMPONENT_SOURCE}")
        #execute_process(COMMAND ${GIT_COMMAND} status
        #    RESULT_VARIABLE RES_VAR
        #    OUTPUT_VARIABLE RES
        #    ERROR_VARIABLE RES_ERR
        #    WORKING_DIRECTORY ${COMPONENT_SOURCE}
        #    OUTPUT_STRIP_TRAILING_WHITESPACE)
            
        #if(NOT RES_VAR EQUAL 0)
            if (NOT ${COMPONENT_NAME}_REPO)
                 if(NOT GITHUB_USERNAME)
                    SET(GITHUB_USERNAME ${GITHUB_ORGANIZATION})
                endif()
                if (GITHUB_USE_SSL)
                    SET(GITHUB_PROTOCOL "git@github.com:")
                else()
                    SET(GITHUB_PROTOCOL "https://github.com/")
                endif()
                set(${COMPONENT_NAME}_REPO ${GITHUB_PROTOCOL}${GITHUB_USERNAME}/${FOLDER_NAME})
            endif()
            SET(DOWNLOAD_CMDS
                GIT_REPOSITORY ${${COMPONENT_NAME}_REPO}
                GIT_TAG ${${COMPONENT_NAME}_BRANCH}
            )
            message(STATUS "DOWNLOAD_CMDS=${DOWNLOAD_CMDS}")
        #else()
        #    message(STATUS "Git returned output '${RES}' / error '${RES_ERR}'")
        #endif()
    
    # Default: Download the current version branch as zip of no development flag is set
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
    
	ExternalProject_Add(${COMPONENT_NAME}
		DEPENDS ${${COMPONENT_NAME}_DEPS}
		PREFIX ${COMPONENT_BUILD_DIR}
		TMP_DIR ${COMPONENT_BUILD_DIR}/ep_tmp
		#STAMP_DIR ${OPENCMISS_ROOT}/build/cmake_ep_stamps
		STAMP_DIR ${COMPONENT_BUILD_DIR}/ep_stamps
		
		#--Download step--------------
        ${DOWNLOAD_CMDS}
        
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
	)
	
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
    
    if(${PARALLEL} STREQUAL TRUE OR ${PARALLEL})
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

# Gets the revison of a submodule
#
# See http://git-scm.com/docs/git-submodule#status
#
# STATUS_VAR: Variable name to store the submodule status flag (-,+, ), see git-submodule
# REV_VAR: Variable name to store the revision
# REPO_DIR: Repo directory that contains the submodule
# MODULE_PATH: Path to the submodule relative to REPO_DIR
#macro(GET_SUBMODULE_STATUS STATUS_VAR REV_VAR REPO_DIR MODULE_PATH)
#    
#    execute_process(COMMAND ${GIT_COMMAND} submodule status ${MODULE_PATH}
#        RESULT_VARIABLE RES_VAR
#        OUTPUT_VARIABLE RES
#        ERROR_VARIABLE RES_ERR
#        WORKING_DIRECTORY ${REPO_DIR}
#        OUTPUT_STRIP_TRAILING_WHITESPACE)
#    if(NOT RES_VAR EQUAL 0)
#        message(FATAL_ERROR "Process returned nonzero result: ${RES_VAR}. Additional error: ${RES_ERR}")
#    endif()
#    string(SUBSTRING ${RES} 0 1 ${STATUS_VAR})
#    string(SUBSTRING ${RES} 1 40 ${REV_VAR})
#    unset(RES_VAR)
#    unset(RES)
#    unset(RES_ERR)
#    unset(_cmd)
#endmacro()

# Recursively updates a submodule and switches to a specified branch, if given. 
#macro(OCM_DEVELOPER_SUBMODULE_UPDATE REPO_ROOT MODULE_PATH BRANCH)
#    message(STATUS "Updating git submodule ${MODULE_PATH}..")
#    execute_process(COMMAND ${GIT_COMMAND} submodule update --init --recursive ${MODULE_PATH}
#        RESULT_VARIABLE RETCODE
#        ERROR_VARIABLE UPDATE_CMD_ERR
#        WORKING_DIRECTORY ${REPO_ROOT})
#    if (NOT RETCODE EQUAL 0)
#        message(FATAL_ERROR "Error updating submodule '${MODULE_PATH}' (code: ${RETCODE}): ${UPDATE_CMD_ERR}")
#    endif()
#    if (BRANCH)
       # Check out opencmiss branch
#       execute_process(COMMAND ${GIT_COMMAND} checkout ${BRANCH}
#           WORKING_DIRECTORY ${REPO_ROOT}/${MODULE_PATH}
#           RESULT_VARIABLE RETCODE
#           ERROR_VARIABLE CHECKOUT_CMD_ERR
#       )
#       if (NOT RETCODE EQUAL 0)
#           message(FATAL_ERROR "Error checking out submodule '${MODULE_PATH}' (code: ${RETCODE}): ${CHECKOUT_CMD_ERR}")
#       endif()
#    endif()
#endmacro()

# Recursively inits a submodule and switches to a specified branch, if given. 
#macro(OCM_DEVELOPER_SUBMODULE_INIT REPO_ROOT MODULE_PATH)
#    message(STATUS "Initializing git submodule ${MODULE_PATH}..")
#    execute_process(COMMAND ${GIT_COMMAND} submodule init ${MODULE_PATH}
#        RESULT_VARIABLE RETCODE
#        ERROR_VARIABLE UPDATE_CMD_ERR
#        WORKING_DIRECTORY ${REPO_ROOT})
#    if (NOT RETCODE EQUAL 0)
#        message(FATAL_ERROR "Error initializing submodule '${MODULE_PATH}' (code: ${RETCODE}): ${UPDATE_CMD_ERR}")
#    endif()
#endmacro()

# Adds extra steps to the external projects for submodule updates and checkout.
macro(ADD_SUBMODULE_CHECKOUT_STEPS PROJECT REPO_ROOT MODULE_PATH BRANCH) 
    ExternalProject_Add_Step(${PROJECT} gitinit
	        COMMAND ${GIT_COMMAND} submodule update ${MODULE_PATH} #-i --recursive not needed anymore as src/XXX is final depth
	        COMMENT "Initializing git submodule ${MODULE_PATH}.."
	        DEPENDERS configure
	        WORKING_DIRECTORY ${REPO_ROOT})
	if (BRANCH)
     	ExternalProject_Add_Step(${PROJECT} gitcheckout
     	        COMMAND ${GIT_COMMAND} checkout ${BRANCH}
    	        COMMENT "Checking out branch ${BRANCH} of ${MODULE_PATH}.."
     	        DEPENDEES gitinit
    	        DEPENDERS configure
     	        WORKING_DIRECTORY ${REPO_ROOT}/${MODULE_PATH}
    	)
	endif()
endmacro()