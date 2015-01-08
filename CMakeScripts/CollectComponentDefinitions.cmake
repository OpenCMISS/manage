########################################################################
# Collect common arguments for components/subprojects
SET(COMPONENT_COMMON_DEFS )

# As the CMAKE_ARGS are a list themselves, we need to treat the ; in the (possible) list of module_paths
# specially. Therefore CMAKE has a special command $<SEMICOLON>
STRING(REPLACE ";" "$<SEMICOLON>" CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")

# Misc definitions
LIST(APPEND COMPONENT_COMMON_DEFS
    -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DBUILD_PRECISION=${BUILD_PRECISION}
    -DBUILD_TESTS=${BUILD_TESTS}
    -DCMAKE_PREFIX_PATH=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/lib/cmake
    -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
    -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
)

# Add compilers and flags
foreach(lang C CXX Fortran)
    if (CMAKE_${lang}_FLAGS)
        LIST(APPEND COMPONENT_COMMON_DEFS
            -DCMAKE_${lang}_FLAGS=${CMAKE_${lang}_FLAGS}
        )
    endif()
    if(CMAKE_${lang}_COMPILER)
        LIST(APPEND COMPONENT_COMMON_DEFS
            -DCMAKE_${lang}_COMPILER=${CMAKE_${lang}_COMPILER}
        )
    endif()
endforeach()

# OpenMP multithreading
foreach(DEP ${OCM_DEPS_WITH_OPENMP})
    if(${DEP} STREQUAL ${PROJECT_NAME})
        LIST(APPEND COMPONENT_COMMON_DEFS
            -DWITH_OPENMP=${OCM_USE_MT}
        )
    endif()
endforeach()

# check if MPI compilers should be forwarded/set
# so that the local FindMPI uses that
foreach(DEP ${OCM_DEPS_WITHMPI})
    if(${DEP} STREQUAL ${PROJECT_NAME})
        if (MPI)
            LIST(APPEND COMPONENT_COMMON_DEFS
                -DMPI=${MPI}
            )
        endif()
        if (MPI_HOME)
            LIST(APPEND COMPONENT_COMMON_DEFS
                -DMPI_HOME=${MPI_HOME}
            )
        endif()
        foreach(lang C CXX Fortran)
            if(MPI_${lang}_COMPILER)
                LIST(APPEND COMPONENT_COMMON_DEFS
                    -DMPI_${lang}_COMPILER=${MPI_${lang}_COMPILER}
                )
            endif()
        endforeach()
    endif()
endforeach()

# Pass on force flags (consumed by find_package calls)
foreach(DEP ${${PROJECT_NAME}_DEPS})
    if (OCM_FORCE_${DEP})
	    LIST(APPEND COMPONENT_COMMON_DEFS 
	        -DOCM_FORCE_${DEP}=${OCM_FORCE_${DEP}}
	    )
	endif()
endforeach()