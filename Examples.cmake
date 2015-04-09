set(OPENCMISS_EXAMPLES_SRC_DIR ${OPENCMISS_ROOT}/examples)
set(OPENCMISS_EXAMPLES_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/examples)
set(OPENCMISS_EXAMPLES_INSTALL_PREFIX ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/examples)
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
        SET(EXAMPLES_REPO https://github.com/OpenCMISS/examples)
    endif()
    ################@TEMP@#################
    SET(DOWNLOAD_CMDS
        DOWNLOAD_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}/src-download
        #URL https://github.com/${GITHUB_ORGANIZATION}/${FOLDER_NAME}/archive/${${COMPONENT_NAME}_BRANCH}.zip
        ################@TEMP@#################
        URL ${EXAMPLES_REPO}/archive/${EXAMPLES_BRANCH}.zip
        ################@TEMP@#################
    )
endif()
message(STATUS "Configuring build of OpenCMISS-Examples ('examples' target) at ${OPENCMISS_EXAMPLES_BUILD_DIR}")
ExternalProject_Add(examples
    #DEPENDS IRON
    ${DOWNLOAD_CMDS}
    PREFIX ${OPENCMISS_EXAMPLES_BUILD_DIR}
    SOURCE_DIR ${OPENCMISS_EXAMPLES_SRC_DIR}
    BINARY_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}
    CMAKE_ARGS -DOPENCMISS_INSTALL_DIR=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}
)
# We dont want to build the examples project by default - you got to trigger it.
set_target_properties(examples PROPERTIES EXCLUDE_FROM_ALL TRUE)