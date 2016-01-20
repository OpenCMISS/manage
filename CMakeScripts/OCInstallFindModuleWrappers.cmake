# Create the list of all components we'll need FindXXX wrappers for.
# Those components are all but those we maintain ourselves.
set(PACKAGES_WITH_TARGETS ${OPENCMISS_COMPONENTS})
list(REMOVE_ITEM PACKAGES_WITH_TARGETS
    LIBCELLML CELLML FIELDML-API ZINC IRON
)
    
# Some shipped find-package modules have a different case-sensitive spelling - need to stay consistent with that
set(LIBXML2_CASENAME LibXml2)
set(BZIP2_CASENAME BZip2)
set(FREETYPE_CASENAME Freetype)
set(IMAGEMAGICK_CASENAME ImageMagick)
# Some packages naturally have their exported target names differ from those of the package - this is convenience but
# enables us to stay more consistent (e.g. we have "libbz2.a" on system installations instead of "libbzip2.a")
set(LIBXML2_TARGETNAME xml2)
set(BZIP2_TARGETNAME bz2)
set(NETGEN_TARGETNAME nglib)
set(IMAGEMAGICK_TARGETNAME MagickCore)
    
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
        configure_file("${OPENCMISS_MANAGE_DIR}/Templates/FindXXX.template.cmake" "${FILE}" @ONLY)
    #endif()
endforeach()

# Add directory to module path
list(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_FINDMODULE_WRAPPER_DIR}
)
