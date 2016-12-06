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
set(GTEST_CASENAME GTest)
set(CLANG_CASENAME Clang)
set(CSIM_CASENAME CSim)
# Some packages naturally have their exported target names differ from those of the package - this is convenience but
# enables us to stay more consistent (e.g. we have "libbz2.a" on system installations instead of "libbzip2.a")
set(LIBXML2_TARGETNAME xml2)
set(BZIP2_TARGETNAME bz2)
set(NETGEN_TARGETNAME nglib)
set(IMAGEMAGICK_TARGETNAME MagickCore)
set(GTEST_TARGETNAME gtest_main) # This will bite us some day.
# There's also a logical 'gtest' target. But here we can only define one (in general for ALL possible
# packages to cover with this kind of wrapper)
    
# Generate the wrappers (if not existing)
foreach(PACKAGE_NAME ${PACKAGES_WITH_TARGETS})
    # See above
    if (${PACKAGE_NAME}_CASENAME)
        SET(PACKAGE_CASENAME ${${PACKAGE_NAME}_CASENAME})
    else()
        SET(PACKAGE_CASENAME ${PACKAGE_NAME})
    endif()

    set(FILE ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers/Find${PACKAGE_CASENAME}.cmake)
    #if(NOT EXISTS ${FILE})
        # Some packages have different target names than their package name
        if (${PACKAGE_NAME}_TARGETNAME)
            set(PACKAGE_TARGET ${${PACKAGE_NAME}_TARGETNAME})
        else()
            string(TOLOWER ${PACKAGE_NAME} PACKAGE_TARGET)    
        endif()
        # Define custom function names so that the correct functions are called
        # using the same name would (silently) overload the functions, causing misleading outputs
        string(REPLACE "-" "_" _HLP ${PACKAGE_TARGET})
        set(MESSAGE "my_stupid_package_dependent_message_function_${_HLP}")
        set(DEBUG_MESSAGE "my_stupid_package_dependent_message_function_debug_${_HLP}")
        configure_file("${MANAGE_MODULE_PATH}/Templates/FindXXX.template.cmake" "${FILE}" @ONLY)
    #endif()
endforeach()

# Add directory to module path
list(APPEND CMAKE_MODULE_PATH 
    ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers
    )
list(APPEND OPENCMISS_COMPONENT_MODULE_PATH
    ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers
    )

# Even though the Wrappers are already at the OpenCMISS install dir,
# we also use the install command to allow cpack get a hold of them
install(DIRECTORY ${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers
    DESTINATION cmake
    COMPONENT DevelopmentSDK)
