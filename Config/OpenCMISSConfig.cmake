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
SET(OC_DEVELOPER_CONFIG ${CMAKE_CURRENT_LIST_DIR}/../OpenCMISSDeveloper.cmake)
set(OC_DEVELOPER NO)
if (EXISTS ${OC_DEVELOPER_CONFIG})
    get_filename_component(OC_DEVELOPER_CONFIG ${OC_DEVELOPER_CONFIG} ABSOLUTE)
    message(STATUS "Applying OpenCMISS developer configuration at ${OC_DEVELOPER_CONFIG}...")
    include(${OC_DEVELOPER_CONFIG})
    set(OC_DEVELOPER YES)
    unset(OC_DEVELOPER_CONFIG)
endif()

# Postprocessing
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    # Set default version number branch unless e.g. IRON_BRANCH is specified
    if(NOT ${COMPONENT}_BRANCH)
        set(${COMPONENT}_BRANCH "v${${COMPONENT}_VERSION}")
    endif()
    
    # Force mandatory ones to be switched on
    if (${COMPONENT} IN_LIST OC_MANDATORY_COMPONENTS)
        set(OC_USE_${COMPONENT} REQ)
    endif()
    
    # All local enabled? Set to local search.
    if (OC_COMPONENTS_SYSTEM STREQUAL NONE)
        set(OC_SYSTEM_${COMPONENT} NO)
    elseif(OC_COMPONENTS_SYSTEM STREQUAL ALL)
        set(OC_SYSTEM_${COMPONENT} YES)
    endif()
    # Force "devel" branches for each component of DEVEL_ALL is set
    if (OC_DEVEL_ALL)
        SET(${COMPONENT}_BRANCH devel)
    endif()
    # Set all individual components build types to shared if the global BUILD_SHARED_LIBS is set
    if (BUILD_SHARED_LIBS)
        set(${COMPONENT}_SHARED ON)
    endif()
    if (NOT COMPONENT STREQUAL MPI) # Dont show that for MPI - have different implementations
    	string(SUBSTRING "${COMPONENT}                  " 0 12 COMPONENT_FIXED_SIZE)
    	string(SUBSTRING "${OC_USE_${COMPONENT}}       " 0 3 OC_USE_FIXED_SIZE)
    	string(SUBSTRING "${OC_SYSTEM_${COMPONENT}}    " 0 3 OC_SYSTEM_FIXED_SIZE)
    	string(SUBSTRING "${${COMPONENT}_VERSION}       " 0 7 OC_VERSION_FIXED_SIZE)
    	string(SUBSTRING "${${COMPONENT}_SHARED}        " 0 3 OC_SHARED_FIXED_SIZE)
    	# ${COMPONENT}_BRANCH is as good as version (this is what is effectively checked out) and will also display "devel" correctly
        message(STATUS "OpenCMISS component ${COMPONENT_FIXED_SIZE}: Use ${OC_USE_FIXED_SIZE}, System search ${OC_SYSTEM_FIXED_SIZE}, Shared: ${OC_SHARED_FIXED_SIZE}, Version '${OC_VERSION_FIXED_SIZE}', Branch '${${COMPONENT}_BRANCH}')")
    endif()
endforeach()
if (OC_DEVEL_ALL)
    set(EXAMPLES_BRANCH devel)
endif()