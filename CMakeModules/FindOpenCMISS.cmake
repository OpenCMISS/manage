# Provides the necessary logic to find an OpenCMISS installation.
# Does not yet listen to "REQUIRED" or "QUIET" modifiers but throws an error if anything is missing.
#
# Provides the target "opencmiss" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the top level libraries configured in OpenCMISS.

# Find the build context (normally either in same location as this file or at OPENCMISS_INSTALL_DIR)
find_file(OPENCMISS_BUILD_CONTEXT OpenCMISSBuildContext.cmake
    HINTS . ${OPENCMISS_INSTALL_DIR} 
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/release
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/debug
)
set(OPENCMISS_FOUND NO)
if (OPENCMISS_BUILD_CONTEXT)
    
    # Include the build context
    include(${OPENCMISS_BUILD_CONTEXT})
    
    message(STATUS "Using OpenCMISS-${OPENCMISS_BUILD_TYPE} installation at ${OPENCMISS_INSTALL_DIR}")
    
    # Append the OpenCMISS module path to the current path
    list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})
    
    # Add the prefix path so the config files can be found
    list(INSERT 0 CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH})
    
    # Add the opencmiss library (INTERFACE type is new since 3.0)
    add_library(opencmiss INTERFACE IMPORTED)
    
    # Add top level libraries of OpenCMISS framework if configured
    if (OCM_USE_IRON)
        find_package(IRON ${IRON_VERSION} REQUIRED)
        target_link_libraries(opencmiss INTERFACE iron)
    endif()
    if (OCM_USE_ZINC)
        find_package(ZINC ${ZINC_VERSION} REQUIRED)
        target_link_libraries(opencmiss INTERFACE zinc)
    endif()
    
    # Add the link libraries for opencmiss
    #set_target_properties(opencmiss PROPERTIES
    #    INTERFACE_LINK_LIBRARIES "${OPENCMISS_TARGETS}"
    #)
    
    #get_target_property(ocd opencmiss INTERFACE_COMPILE_DEFINITIONS)
    #get_target_property(oid opencmiss INTERFACE_INCLUDE_DIRECTORIES)
    #get_target_property(oil opencmiss INTERFACE_LINK_LIBRARIES)
    #message(STATUS "opencmiss target config:\nINTERFACE_COMPILE_DEFINITIONS=${ocd}\nINTERFACE_INCLUDE_DIRECTORIES=${oid}\nINTERFACE_LINK_LIBRARIES=${oil}")
    
    set(OPENCMISS_FOUND YES)
else()
    message(FATAL_ERROR "Could not find OpenCMISS. Missing OpenCMISSBuildContext.cmake (HINTS: ${OPENCMISS_INSTALL_DIR})")
endif()
