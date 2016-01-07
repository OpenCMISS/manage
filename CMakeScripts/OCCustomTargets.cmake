# update: Updates the whole source tree
# reset: Blows away the current build and installation trees

# This makes sure the install and featuretests targets are build when invoking "make"
add_custom_target(finish_build ALL)
add_custom_command(TARGET finish_build
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target install
    COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target featuretests
)

# Create a download target that depends on all other downloads
set(_OC_SOURCE_UPDATE_TARGETS )
set(_OC_COLLECT_LOG_TARGETS )
set(_OC_SOURCE_GITSTATUS_TARGETS )
foreach(_COMP ${_OC_SELECTED_COMPONENTS})
    string(TOLOWER "${_COMP}" _COMP_LOWER)
    list(APPEND _OC_SOURCE_UPDATE_TARGETS ${_COMP_LOWER}-update)
    list(APPEND _OC_SOURCE_GITSTATUS_TARGETS ${_COMP_LOWER}-gitstatus)
    list(APPEND _OC_COLLECT_LOG_TARGETS _${_COMP}-collectlogs)
endforeach()
add_custom_target(update
    DEPENDS ${_OC_SOURCE_UPDATE_TARGETS}
)
if (GIT_FOUND)
    add_custom_target(gitstatus
        DEPENDS ${_OC_SOURCE_GITSTATUS_TARGETS}
    )
endif()
add_custom_target(reset
    DEPENDS reset_mpionly reset_featuretests
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_BINARY_DIR}"
    COMMAND ${CMAKE_COMMAND} -E remove "${OC_BUILDLOG}"
    COMMAND ${CMAKE_COMMAND} -E copy ${OPENCMISS_LOCALCONFIG} ../backup_localconfig.tmp
    COMMAND ${CMAKE_COMMAND} -E remove -f ${PROJECT_BINARY_DIR}/*
    COMMAND ${CMAKE_COMMAND} -E copy ../backup_localconfig.tmp ${OPENCMISS_LOCALCONFIG}
    COMMAND ${CMAKE_COMMAND} -E remove -f ../backup_localconfig.tmp
    COMMENT "Removing directories:
        ->${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}
        ->${OPENCMISS_COMPONENTS_BINARY_DIR}"
)
add_custom_target(reset_mpionly
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}"
    COMMENT "Removing directories:
        ->${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}
        ->${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}"
)
add_custom_target(utter_destruction
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_ROOT}/build"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${OPENCMISS_ROOT}/install"
    COMMAND ${CMAKE_COMMAND} -E copy ${OPENCMISS_LOCALCONFIG} ../backup_localconfig.tmp
    COMMAND ${CMAKE_COMMAND} -E remove -f ${PROJECT_BINARY_DIR}/*
    COMMAND ${CMAKE_COMMAND} -E copy ../backup_localconfig.tmp ${OPENCMISS_LOCALCONFIG}
    COMMAND ${CMAKE_COMMAND} -E remove -f ../backup_localconfig.tmp
    COMMENT "BAM! Deleting build & install folders. Only keeping OpenCMISSLocalConfig"
)