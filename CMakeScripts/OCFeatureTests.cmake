##
# In order to verify the overall functionality of an OpenCMISS build, we use *feature tests*
# to quickly check core functionality *every time after build and installation*.
#
# The feature tests are a selected set of OpenCMISS examples from the GitHub `OpenCMISS-Examples`_ organisation,
# which are build along with the main components and added as CTest test cases. 
#
# Depending on the effective configuration, a suitable selection of the following examples is build and run:
#
#    Classical field - Fortran
#        This feature test is build whenever Iron is build. See :var:`OC_USE_<COMP>`.
#
#    Classical field - C
#        This example is only build when the C bindings for Iron are build.
#        See the :ref:`IRON_WITH_C_BINDINGS <intercomponent>` variable.
#
#    Finite elasticity cantilever - Fortran
#        This feature test is build whenever Iron is build. See :var:`OC_USE_<COMP>`.
#
#    Bioelectrics Monodomain - Fortran
#        This feature test is build whenever
#
#            * Iron and CellML are build, see :var:`OC_USE_<COMP>`.
#            * Iron with CellML is enabled, see :ref:`IRON_WITH_CELLML <intercomponent>`.
#
#    Classical field static advection diffusion with FieldML - Fortran
#        This feature test is build whenever
#
#            * Iron and FieldML-API are build, see :var:`OC_USE_<COMP>`.
#            * Iron with FieldML is enabled, see :ref:`IRON_WITH_FIELDML <intercomponent>`.
#
# See also: :ref:`build targets`.
#
# .. _`OpenCMISS-Examples`: https://www.github.com/OpenCMISS-Examples
#

set(_FEATURETESTS_UPDATE_TARGETS )

# Only run the feature tests if we build more than the dependencies
if (NOT OC_DEPENDENCIES_ONLY)
    set(FEATURE_TEST_PREFIX opencmiss_feature_)
    # Iron-related feature tests
    if (OC_USE_IRON)
        set(FEATURE_TEST_EXAMPLES 
            classicalfield_laplace_laplace_fortran
            finiteelasticity_cantilever_fortran
        )
        if (IRON_WITH_C_BINDINGS)
            list(APPEND FEATURE_TEST_EXAMPLES classicalfield_laplace_laplace_c)
        endif()
        if (OC_USE_CELLML AND IRON_WITH_CELLML)
            list(APPEND FEATURE_TEST_EXAMPLES 
                bioelectrics_monodomain_fortran
                cellml_model-integration_fortran
            )
        endif()
        if (OC_USE_FIELDML-API AND IRON_WITH_FIELDML)
            list(APPEND FEATURE_TEST_EXAMPLES classicalfield_advectiondiffusion_staticadvectiondiffusion_fieldml)
        endif()
        # Collect any arguments
        # n98.xml is the only currently working xml file
        set(bioelectrics_monodomain_fortran_ARGS 0.005 0.1001 70 n98.xml)
        # Only file: n98.xml
        set(cellml_model-integration_fortran_ARGS n98.xml)
    endif()
    # Iron-related feature tests
    if (OC_USE_ZINC)
        #TODO
    endif()
    
    set(FEATURETESTS_BINARY_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/featuretests)
    set(FEATURETESTS_SRC_DIR ${OPENCMISS_ROOT}/src/featuretests)
    set(GITHUB_ORGANIZATION OpenCMISS-Examples)
    set(_FT_EX_EP )
    foreach(example_name ${FEATURE_TEST_EXAMPLES})
        list(APPEND _FT_EX_EP "${OC_EP_PREFIX}${example_name}")
        list(APPEND _FEATURETESTS_UPDATE_TARGETS "${example_name}-update")
        set(BIN_DIR "${FEATURETESTS_BINARY_DIR}/${example_name}")
        set(SRC_DIR "${FEATURETESTS_SRC_DIR}/${example_name}")
        set(INSTALL_DIR ${BIN_DIR}/install)
        # Set correct paths
        set(DEFS 
            -DOPENCMISS_INSTALL_DIR=${OPENCMISS_INSTALL_ROOT}
            -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
            -DMPI=${MPI}
        )
        # Instead of passing the (mpi-)compilers, we should imitate
        # the behaviour thats in place for anyone building an example
        # - they only use TOOLCHAIN and MPI mnemonics
        if (TOOLCHAIN)
            list(APPEND DEFS -DTOOLCHAIN=${TOOLCHAIN})  
        endif()
        set(${example_name}_BRANCH ${OC_FEATURETESTS_BRANCH})
        createExternalProjects(${example_name} "${SRC_DIR}" "${BIN_DIR}" "${DEFS}")
        addConvenienceTargets(${example_name} "${BIN_DIR}" "${SRC_DIR}")
    
        # Dont build with the main build, as installation of OpenCMISS has not been done by then.
        set_target_properties(${OC_EP_PREFIX}${example_name} PROPERTIES EXCLUDE_FROM_ALL YES)
        
        add_test(NAME ${FEATURE_TEST_PREFIX}${example_name}
            COMMAND run ${${example_name}_ARGS}
            WORKING_DIRECTORY ${INSTALL_DIR}
        )
    endforeach()
    # Add a top level target that runs only the feature tests
    add_custom_target(featuretests
        DEPENDS ${_FT_EX_EP} # Triggers the build
        COMMAND ${CMAKE_CTEST_COMMAND} -R ${FEATURE_TEST_PREFIX}*
        COMMENT "Running OpenCMISS feature tests"
    )
else()
    # Add a top level target that runs only the feature tests
    add_custom_target(featuretests
        COMMAND ${CMAKE_COMMAND} -E echo "No feature tests for dependency-only builds."
    )
endif()
