# This file adds test cases that could well be considered "manage" unit tests!

if (EXISTS "${OPENCMISS_ROOT}")
    set(TEST_EXAMPLES_BINARY_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/example_tests)
    set(TEST_EXAMPLES_SRC_DIR ${OPENCMISS_ROOT}/src/example_tests)
    set(OPENCMISS_TEST_INSTALL_ROOT ${OPENCMISS_INSTALL_ROOT})
else ()
    set(TEST_EXAMPLES_BINARY_DIR ${OPENCMISS_LIBRARIES_BINARY_DIR_MPI}/example_tests)
    set(TEST_EXAMPLES_SRC_DIR ${OPENCMISS_LIBRARIES_ROOT}/src/example_tests)
    set(OPENCMISS_TEST_INSTALL_ROOT ${OPENCMISS_LIBRARIES_ROOT}/install)
endif ()

set(GITHUB_ORGANIZATION OpenCMISS-Examples)
set(OC_TEST_EXAMPLES classicalfield_laplace_simple)

set(_FT_EX_EP )
foreach(example_name ${OC_TEST_EXAMPLES})
    #list(APPEND _FT_EX_EP "${OC_EP_PREFIX}${example_name}")
    #list(APPEND _KEYTESTS_UPDATE_TARGETS "${example_name}-update")
    set(BIN_DIR "${TEST_EXAMPLES_BINARY_DIR}/${example_name}")
    set(SRC_DIR "${TEST_EXAMPLES_SRC_DIR}/${example_name}")
    set(INSTALL_DIR ${BIN_DIR}/install)
    # Set correct paths
    set(DEFS 
        -DOPENCMISS_INSTALL_DIR=${OPENCMISS_TEST_INSTALL_ROOT}
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
        -DMPI=${MPI}
    )
    # Instead of passing the (mpi-)compilers, we should imitate
    # the behaviour thats in place for anyone building an example
    # - they only use TOOLCHAIN and MPI mnemonics
    if (TOOLCHAIN)
        list(APPEND DEFS -DTOOLCHAIN=${TOOLCHAIN})
    endif()
    
    set(${example_name}_BRANCH ${OC_KEYTESTS_BRANCH})
    createExternalProjects(${example_name} "${SRC_DIR}" "${BIN_DIR}" "${DEFS}")

    # Dont build with the main build, as installation of OpenCMISS has not been done by then.
    set_target_properties(${OC_EP_PREFIX}${example_name} PROPERTIES EXCLUDE_FROM_ALL YES)
    
#    file(WRITE "${BIN_DIR}/runtest.cmake"
#    "
        # Build the example
#        execute_process(
#            COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG> --target ${OC_EP_PREFIX}${example_name}
#            RESULT_VARIABLE RES 
#            WORKING_DIRECTORY \"${OpenCMISS_BINARY_DIR}\" 
#        )
        # Run the internal example tests
#        execute_process(
#            COMMAND ${CMAKE_CTEST_COMMAND} -C $<CONFIG>
#            RESULT_VARIABLE RES
#            WORKING_DIRECTORY \"${BIN_DIR}\" 
#        )
#    "
#    )
#    add_test(NAME Example_${example_name}
#        COMMAND ${CMAKE_COMMAND} -P "${BIN_DIR}/runtest.cmake"
#    )
     add_test(NAME Example_${example_name}
        COMMAND ${CMAKE_CTEST_COMMAND} -C $<CONFIG>
        WORKING_DIRECTORY \"${BIN_DIR}\" 
     )
endforeach()
