set(FEATURE_TEST_EXAMPLES 
    classicalfield_laplace_laplace_fortran
    finiteelasticity_cantilever_fortran
    bioelectrics_monodomain_fortran
)
set(BIN_DIR_ROOT ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/featuretests)
set(SRC_DIR_ROOT ${OPENCMISS_ROOT}/src/featuretests)
set(GITHUB_ORGANIZATION OpenCMISS-Examples)
foreach(example_name ${FEATURE_TEST_EXAMPLES})
    set(BIN_DIR "${BIN_DIR_ROOT}/${example_name}")
    set(SRC_DIR "${SRC_DIR_ROOT}/${example_name}")
    set(DEFS 
        -DOPENCMISS_INSTALL_DIR=${OPENCMISS_INSTALL_ROOT}
        -DCMAKE_INSTALL_PREFIX=${SRC_DIR}
    )
    set(${example_name}_BRANCH devel)
    createExternalProjects(${example_name} "${SRC_DIR}" "${BIN_DIR}" "${DEFS}")
    
    add_test(NAME feature_${example_name}
        COMMAND run
        WORKING_DIRECTORY ${SRC_DIR}     
    )
endforeach()
add_custom_target(featuretests
    COMMAND ${CMAKE_CTEST_COMMAND} feature_*
)