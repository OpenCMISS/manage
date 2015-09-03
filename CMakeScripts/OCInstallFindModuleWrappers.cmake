# This file sets all the targets any (external/3rd party) component provides
SET(PACKAGES_WITH_TARGETS BLAS HYPRE LAPACK METIS
    MUMPS PARMETIS PASTIX PETSC PLAPACK PTSCOTCH SCALAPACK
    SCOTCH SOWING SUITESPARSE SUNDIALS SUPERLU SUPERLU_DIST ZLIB SZIP HDF5
    BZIP2 LIBXML2 JPEG OPTPP NETGEN GLEW)
    
# Some shipped find-package modules have a different case-sensitive spelling - need to stay consistent with that
SET(LIBXML2_CASENAME LibXml2)
SET(BZIP2_CASENAME BZip2)
# Some packages naturally have their exported target names differ from those of the package - this is convenience but
# enables us to stay more consistent (e.g. we have "libbz2.a" on system installations instead of "libbzip2.a")
SET(LIBXML2_TARGETNAME xml2)
SET(BZIP2_TARGETNAME bz2)
SET(NETGEN_TARGETNAME nglib)
    
# Generate the wrappers (if not existing)
SET(OPENCMISS_FINDMODULE_WRAPPER_DIR ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSFindModuleWrappers)
foreach(PACKAGE_NAME ${PACKAGES_WITH_TARGETS})
    # See above
    if (${PACKAGE_NAME}_CASENAME)
        SET(PACKAGE_CASENAME ${${PACKAGE_NAME}_CASENAME})
    else()
        SET(PACKAGE_CASENAME ${PACKAGE_NAME})
    endif()
    SET(FILE ${OPENCMISS_FINDMODULE_WRAPPER_DIR}/Find${PACKAGE_CASENAME}.cmake)
    #if(NOT EXISTS ${FILE})
        # Some packages have different target names than their package name
        if (${PACKAGE_NAME}_TARGETNAME)
            set(PACKAGE_TARGET ${${PACKAGE_NAME}_TARGETNAME})
        else()
            string(TOLOWER ${PACKAGE_NAME} PACKAGE_TARGET)    
        endif()
        configure_file(${OPENCMISS_MANAGE_DIR}/Templates/FindXXX.template.cmake ${FILE} @ONLY)
    #endif()
endforeach()

# Add directory to module path
list(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_FINDMODULE_WRAPPER_DIR}
)
