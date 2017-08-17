##
# In order to verify the overall functionality of an OpenCMISS build, we use *key tests*
# to quickly check core functionality *every time after build and installation*.
#
# The key tests are a selected set of tests available from the OpenCMISS main libaries
# and some dependencies. 
#
# Depending on the effective configuration and component selection, a suitable selection of the following examples is built and run:
#
#    :Iron-Fortran: Run whenever Iron is built. See :var:`OC_USE_IRON`.
#
#      - ClassicalField_Laplace
#      - ClassicalField_AnalyticLaplace
#      - ClassicalField_AnalyticNonlinearPoisson
#      - FiniteElasticity_Cantilever
#      - LinearElasticity_Extension
#
#    :Iron-C: Run when the C bindings for Iron are built.
#      See the :ref:`IRON_WITH_C_BINDINGS <intercomponent>` variable.
#    
#      - C_Bindings_ComplexMesh
#
#    :Iron-Python: Run when the Python bindings for Iron are built.
#      See the :ref:`IRON_WITH_Python_BINDINGS <intercomponent>` variable.
#  
#      - Python_Bindings_Import
#      - Python_Bindings_Cantilever
#
#    :Iron-CellML: Tests CellML models through Iron. Built when
#      Iron and CellML are built, see :var:`OC_USE_<COMP>`.
#      Iron with CellML is enabled, see :ref:`IRON_WITH_CELLML <intercomponent>`.
#
#      - CellML Model Integration
#
#    :Iron-FieldML: Classical field static advection diffusion with FieldML. Run when
#      Iron and FieldML-API are built, see :var:`OC_USE_<COMP>`.
#      Iron with FieldML is enabled, see :ref:`IRON_WITH_FIELDML <intercomponent>`.
#
#      - StaticAdvectionDiffusion_FieldML
#
#    :Zinc-API: Run whenever Zinc is built, see :var:`OC_USE_ZINC`.
#
#      - APITest_*
#
#    :Zinc-Python: Run whenever Python bindings for Zinc are built.
#      See the :ref:`ZINC_WITH_Python_BINDINGS <intercomponent>` variable.
#
#      - Python_Bindings_*
#
# See also: :ref:`build targets`.
#
# .. _`OpenCMISS-Examples`: https://www.github.com/OpenCMISS-Examples
#

# Prefix for any tests that belongs to the OpenCMISS key tests
set(KEY_TEST_PREFIX OpenCMISS_KeyTest)
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
    if (OC_USE_FIELDML-API AND IRON_WITH_FIELDML-API)
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

# Add a top level target that runs only the key tests
add_custom_target(keytests
    COMMAND ${CMAKE_CTEST_COMMAND} -R "^${KEY_TEST_PREFIX}*" -O ${OPENCMISS_SUPPORT_DIR}/keytests.log --output-on-failure -C $<CONFIG>
    COMMENT "Running OpenCMISS key tests"
)
