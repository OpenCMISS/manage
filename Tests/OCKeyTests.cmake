##
# In order to verify the overall functionality of an OpenCMISS build, we use *key tests*
# to quickly check core functionality *every time after build and installation*.
#
# The key tests are a selected set of OpenCMISS examples from the GitHub `OpenCMISS-Examples`_ organisation,
# which are build along with the main components and added as CTest test cases. 
#
# Depending on the effective configuration, a suitable selection of the following examples is build and run:
#
#    Classical field - Fortran
#        This key test is build whenever Iron is build. See :var:`OC_USE_<COMP>`.
#
#    Classical field - C
#        This example is only build when the C bindings for Iron are build.
#        See the :ref:`IRON_WITH_C_BINDINGS <intercomponent>` variable.
#
#    Finite elasticity cantilever - Fortran
#        This key test is build whenever Iron is build. See :var:`OC_USE_<COMP>`.
#
#    Bioelectrics Monodomain - Fortran
#        This key test is build whenever
#
#            * Iron and CellML are build, see :var:`OC_USE_<COMP>`.
#            * Iron with CellML is enabled, see :ref:`IRON_WITH_CELLML <intercomponent>`.
#
#    Classical field static advection diffusion with FieldML - Fortran
#        This key test is build whenever
#
#            * Iron and FieldML-API are build, see :var:`OC_USE_<COMP>`.
#            * Iron with FieldML is enabled, see :ref:`IRON_WITH_FIELDML <intercomponent>`.
#
# See also: :ref:`build targets`.
#
# .. _`OpenCMISS-Examples`: https://www.github.com/OpenCMISS-Examples
#

# Prefix for any tests that belongs to the OpenCMISS key tests
set(KEY_TEST_PREFIX OpenCMISS_KeyTest)

if (NOT OC_DEPENDENCIES_ONLY)
    # Iron-related key tests
    if (OC_USE_IRON)
        set(KEY_TESTS_IRON 
            ClassicalField_Laplace
            ClassicalField_AnalyticLaplace
            ClassicalField_AnalyticNonlinearPoisson
            FiniteElasticity_Cantilever
            LinearElasticity_Extension
        )
        if (OC_USE_CELLML AND IRON_WITH_CELLML)
            list(APPEND KEY_TESTS_IRON CellML_ModelIntegration)
        endif()
        if (OC_USE_FIELDML-API AND IRON_WITH_FIELDML)
            list(APPEND KEY_TESTS_IRON StaticAdvectionDiffusion_FieldML)
        endif()
        if (IRON_WITH_C_BINDINGS)
            list(APPEND KEY_TESTS_IRON C_Bindings_ComplexMesh)
        endif()
        if (IRON_WITH_Python_BINDINGS)
            list(APPEND KEY_TESTS_IRON Python_Bindings_Import Python_Bindings_Cantilever)
        endif()
        
        # Add all the key tests as local test
        foreach(_TEST ${KEY_TESTS_IRON})
            add_test(NAME ${KEY_TEST_PREFIX}_Iron_${_TEST}
                COMMAND ${CMAKE_CTEST_COMMAND} -R "^${_TEST}\$" --output-on-failure -C $<CONFIG>
                WORKING_DIRECTORY "${IRON_BINARY_DIR}"
            )
        endforeach()
    endif()
    
    # Zinc-related key tests
    if (OC_USE_ZINC)
        set(KEY_TESTS_ZINC "APITest_.*")
        
        if (ZINC_WITH_Python_BINDINGS)
            list(APPEND KEY_TESTS_ZINC 
                "Python_Bindings_.*"
            )
        endif()
        
        # Add all the key tests as local test
        foreach(_TEST ${KEY_TESTS_ZINC})
            add_test(NAME ${KEY_TEST_PREFIX}_Zinc_${_TEST}
                COMMAND ${CMAKE_CTEST_COMMAND} -R "^${_TEST}\$" --output-on-failure -C $<CONFIG>
                WORKING_DIRECTORY "${ZINC_BINARY_DIR}"
            )
        endforeach()
    endif()
endif()

# Add a top level target that runs only the key tests
add_custom_target(keytests
    COMMAND ${CMAKE_CTEST_COMMAND} -R "^${KEY_TEST_PREFIX}*" -O ${OC_SUPPORT_DIR}/keytests.log --output-on-failure -C $<CONFIG>
    COMMENT "Running OpenCMISS key tests"
)
