set(FEATURE_TEST_EXAMPLES 
    classicalfield_laplace_laplace_fortran
    finiteelasticity_cantilever_fortran
)
if (IRON_WITH_C_BINDINGS)
    list(APPEND FEATURE_TEST_EXAMPLES classicalfield_laplace_laplace_c)
endif()
if (OCM_USE_CELLML AND IRON_WITH_CELLML)
    list(APPEND FEATURE_TEST_EXAMPLES bioelectrics_monodomain_fortran)
endif()
# Collect any arguments
# n98.xml is the only currently working xml file
set(bioelectrics_monodomain_fortran_ARGS 0.005 0.1001 70 n98.xml)

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
        COMMAND run ${${example_name}_ARGS}
        WORKING_DIRECTORY ${SRC_DIR}     
    )
endforeach()
# Add a top level target that runs only the feature tests
add_custom_target(featuretests
    COMMAND ${CMAKE_CTEST_COMMAND} feature_*
    COMMENT "Running OpenCMISS feature tests"
)