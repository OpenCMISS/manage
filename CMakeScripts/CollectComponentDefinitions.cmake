########################################################################
# Collect common arguments for components/subprojects
SET(COMPONENT_COMMON_DEFS )

# Misc definitions
# The COMMON_PACKAGE_CONFIG_DIR contains the cmake-generated target config files consumed by find_package(... CONFIG).
# Those are "usually" placed under the lib/ folders of the installation tree, however, the OpenCMISS build system
# install trees also have the build type as subfolders. As the config-files generated natively create differently named files
# for each build type, they can be collected in a common subfolder. As the build type subfolder-element is the last in line,
# we simply use the parent folder of the component's CMAKE_INSTALL_PREFIX to place the cmake package config files.
SET(COMMON_PACKAGE_CONFIG_DIR cmake) #../cmake

# As the CMAKE_ARGS are a list themselves, we need to treat the ; in the (possible) list of module_paths
# specially. Therefore CMAKE has a special command $<SEMICOLON>
STRING(REPLACE ";" "$<SEMICOLON>" CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")

LIST(APPEND COMPONENT_COMMON_DEFS
    -DCMAKE_INSTALL_PREFIX=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DBUILD_PRECISION=${BUILD_PRECISION}
    -DBUILD_TESTS=${BUILD_TESTS}
    -DCMAKE_PREFIX_PATH=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/${COMMON_PACKAGE_CONFIG_DIR}
    -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
    -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
    -DFORTRAN_MANGLING=${FORTRAN_MANGLING}
    -DINT_TYPE=${INT_TYPE}
    -DPACKAGE_CONFIG_DIR=${COMMON_PACKAGE_CONFIG_DIR}
    -DCMAKE_NO_SYSTEM_FROM_IMPORTED=YES
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
    if (OCM_SYSTEM_${COMP})
	    LIST(APPEND COMPONENT_COMMON_DEFS 
	        -DOCM_SYSTEM_${COMP}=${OCM_SYSTEM_${COMP}}
	    )
	endif()
endforeach()

# fPIC flag
# if BUILD_SHARED_LIBS is set to true, the POSITION_INDEPENDENT_CODE property is set automatically for EXECUTABLE and SHARED library targets.
# However, OBJECT targets wont automatically have POSITION_INDEPENDENT_CODE if BUILD_SHARED_LIBS is set to true, so we manually set this
# if we build shared libraries to enable linking of object libraries into shared libraries.
if (BUILD_SHARED_LIBS OR OCM_POSITION_INDEPENDENT_CODE)
    list(APPEND COMPONENT_COMMON_DEFS -DCMAKE_POSITION_INDEPENDENT_CODE=YES)
endif()

# For shared libs, use the correct install RPATH to enable binaries to find the shared libs.
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
if (BUILD_SHARED_LIBS)
    list(APPEND COMPONENT_COMMON_DEFS 
        -DCMAKE_INSTALL_RPATH=${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/lib
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE)
endif()

# Forward verbosity if wanted
if (CMAKE_VERBOSE_MAKEFILE)
    list(APPEND COMPONENT_COMMON_DEFS -DCMAKE_VERBOSE_MAKEFILE=YES)
endif()