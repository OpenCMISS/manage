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

set(_KEYTESTS_UPDATE_TARGETS )
set(OC_KEYTESTS )

# Only run the key tests if we build more than the dependencies
if (NOT OC_DEPENDENCIES_ONLY)
    # Prefix for any tests that belongs to the OpenCMISS key tests
    set(KEY_TEST_PREFIX opencmiss_key_)
    
    # Iron-related key tests
    if (OC_USE_IRON)
        set(KEY_TEST_EXAMPLES 
            classicalfield_laplace_laplace_fortran
            finiteelasticity_cantilever_fortran
        )
        if (IRON_WITH_C_BINDINGS)
            list(APPEND KEY_TEST_EXAMPLES classicalfield_laplace_laplace_c)
        endif()
        if (OC_USE_CELLML AND IRON_WITH_CELLML)
            list(APPEND KEY_TEST_EXAMPLES 
                bioelectrics_monodomain_fortran
                cellml_model-integration_fortran
            )
        endif()
        if (OC_USE_FIELDML-API AND IRON_WITH_FIELDML)
            list(APPEND KEY_TEST_EXAMPLES classicalfield_advectiondiffusion_staticadvectiondiffusion_fieldml)
        endif()
        # Collect any arguments
        # n98.xml is the only currently working xml file
        set(bioelectrics_monodomain_fortran_ARGS 0.005 0.1001 70 n98.xml)
        # Only file: n98.xml
        set(cellml_model-integration_fortran_ARGS n98.xml)
        
        # If we generate bindings, we also add key tests that verify their functionality.
        # Implemented for virtualenv case only thus far
        if (IRON_WITH_Python_BINDINGS AND PYTHON_VIRTUALENV_DIR)
            add_test(NAME ${KEY_TEST_PREFIX}iron_python_bindings
                COMMAND ${CMAKE_CTEST_COMMAND} -R python_bindings_import --output-on-failure -C $<CONFIG>
                WORKING_DIRECTORY "${IRON_BINARY_DIR}"
            )
            list(APPEND OC_KEYTESTS ${KEY_TEST_PREFIX}iron_python_bindings)
        endif()
    endif()
    # Zinc-related key tests
    if (OC_USE_ZINC)
        # If we generate bindings, we also add key tests that verify their functionality.
        # Implemented for virtualenv case only thus far
        if (ZINC_WITH_Python_BINDINGS AND PYTHON_VIRTUALENV_DIR)
            add_test(NAME ${KEY_TEST_PREFIX}zinc_python_bindings
                COMMAND ${CMAKE_CTEST_COMMAND} -R python_bindings_import --output-on-failure -C $<CONFIG>
                WORKING_DIRECTORY "${ZINC_BINARY_DIR}"
            )
            list(APPEND OC_KEYTESTS ${KEY_TEST_PREFIX}zinc_python_bindings)
        endif()
    endif()
    
    set(KEYTESTS_BINARY_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/keytests)
    set(KEYTESTS_SRC_DIR ${OPENCMISS_ROOT}/src/keytests)
    set(GITHUB_ORGANIZATION OpenCMISS-Examples)
    set(_FT_EX_EP )
    foreach(example_name ${KEY_TEST_EXAMPLES})
        list(APPEND _FT_EX_EP "${OC_EP_PREFIX}${example_name}")
        list(APPEND _KEYTESTS_UPDATE_TARGETS "${example_name}-update")
        set(BIN_DIR "${KEYTESTS_BINARY_DIR}/${example_name}")
        set(SRC_DIR "${KEYTESTS_SRC_DIR}/${example_name}")
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
        set(${example_name}_BRANCH ${OC_KEYTESTS_BRANCH})
        createExternalProjects(${example_name} "${SRC_DIR}" "${BIN_DIR}" "${DEFS}")
        addConvenienceTargets(${example_name} "${BIN_DIR}" "${SRC_DIR}")
    
        # Dont build with the main build, as installation of OpenCMISS has not been done by then.
        set_target_properties(${OC_EP_PREFIX}${example_name} PROPERTIES EXCLUDE_FROM_ALL YES)
        
        add_test(NAME ${KEY_TEST_PREFIX}${example_name}
            COMMAND run ${${example_name}_ARGS}
            WORKING_DIRECTORY ${INSTALL_DIR}
        )
        list(APPEND OC_KEYTESTS ${KEY_TEST_PREFIX}${example_name})
    endforeach()
    
    # Set up the correct environment for the tests
    # See https://cmake.org/pipermail/cmake/2009-May/029464.html
    file(TO_NATIVE_PATH "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}/bin" PATH1)
    file(TO_NATIVE_PATH "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_NO_BUILD_TYPE}/lib" PATH2)
    file(TO_NATIVE_PATH "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/bin" PATH3)
    file(TO_NATIVE_PATH "${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/lib" PATH4)
    if (WIN32)
       set(LD_VARNAME "PATH")
       set(LD_PATH "${PATH1};${PATH2};${PATH3};${PATH4};$ENV{PATH}")
       string(REPLACE ";" "\\;" LD_PATH "${LD_PATH}")
    else()
       set(LD_VARNAME "LD_LIBRARY_PATH")
       set(LD_PATH "${PATH1}:${PATH2}:${PATH3}:${PATH4}:$ENV{LD_LIBRARY_PATH}")
    endif()
    foreach(KEYTEST ${OC_KEYTESTS})
        set_tests_properties(${KEYTEST} PROPERTIES
            TIMEOUT 30 
            ENVIRONMENT "${LD_VARNAME}=${LD_PATH}")
    endforeach()
    
    # Add a top level target that runs only the key tests
    add_custom_target(keytests
        DEPENDS ${_FT_EX_EP} # Triggers the build
        COMMAND ${CMAKE_CTEST_COMMAND} -R ${KEY_TEST_PREFIX}* -O ${OC_SUPPORT_DIR}/keytests.log --output-on-failure -C $<CONFIG>
        COMMENT "Running OpenCMISS key tests"
    )
else()
    # Add a top level target that runs only the key tests
    add_custom_target(keytests
        COMMAND ${CMAKE_COMMAND} -E echo "No key tests for dependency-only builds."
    )
endif()
