# This file adds examples that can be used for testing!

if (OPENCMISS_EXAMPLES_SOURCE_DIR)

    set(OC_TEST_EXAMPLES classicalfield_laplace_simple)

    set(_FT_EX_EP )
    foreach(example_name ${OC_TEST_EXAMPLES})
        set(BIN_DIR "${OPENCMISS_EXAMPLES_BINARY_MPI_DIR}/${example_name}")
        set(SRC_DIR "${OPENCMISS_EXAMPLES_SOURCE_DIR}/${example_name}")
        set(INSTALL_DIR ${OPENCMISS_EXAMPLES_INSTALL_MPI_PREFIX})
        # Set correct paths
        set(DEFS
            -DOPENCMISSLIBS_DIR=${OPENCMISS_LIBRARIES_INSTALL_MPI_PREFIX}
            -DCMAKE_INSTALL_PREFIX=${OPENCMISS_EXAMPLES_INSTALL_MPI_PREFIX}
            -DOPENCMISS_MPI=${OPENCMISS_MPI}
        )
        # Instead of passing the (mpi-)compilers, we should imitate
        # the behaviour thats in place for anyone building an example
        # - they only use TOOLCHAIN and MPI mnemonics
        if (OPENCMISS_TOOLCHAIN)
            list(APPEND DEFS -DOPENCMISS_TOOLCHAIN=${OPENCMISS_TOOLCHAIN})
        endif()

        set(${example_name}_BRANCH ${OC_EXAMPLES_BRANCH})
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

         list(APPEND example_targets ${OC_EP_PREFIX}${example_name})
    endforeach()

    add_custom_target(build_examples
        DEPENDS ${example_targets})

else ()
    message(STATUS "No examples source directory set ==> no examples will be available through this framework.")
endif ()

