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
        message(STATUS "Applying local OpenCMISS config file at ${LOCALCONF}...")
        include(${LOCALCONF})
        SET(_CONFIG_FOUND YES)   
    endif()
endif()
SET(_LC_CDIR ${LOCALCONF})
SET(LOCALCONF ${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSLocalConfig.cmake)
if(EXISTS ${LOCALCONF} AND NOT _LC_CDIR STREQUAL LOCALCONF)
    message(STATUS "Applying local OpenCMISS config file at ${LOCALCONF}...")
    include(${LOCALCONF})
    SET(_CONFIG_FOUND YES)   
endif()
if (NOT _CONFIG_FOUND)
    message(STATUS "No local OpenCMISS configuration file present.")
endif()
unset(_LC_CDIR)
unset(_CONFIG_FOUND)

# Postprocessing
foreach(OCM_COMP ${OPENCMISS_COMPONENTS})
    # Set default version number branch unless e.g. IRON_BRANCH is specified
    if(NOT ${OCM_COMP}_BRANCH)
        set(${OCM_COMP}_BRANCH "v${${OCM_COMP}_VERSION}")
    endif()
    # All local enabled? Set to local search.
    if (OCM_ALL_LOCAL)
        SET(OCM_${OCM_COMP}_LOCAL YES)
    endif()
    message(STATUS "OpenCMISS component ${OCM_COMP}: Enabled ${OCM_USE_${OCM_COMP}}, Local lookup ${OCM_${OCM_COMP}_LOCAL}, Branch '${${OCM_COMP}_BRANCH}'")
endforeach()