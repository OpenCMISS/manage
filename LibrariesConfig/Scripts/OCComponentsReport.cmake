foreach(COMPONENT_NAME ${OC_REQUIRED_COMPONENTS})

    # Force mandatory ones to be switched on
    if (${COMPONENT_NAME} IN_LIST OPENCMISS_MANDATORY_COMPONENTS)
        set(_OC_USE REQ)
    else ()
        set(_OC_USE ${OC_USE_${COMPONENT_NAME}})
    endif ()

    # Compute directories
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME)
    if (COMPONENT_NAME STREQUAL "IRON" OR COMPONENT_NAME STREQUAL "ZINC")
        if (OPENCMISS_ZINC_SOURCE_DIR OR OPENCMISS_IRON_SOURCE_DIR)
            set(_COMPONENT_SOURCE_DIR "${OPENCMISS_${COMPONENT_NAME}_SOURCE_DIR}/${FOLDER_NAME}")
        else ()
            set(_COMPONENT_SOURCE_DIR "${OPENCMISS_LIBRARIES_SOURCE_DIR}/${FOLDER_NAME}")
        endif ()
    else ()
        set(_COMPONENT_SOURCE_DIR "${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${FOLDER_NAME}")
    endif ()
    # Get component branch from source..
    get_git_branch("${_COMPONENT_SOURCE_DIR}" ${COMPONENT_NAME}_BRANCH)
    unset(_COMPONENT_SOURCE_DIR)
    if (NOT COMPONENT_NAME STREQUAL MPI) # Dont show that for MPI - have different implementations
        string(SUBSTRING "${COMPONENT_NAME}                  " 0 12 COMPONENT_FIXED_SIZE)
        string(SUBSTRING "${_OC_USE}       " 0 3 OC_USE_FIXED_SIZE)
        string(SUBSTRING "${OC_SYSTEM_${COMPONENT_NAME}}    " 0 3 OC_SYSTEM_FIXED_SIZE)
        # string(SUBSTRING "${${COMPONENT_NAME}_VERSION}       " 0 7 OC_VERSION_FIXED_SIZE) now using the branch from the git repository only
        string(SUBSTRING "${${COMPONENT_NAME}_SHARED}        " 0 3 OC_SHARED_FIXED_SIZE)
        # ${COMPONENT_NAME}_BRANCH is as good as version (this is what is effectively checked out) and will also display "develop" correctly
        message(STATUS "OpenCMISS component ${COMPONENT_FIXED_SIZE}: Use ${OC_USE_FIXED_SIZE}, System search ${OC_SYSTEM_FIXED_SIZE}, Shared: ${OC_SHARED_FIXED_SIZE}, Branch '${${COMPONENT_NAME}_BRANCH}')")
    endif ()
endforeach()

