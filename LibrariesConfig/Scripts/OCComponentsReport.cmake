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
    # Set all individual components build types to shared if the global BUILD_SHARED_LIBS is set
    if (BUILD_SHARED_LIBS)
        set(${COMPONENT}_SHARED ON)
    endif ()
    # Compute directories
    string(TOLOWER ${COMPONENT} FOLDER_NAME)
    if (COMPONENT STREQUAL "IRON" OR COMPONENT STREQUAL "ZINC")
        set(COMPONENT_SOURCE_DIR "${OPENCMISS_LIBRARIES_SOURCE_DIR}/${FOLDER_NAME}")
    else ()
        set(COMPONENT_SOURCE_DIR "${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${FOLDER_NAME}")
    endif ()
    # Get component branch from source..
    get_git_branch("${COMPONENT_SOURCE_DIR}" ${COMPONENT}_BRANCH)
    if (NOT COMPONENT STREQUAL MPI) # Dont show that for MPI - have different implementations
        string(SUBSTRING "${COMPONENT}                  " 0 12 COMPONENT_FIXED_SIZE)
        string(SUBSTRING "${OC_USE_${COMPONENT}}       " 0 3 OC_USE_FIXED_SIZE)
        string(SUBSTRING "${OC_SYSTEM_${COMPONENT}}    " 0 3 OC_SYSTEM_FIXED_SIZE)
        # string(SUBSTRING "${${COMPONENT}_VERSION}       " 0 7 OC_VERSION_FIXED_SIZE) now using the branch from the git repository only
        string(SUBSTRING "${${COMPONENT}_SHARED}        " 0 3 OC_SHARED_FIXED_SIZE)
        # ${COMPONENT}_BRANCH is as good as version (this is what is effectively checked out) and will also display "develop" correctly
        message(STATUS "OpenCMISS component ${COMPONENT_FIXED_SIZE}: Use ${OC_USE_FIXED_SIZE}, System search ${OC_SYSTEM_FIXED_SIZE}, Shared: ${OC_SHARED_FIXED_SIZE}, Branch '${${COMPONENT}_BRANCH}')")
    endif ()
endforeach()

