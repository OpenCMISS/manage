# Load default configuration
include(OpenCMISSDefaultConfig)
include(OpenCMISSComponentConfig)

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
