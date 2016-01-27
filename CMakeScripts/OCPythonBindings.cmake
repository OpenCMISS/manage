# Only run stuff if we're having python and
set(PYTHON_VIRTUALENV_DIR "VIRTUALENV-NOTFOUND")
if (IRON_WITH_Python_BINDINGS OR ZINC_WITH_Python_BINDINGS)
    if (OC_PYTHON_PREREQ_FOUND)
        find_program(VIRTUALENV_EXECUTABLE virtualenv)
        if (VIRTUALENV_EXECUTABLE)
            set(PYTHON_VIRTUALENV_DIR ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/python)
            add_custom_target(python_virtualenv ALL
                COMMAND ${VIRTUALENV_EXECUTABLE} --system-site-packages "${PYTHON_VIRTUALENV_DIR}"
            )
        else()
            log("Python bindings will be generated but virtualenv is not available. Convenience binding switching will not be available.\nSee http://www.opencmiss.org/documentation for more information" WARNING)
        endif()
    else()
        log("Python bindings were requested for Iron or Zinc but the prerequisites are not met.\nPython, Python development libraries and Swig are required.\nSee http://www.opencmiss.org/documentation for more information." ERROR)
    endif()
endif()