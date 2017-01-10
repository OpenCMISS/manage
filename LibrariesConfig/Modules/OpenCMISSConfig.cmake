# Load default configuration
include(OpenCMISSDefaultConfig)
# This file is separate for documentation structural reasons (sphinx / rst)
include(OpenCMISSInterComponentConfig)

# Half hack: The CMAKE_BUILD_TYPE variable is not initialized in the cache if it's "only" set
# as a variable via cmake script. Consequently, issuing a project() command looks in the cache
# and finds an uninitialized CMAKE_BUILD_TYPE and uses that, ignoring any set value in LocalConfig/DevelConfig.
# As the DIRECT_VARS setting also inserts lines into the localconfig file, the build parameterization also
# wont work.
# A possible "workaround" would be to pass those variables via command line, which would add them to the cache and done.
# However, as all the other variables are defined in the localconfig file, it would seem (especially with the build type)
# unintuitive to have to define the build type differently. Hence, this solution simply sets the assigned value of 
# CMAKE_BUILD_TYPE also in the cache.
# If there appear other variables that require the same behaviour, one should consider alternative solutions to this.
#set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "The build type for OpenCMISS" FORCE)

######################################################################
# Postprocessing

# Include the installation configuration
include(${OPENCMISS_INSTALLATION_CACHE_FILE})

# Load local configuration to allow overrides
# First try at a given path, then local
set(_CONFIG_FOUND NO)
if (OPENCMISS_CONFIG_DIR)
    set(_LOCAL_CONFIG ${OPENCMISS_CONFIG_DIR}/OpenCMISSLocalConfig.cmake)
    if (EXISTS ${_LOCAL_CONFIG})
        message(STATUS "Applying OpenCMISS local configuration at ${_LOCAL_CONFIG}...")
        include(${_LOCAL_CONFIG})
        set(_CONFIG_FOUND YES)   
    endif ()
endif ()
set(_LC_CDIR ${_LOCAL_CONFIG})
set(_LOCAL_CONFIG ${OPENCMISS_LOCAL_CONFIG})
if (EXISTS ${_LOCAL_CONFIG} AND NOT _LC_CDIR STREQUAL _LOCAL_CONFIG)
    message(STATUS "Applying OpenCMISS local configuration at ${_LOCAL_CONFIG}...")
    include(${_LOCAL_CONFIG})
    set(_CONFIG_FOUND YES)   
endif ()
if (NOT _CONFIG_FOUND)
    message(STATUS "No local OpenCMISS configuration file present.")
endif()
unset(_LC_CDIR)
unset(_CONFIG_FOUND)

# Add HDF5 to fortran projects if enabled
if (HDF5_BUILD_FORTRAN)
  list(APPEND OPENCMISS_COMPONENTS_WITH_Fortran HDF5)
  list(APPEND OPENCMISS_COMPONENTS_WITH_F90 HDF5)
endif ()

# Disable iron/zinc if only dependencies should be built
if (OC_DEPENDENCIES_ONLY)
    set(OC_USE_IRON OFF)
    set(OC_USE_ZINC OFF)
endif ()
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    
    # Force mandatory ones to be switched on
    if (${COMPONENT} IN_LIST OC_MANDATORY_COMPONENTS)
        set(OC_USE_${COMPONENT} REQ)
    endif ()
    
    # All local enabled? Set to local search.
    if (OC_COMPONENTS_SYSTEM STREQUAL NONE)
        set(OC_SYSTEM_${COMPONENT} OFF)
    elseif (OC_COMPONENTS_SYSTEM STREQUAL ALL)
        set(OC_SYSTEM_${COMPONENT} ON)
    endif ()
    # Set "devel" branches for each component if DEVEL_ALL is set,
    # but don't override any specified component branches.
    if (OPENCMISS_DEVEL_ALL AND NOT ${COMPONENT}_BRANCH)
        set(${COMPONENT}_BRANCH devel)
    elseif (NOT ${COMPONENT}_BRANCH)
        # Set default version number branch unless e.g. IRON_BRANCH is specified
        set(${COMPONENT}_BRANCH "v${${COMPONENT}_VERSION}")
    endif ()
    # Set all individual components build types to shared if the global BUILD_SHARED_LIBS is set
    if (BUILD_SHARED_LIBS)
        set(${COMPONENT}_SHARED ON)
    endif ()    
    if (NOT COMPONENT STREQUAL MPI) # Dont show that for MPI - have different implementations
        string(SUBSTRING "${COMPONENT}                  " 0 12 COMPONENT_FIXED_SIZE)
        string(SUBSTRING "${OC_USE_${COMPONENT}}       " 0 3 OC_USE_FIXED_SIZE)
        string(SUBSTRING "${OC_SYSTEM_${COMPONENT}}    " 0 3 OC_SYSTEM_FIXED_SIZE)
        string(SUBSTRING "${${COMPONENT}_VERSION}       " 0 7 OC_VERSION_FIXED_SIZE)
        string(SUBSTRING "${${COMPONENT}_SHARED}        " 0 3 OC_SHARED_FIXED_SIZE)
        # ${COMPONENT}_BRANCH is as good as version (this is what is effectively checked out) and will also display "devel" correctly
        message(STATUS "OpenCMISS component ${COMPONENT_FIXED_SIZE}: Use ${OC_USE_FIXED_SIZE}, System search ${OC_SYSTEM_FIXED_SIZE}, Shared: ${OC_SHARED_FIXED_SIZE}, Version '${OC_VERSION_FIXED_SIZE}', Branch '${${COMPONENT}_BRANCH}')")
    endif ()
endforeach()

if (OPENCMISS_DEVEL_ALL)
    set(EXAMPLES_BRANCH devel)
    set(OC_KEYTESTS_BRANCH devel)
else ()
    set(OC_KEYTESTS_BRANCH v${OpenCMISS_VERSION})
endif ()

# Include the installation configuration again to stop local changes from being effective
include(${OPENCMISS_INSTALLATION_CACHE_FILE})


