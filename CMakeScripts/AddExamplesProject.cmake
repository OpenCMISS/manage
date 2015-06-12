set(OPENCMISS_EXAMPLES_SRC_DIR ${OPENCMISS_ROOT}/examples)
set(OPENCMISS_EXAMPLES_BUILD_DIR ${OPENCMISS_ROOT}/build/examples/${ARCHITECTURE_PATH_MPI})
set(OPENCMISS_EXAMPLES_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/examples/${ARCHITECTURE_PATH_MPI})
set(EXAMPLES_BRANCH cmake)

# git repo or zip!
if (OCM_DEVEL_EXAMPLES)
    find_package(Git)
    if(GIT_FOUND)
        if (NOT EXAMPLES_REPO)
            if(GITHUB_USERNAME)
                SET(_GITHUB_USERNAME ${GITHUB_USERNAME})
            else()
                SET(_GITHUB_USERNAME OpenCMISS)
            endif()
            if (GITHUB_USE_SSL)
                SET(GITHUB_PROTOCOL "git@github.com:")
            else()
                SET(GITHUB_PROTOCOL "https://github.com/")
            endif()
            set(EXAMPLES_REPO ${GITHUB_PROTOCOL}${_GITHUB_USERNAME}/examples)
        endif()
        SET(DOWNLOAD_CMDS
            GIT_REPOSITORY ${EXAMPLES_REPO}
            GIT_TAG ${EXAMPLES_BRANCH}
        )
        #message(STATUS "DOWNLOAD_CMDS=${DOWNLOAD_CMDS}")
    else()
        message(FATAL_ERROR "Could not find GIT. GIT is required for development mode of component ${COMPONENT_NAME}")
    endif()

else()
    ################@TEMP@#################
    # Temporary fix to also adhere to "custom" repository locations when in user mode.
    # Should be removed in final version.
    if (NOT EXAMPLES_REPO)
        SET(EXAMPLES_REPO https://github.com/rondiplomatico/examples)
    endif()
    ################@TEMP@#################
    SET(DOWNLOAD_CMDS
        DOWNLOAD_DIR ${OPENCMISS_ROOT}/src/download
        #URL https://github.com/${GITHUB_ORGANIZATION}/${FOLDER_NAME}/archive/${${COMPONENT_NAME}_BRANCH}.zip
        DOWNLOAD_NO_PROGRESS 1
        URL ${EXAMPLES_REPO}/archive/${EXAMPLES_BRANCH}.zip
    )
endif()
message(STATUS "Configuring build of OpenCMISS-Examples ('examples' target) at ${OPENCMISS_EXAMPLES_BUILD_DIR}")
ExternalProject_Add(examples-download
    PREFIX ${OPENCMISS_EXAMPLES_SRC_DIR}
    TMP_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}/ep_tmp
    STAMP_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}/ep_stamps
    EXCLUDE_FROM_ALL 1
    ${DOWNLOAD_CMDS}
    SOURCE_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
ExternalProject_Add(examples-build
    DEPENDS examples-download
    PREFIX ${OPENCMISS_EXAMPLES_BUILD_DIR}
    TMP_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}/ep_tmp
    STAMP_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}/ep_stamps
    EXCLUDE_FROM_ALL 1
    SOURCE_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}
    BINARY_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}
    CMAKE_ARGS 
        -DOPENCMISS_INSTALL_DIR=${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}
)
add_custom_target(examples
    DEPENDS examples-download examples-build
    EXCLUDE_FROM_ALL 1
)
# We dont want to build the examples by default - you got to trigger it.
#set_target_properties(examples-build examples-download PROPERTIES EXCLUDE_FROM_ALL TRUE)
