# Generate the wrappers (if not existing)
SET(WRAPPER_DIR ${OPENCMISS_SETUP_DIR}/CMakeFindModuleWrappers)
foreach(PACKAGE_NAME ${PACKAGES_WITH_TARGETS})
    SET(FILE ${WRAPPER_DIR}/Find${PACKAGE_NAME}.cmake)
    #if(NOT EXISTS ${FILE})
        SET(PACKAGE_TARGETS ${${PACKAGE_NAME}_TARGETS})
        configure_file(${WRAPPER_DIR}/FindXXX.in.cmake ${FILE} @ONLY)
    #endif()
endforeach()

set(SUBGROUP_PATH utilities)
set(GITHUB_ORGANIZATION OpenCMISS-Utilities)

if(OCM_USE_MPI)
    # todo check for mpi and build if not found
endif()

# ... gtest, mpi, ..
