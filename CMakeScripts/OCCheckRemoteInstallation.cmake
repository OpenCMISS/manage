# Read OPENCMISS_REMOTE_INSTALL_DIR from environment if not specified directly
if (NOT OPENCMISS_REMOTE_INSTALL_DIR AND EXISTS "$ENV{OPENCMISS_REMOTE_INSTALL_DIR}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_REMOTE_INSTALL_DIR}" OPENCMISS_REMOTE_INSTALL_DIR)
endif()

# Wrap the inclusion of the remote context into a function to protect the local scope
function(get_remote_prefix_path DIR RESULT_VAR)
    get_filename_component(DIR ${DIR} ABSOLUTE)
    if (EXISTS ${DIR}/context.cmake)
        include(${DIR}/context.cmake)
        set(${RESULT_VAR} ${OPENCMISS_PREFIX_PATH_EXPORT} PARENT_SCOPE)
    endif()
endfunction()

##############
# Compile remote directory
set(OPENCMISS_REMOTE_INSTALL_DIR_ARCH )
# In case we are provided with a direct install directory, use that and let the user make sure the installations are compatible
if (OPENCMISS_REMOTE_INSTALL_DIR_FORCE)
    get_filename_component(OPENCMISS_REMOTE_INSTALL_DIR_FORCE "${OPENCMISS_REMOTE_INSTALL_DIR_FORCE}" ABSOLUTE)
    set(OPENCMISS_REMOTE_INSTALL_DIR_ARCH "${OPENCMISS_REMOTE_INSTALL_DIR_FORCE}")
    if (NOT EXISTS "${OPENCMISS_REMOTE_INSTALL_DIR_FORCE}")
        message(FATAL_ERROR "Invalid OPENCMISS_REMOTE_INSTALL_DIR_FORCE directory: ${OPENCMISS_REMOTE_INSTALL_DIR_FORCE}")
    endif()
# In case we are provided with a remote root directory, we are creating the same sub-path as we are locally using
# to import the matching libraries
elseif(OPENCMISS_REMOTE_INSTALL_DIR)
    get_filename_component(OPENCMISS_REMOTE_INSTALL_DIR "${OPENCMISS_REMOTE_INSTALL_DIR}" ABSOLUTE)    
    if (EXISTS "${OPENCMISS_REMOTE_INSTALL_DIR}")
        # The remote installations always have to use an architecture path, and we're compiling our local
        # one to make sure a compatible architecture and configuration has been chosen.
        getArchitecturePath(_UNUSED ARCHITECTURE_PATH_MPI)
    
        set(ARCH_SUBPATH ${ARCHITECTURE_PATH_MPI}/${BUILDTYPEEXTRA})
        set(OPENCMISS_REMOTE_INSTALL_DIR_ARCH ${OPENCMISS_REMOTE_INSTALL_DIR}/${ARCH_SUBPATH})
    else()
        message(FATAL_ERROR "Invalid OPENCMISS_REMOTE_INSTALL_DIR directory: ${OPENCMISS_REMOTE_INSTALL_DIR}")
    endif()
endif()
##############
# Read remote configuration 
if (OPENCMISS_REMOTE_INSTALL_DIR_ARCH)
    # Need to wrap this into a function as a separate scope is needed in order to avoid overriding
    # local values by those set in the opencmiss context file.
    get_remote_prefix_path(${OPENCMISS_REMOTE_INSTALL_DIR_ARCH} REMOTE_PREFIX_PATH)
    if (REMOTE_PREFIX_PATH)
        message(STATUS "Using remote OpenCMISS component installation at ${OPENCMISS_REMOTE_INSTALL_DIR_ARCH}...")
        list(APPEND CMAKE_PREFIX_PATH ${REMOTE_PREFIX_PATH})
        list(APPEND OPENCMISS_PREFIX_PATH ${REMOTE_PREFIX_PATH})
        unset(REMOTE_PREFIX_PATH) 
    else()
        message(FATAL_ERROR "No matching remote OpenCMISS installation found for the current configuration subpath '${ARCH_SUBPATH}' under ${OPENCMISS_REMOTE_INSTALL_DIR}. Please check you local setup.")
    endif()
endif()

