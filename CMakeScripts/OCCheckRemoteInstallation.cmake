# Read OPENCMISS_INSTALL_DIR_REMOTE from environment if not specified directly
if (NOT OPENCMISS_INSTALL_DIR_REMOTE AND EXISTS "$ENV{OPENCMISS_INSTALL_DIR_REMOTE}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR_REMOTE}" OPENCMISS_INSTALL_DIR_REMOTE)
endif()

# Wrap the inclusion of the remote context into a function to protect the local scope
function(get_remote_prefix_path DIR RESULT_VAR)
    get_filename_component(DIR ${DIR} ABSOLUTE)
    if (EXISTS ${DIR}/context.cmake)
        include(${DIR}/context.cmake)
        set(${RESULT_VAR} ${OPENCMISS_PREFIX_PATH} PARENT_SCOPE)
    endif()
endfunction()

# In case we are provided with a remote root directory, we are creating the same sub-path as we are locally using
# to import the matching libraries
if (OPENCMISS_INSTALL_DIR_REMOTE)
    if (EXISTS "${OPENCMISS_INSTALL_DIR_REMOTE}")
        # The remote installations always have to use an architecture path.
        getArchitecturePath(_UNUSED ARCHITECTURE_PATH_MPI)
    
        set(CONFIG_PATH ${ARCHITECTURE_PATH_MPI}/${BUILDTYPEEXTRA})
        set(OPENCMISS_REMOTE_ARCHPATH ${OPENCMISS_INSTALL_DIR_REMOTE}/${CONFIG_PATH})
        
        # Need to wrap this into a function as a separate scope is needed in order to avoid overriding
        # local values by those set in the opencmiss context file.
        get_remote_prefix_path(${OPENCMISS_REMOTE_ARCHPATH} REMOTE_PREFIX_PATH)
        if (REMOTE_PREFIX_PATH)
            message(STATUS "Using remote OpenCMISS component installation at ${OPENCMISS_REMOTE_ARCHPATH}...")
            list(APPEND OPENCMISS_PREFIX_PATH ${REMOTE_PREFIX_PATH})
            unset(REMOTE_PREFIX_PATH) 
        else()
            message(WARNING "No matching remote OpenCMISS installation found for the current configuration subpath '${CONFIG_PATH}' under ${OPENCMISS_INSTALL_DIR_REMOTE}. Components will be searched/build locally.")
        endif()
    else()
        message(FATAL_ERROR "Invalid OPENCMISS_INSTALL_DIR_REMOTE directory: ${OPENCMISS_INSTALL_DIR_REMOTE}")
    endif()
endif()

