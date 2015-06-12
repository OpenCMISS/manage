# Provides the necessary logic to find an OpenCMISS installation
#
# Provides the target "opencmiss" that can be added like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the libraries the found OpenCMISS installation is build against.

# Find the build context
find_file(OPENCMISS_BUILD_CONTEXT OpenCMISSBuildContext.cmake
    HINTS ${OPENCMISS_INSTALL_DIR}
)
set(REQ_DIRS )
if (OPENCMISS_BUILD_CONTEXT)
    
    # Include the build context
    include(${OPENCMISS_BUILD_CONTEXT})
    
    # Add the opencmiss library (INTERFACE type is new since 3.0)
    add_library(opencmiss INTERFACE IMPORTED)
    
    # Add the prefix path so the config files can be found
    list(INSERT 0 CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH}) 
    
    # Find each enabled component
    message(STATUS "Looking for OpenCMISS components!")
    foreach(OCM_COMP ${OPENCMISS_COMPONENTS})
        if (OCM_USE_${OCM_COMP})
            message(STATUS "Checking ${OCM_COMP}...")
            # STUPID STUPID STUPID!
            # Some packages have case-sensitive namings as they are shipped (like LibXml2)
            # but within the build environment we solely use upper case. so need that silly
            # workaround
            if (${OCM_COMP}_CASENAME)
                find_package(${${OCM_COMP}_CASENAME} QUIET)
            else()
                find_package(${OCM_COMP} QUIET)
            endif()
            # Have CMake check against the XXX_FOUND variables at the end; this way,
            # finding opencmiss fails whilst also telling which dependency could not be found.
            list(APPEND REQ_DIRS ${OCM_COMP}_FOUND)
        endif()
    endforeach()
    
    set(INVALID_TARGETS )
    foreach(TGT ${OPENCMISS_TARGETS})
        if (TARGET ${TGT})
            get_target_property(_PROP ${TGT} INTERFACE_COMPILE_DEFINITIONS)
            if (_PROP)
                set_property(TARGET opencmiss APPEND PROPERTY
                  INTERFACE_COMPILE_DEFINITIONS "${_PROP}"
                )
            endif()
            get_target_property(_PROP ${TGT} INTERFACE_INCLUDE_DIRECTORIES)
            if (_PROP)
                set_property(TARGET opencmiss APPEND PROPERTY
                  INTERFACE_INCLUDE_DIRECTORIES "${_PROP}"
                )
            endif()
            #message(STATUS "Adding target ${TGT}")
        else()
            message(STATUS "Skipping invalid target ${TGT}")
            list(APPEND INVALID_TARGETS ${TGT})
        endif()
    endforeach()
    list(REMOVE_ITEM OPENCMISS_TARGETS ${INVALID_TARGETS})
    
    # Add the link libraries for opencmiss
    set_target_properties(opencmiss PROPERTIES
        INTERFACE_LINK_LIBRARIES "${OPENCMISS_TARGETS}"
    )
    
    #get_target_property(ocd opencmiss INTERFACE_COMPILE_DEFINITIONS)
    #get_target_property(oid opencmiss INTERFACE_INCLUDE_DIRECTORIES)
    #get_target_property(oil opencmiss INTERFACE_LINK_LIBRARIES)
    #message(STATUS "opencmiss target config:\nINTERFACE_COMPILE_DEFINITIONS=${ocd}\nINTERFACE_INCLUDE_DIRECTORIES=${oid}\nINTERFACE_LINK_LIBRARIES=${oil}")
    
    set(OPENCMISS_FOUND YES)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OPENCMISS DEFAULT_MSG OPENCMISS_BUILD_CONTEXT ${REQ_DIRS})
