if (OC_USE_IRON)
    set(OPENCMISS_EXAMPLES_SRC_DIR ${OPENCMISS_ROOT}/examples)
    getBuildTypePathElem(BUILDTYPEEXTRA)
    
    set(OPENCMISS_EXAMPLES_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/examples/${BUILDTYPEEXTRA})
    #set(OPENCMISS_EXAMPLES_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/examples/${ARCHITECTURE_PATH_MPI})
    
    set(GITHUB_ORGANIZATION OpenCMISS-Examples)
    if (NOT EXAMPLES_BRANCH)
        set(EXAMPLES_BRANCH "v${EXAMPLES_VERSION}")
    endif()
    
    createExternalProjects(EXAMPLES ${OPENCMISS_EXAMPLES_SRC_DIR} ${OPENCMISS_EXAMPLES_BUILD_DIR} "")
    # Dont build the examples with the normal main build!
    set_property(TARGET ${OC_EP_PREFIX}EXAMPLES PROPERTY EXCLUDE_FROM_ALL TRUE)
    
    # Add a test target to run
    if (BUILD_TESTS)
        add_custom_target(examples-test
            DEPENDS ${OC_EP_PREFIX}EXAMPLES
            COMMAND ${CMAKE_COMMAND} --build ${OPENCMISS_EXAMPLES_BUILD_DIR} --target test)
    endif()
endif()