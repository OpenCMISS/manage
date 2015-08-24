# Get variables
include(Variables)

# Load default configuration
include(OpenCMISSDefaultConfig)

# Load local configuration to allow overrides
# First try at a given path, then local
SET(_CONFIG_FOUND NO)
if(OPENCMISS_CONFIG_DIR)
    SET(LOCALCONF ${OPENCMISS_CONFIG_DIR}/OpenCMISSLocalConfig.cmake)
    if(EXISTS ${LOCALCONF})
        message(STATUS "Applying OpenCMISS local configuration at ${LOCALCONF}...")
        include(${LOCALCONF})
        SET(_CONFIG_FOUND YES)   
    endif()
endif()
SET(_LC_CDIR ${LOCALCONF})
SET(LOCALCONF ${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
if(EXISTS ${LOCALCONF} AND NOT _LC_CDIR STREQUAL LOCALCONF)
    message(STATUS "Applying OpenCMISS local configuration at ${LOCALCONF}...")
    include(${LOCALCONF})
    SET(_CONFIG_FOUND YES)   
endif()
if (NOT _CONFIG_FOUND)
    message(STATUS "No local OpenCMISS configuration file present.")
endif()
unset(_LC_CDIR)
unset(_CONFIG_FOUND)

# Look for an OpenCMISS Developer script
SET(OCM_DEVELOPER_CONFIG ${CMAKE_CURRENT_LIST_DIR}/../OpenCMISSDeveloper.cmake)
if (EXISTS ${OCM_DEVELOPER_CONFIG})
    get_filename_component(OCM_DEVELOPER_CONFIG ${OCM_DEVELOPER_CONFIG} ABSOLUTE)
    message(STATUS "Applying OpenCMISS developer configuration at ${OCM_DEVELOPER_CONFIG}...")
    include(${OCM_DEVELOPER_CONFIG})
    unset(OCM_DEVELOPER_CONFIG)
endif()

# Postprocessing
foreach(OCM_COMP ${OPENCMISS_COMPONENTS})
    # Set default version number branch unless e.g. IRON_BRANCH is specified
    if(NOT ${OCM_COMP}_BRANCH)
        set(${OCM_COMP}_BRANCH "v${${OCM_COMP}_VERSION}")
    endif()
    
    # All local enabled? Set to local search.
    if (OCM_SYSTEM_ALL)
        SET(OCM_SYSTEM_${OCM_COMP} YES)
    endif()
    if (NOT OCM_COMP STREQUAL MPI) # Dont show that for MPI - have different implementations
    	string(SUBSTRING "${OCM_COMP}              " 0 12 OCM_COMP_FIXED_SIZE)
    	string(SUBSTRING "${OCM_USE_${OCM_COMP}}   " 0  3 OCM_USE_FIXED_SIZE)
    	string(SUBSTRING "${OCM_SYSTEM_${OCM_COMP}}    " 0  3 OCM_SYSTEM_FIXED_SIZE)
        message(STATUS "OpenCMISS component ${OCM_COMP_FIXED_SIZE}: Enabled ${OCM_USE_FIXED_SIZE}, System search ${OCM_SYSTEM_FIXED_SIZE}, Version '${${OCM_COMP}_VERSION}'")
    endif()
    
    # Force "devel" branches for each component of DEVEL_ALL is set
    if (OCM_DEVEL_ALL)
        SET(${OCM_COMP}_BRANCH devel)
    endif()
    # All git clone enabled?
    if (OCM_GIT_CLONE_ALL)
        SET(OCM_GIT_CLONE_${OCM_COMP} YES)
    endif()
endforeach()
if (OCM_DEVEL_ALL)
    set(EXAMPLES_BRANCH devel)
endif()
if (OCM_GIT_CLONE_ALL)
    set(OCM_GIT_CLONE_EXAMPLES YES)
endif()