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
    -DFORTRAN_MANGLING=${FORTRAN_MANGLING}
    -DINT_TYPE=${INT_TYPE}
)

# Add compilers and flags
foreach(lang C CXX Fortran)
    if (CMAKE_${lang}_FLAGS)
        LIST(APPEND COMPONENT_COMMON_DEFS
            -DCMAKE_${lang}_FLAGS=${CMAKE_${lang}_FLAGS}
        )
    endif()
    # Also forward build-type specific flags
    foreach(BUILDTYPE RELEASE DEBUG)
        if (CMAKE_${lang}_FLAGS_${BUILDTYPE})
            LIST(APPEND COMPONENT_COMMON_DEFS
                -DCMAKE_${lang}_FLAGS_${BUILDTYPE}=${CMAKE_${lang}_FLAGS_${BUILDTYPE}}
            )
        endif()
    endforeach()
    if(CMAKE_${lang}_COMPILER)
        LIST(APPEND COMPONENT_COMMON_DEFS
            -DCMAKE_${lang}_COMPILER=${CMAKE_${lang}_COMPILER}
        )
    endif()
endforeach()

# Pass on local lookup flags (consumed by find_package calls)
foreach(COMP ${OPENCMISS_COMPONENTS})
    if (OCM_${COMP}_LOCAL)
	    LIST(APPEND COMPONENT_COMMON_DEFS 
	        -DOCM_${COMP}_LOCAL=${OCM_${COMP}_LOCAL}
	    )
	endif()
endforeach()

# fPIC flag
if (OCM_POSITION_INDEPENDENT_CODE)
    list(APPEND COMPONENT_COMMON_DEFS -DCMAKE_POSITION_INDEPENDENT_CODE=YES)
endif()

# For shared libs, use the correct install RPATH to enable binaries to find the shared libs.
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
if (BUILD_SHARED_LIBS)
    list(APPEND COMPONENT_COMMON_DEFS 
        -DCMAKE_INSTALL_RPATH=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/lib
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE)
endif()