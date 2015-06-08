# Appends a library to the list of interface_link_libraries
function(append_link_library TARGET LIB)
    get_target_property(CURRENT_ILL
        ${TARGET} INTERFACE_LINK_LIBRARIES)
    if (NOT CURRENT_ILL)
        SET(CURRENT_ILL )
    endif()
    # Treat framework references different
    if(APPLE AND ${LIB} MATCHES ".framework$")
        STRING(REGEX REPLACE ".*/([A-Za-z0-9.]+).framework$" "\\1" FW_NAME ${LIB})
        #message(STATUS "Matched '${FW_NAME}' to ${LIB}")
        SET(LIB "-framework ${FW_NAME}")
    endif()
    set_target_properties(${TARGET} PROPERTIES
        INTERFACE_LINK_LIBRARIES "${CURRENT_ILL};${LIB}")
endfunction()

#message(STATUS "OpenCMISS Find@PACKAGE_CASENAME@ wrapper called. (CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH})")

# Default: Not found
SET(@PACKAGE_CASENAME@_FOUND NO)
    
# The default way is to look for components in the current PREFIX_PATH, e.g. own build components.
# If a LOCAL flag is set for a package, the MODULE and CONFIG modes are tried outside the PREFIX PATH first.
if (NOT OCM_SYSTEM_@PACKAGE_NAME@)
     find_package(@PACKAGE_CASENAME@ ${@PACKAGE_CASENAME@_FIND_VERSION} CONFIG
        PATHS ${CMAKE_PREFIX_PATH}
        QUIET
        NO_DEFAULT_PATH)
else()
    # If local lookup is enabled, try to look for packages in old-fashioned module mode and then config modes 
    
    message(STATUS "System search of component @PACKAGE_CASENAME@ enabled")
    
    # Remove all paths resolving to this one here so that recursive calls wont search here again
    SET(_MODPATHCOPY ${CMAKE_MODULE_PATH})
    SET(_READDME )
    foreach(_ENTRY ${_MODPATHCOPY})
        get_filename_component(_ENTRY_ABSOLUTE ${_ENTRY} ABSOLUTE)
        get_filename_component(_PARENT_DIRECTORY ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
        if (_ENTRY_ABSOLUTE STREQUAL _PARENT_DIRECTORY)
            LIST(REMOVE_ITEM CMAKE_MODULE_PATH ${_ENTRY})
            LIST(APPEND _READDME ${_ENTRY})
        endif()
    endforeach()
    
    # Make "native" call to find_package in MODULE mode first
    message(STATUS "Trying to find @PACKAGE_CASENAME@ ${@PACKAGE_CASENAME@_FIND_VERSION} in MODULE mode")
    message(STATUS "(CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH})")
    
    # Temporarily disable the required flag (if set from outside)
    SET(_PKG_REQ_OLD ${@PACKAGE_CASENAME@_FIND_REQUIRED})
    UNSET(@PACKAGE_CASENAME@_FIND_REQUIRED)
    
    # Remove CMAKE_INSTALL_PREFIX from CMAKE_SYSTEM_PREFIX_PATH - we dont want the module search to "accidentally"
    # discover the packages in our install directory, collect libraries and then re-turn them into targets (redundant round-trip)
    LIST(REMOVE_ITEM CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
    
    # Actual MODULE mode find call
    find_package(@PACKAGE_CASENAME@ ${@PACKAGE_CASENAME@_FIND_VERSION} MODULE QUIET)
    
    # Restore stuff
    SET(@PACKAGE_CASENAME@_FIND_REQUIRED ${_PKG_REQ_OLD})
    LIST(APPEND CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
    
    if (@PACKAGE_NAME@_FOUND)
        # Also set the casename variant as this is checked upon at the end ("newer" version; config mode returns
        # a xXx_FOUND variable that has the same case as used for the call find_package(xXx ..)
        set(@PACKAGE_CASENAME@_FOUND YES)
        if (NOT TARGET @PACKAGE_TARGET@)
            set(LIBS ${@PACKAGE_NAME@_LIBRARIES})
            message(STATUS "Found package @PACKAGE_CASENAME@: ${LIBS}")
            SET(INCS )
            foreach(DIRSUFF _INCLUDE_DIRS _INCLUDES _INCLUDE_PATH _INCLUDE_DIR)
                if (DEFINED @PACKAGE_NAME@${DIRSUFF})
                    LIST(APPEND INCS ${@PACKAGE_NAME@${DIRSUFF}})
                endif()
            endforeach()
            
            #message(STATUS "Converting found module to imported targets for package @PACKAGE_NAME@")
                #":\nLibraries: ${LIBS}\nIncludes: ${INCS}")
            if (NOT CMAKE_CFG_INTDIR STREQUAL .)
                STRING(TOUPPER ${CMAKE_CFG_INTDIR} CURRENT_BUILD_TYPE)
            elseif(CMAKE_BUILD_TYPE)
                STRING(TOUPPER ${CMAKE_BUILD_TYPE} CURRENT_BUILD_TYPE)
            else()
                SET(CURRENT_BUILD_TYPE NOCONFIG)
            endif()
            #message(STATUS "Current build type: CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -- CURRENT_BUILD_TYPE=${CURRENT_BUILD_TYPE}")
            
            list(GET LIBS 0 _FIRST_LIB)
            add_library(@PACKAGE_TARGET@ UNKNOWN IMPORTED)
            # Treat apple frameworks separate
            # See http://stackoverflow.com/questions/12547624/cant-link-macos-frameworks-with-cmake
            if(APPLE AND ${_FIRST_LIB} MATCHES ".framework$")
                STRING(REGEX REPLACE ".*/([A-Za-z0-9.]+).framework$" "\\1" FW_NAME ${_FIRST_LIB})
                #message(STATUS "Matched '${FW_NAME}' to ${LIB}")
                SET(_FIRST_LIB "${_FIRST_LIB}/${FW_NAME}")
            endif()
            set_target_properties(@PACKAGE_TARGET@ PROPERTIES 
                    IMPORTED_LOCATION_${CURRENT_BUILD_TYPE} ${_FIRST_LIB}
                    IMPORTED_CONFIGURATIONS ${CURRENT_BUILD_TYPE}
                    INTERFACE_INCLUDE_DIRECTORIES "${INCS}"
            )
            list(REMOVE_AT LIBS 0)
            # Add non-matched libraries as link libraries so nothing gets forgotten
            foreach(LIB ${LIBS})
                message(STATUS "Adding extra library ${LIB} to link interface of @PACKAGE_TARGET@")
                append_link_library(@PACKAGE_TARGET@ ${LIB})
            endforeach()
        else()
            message(STATUS "Find@PACKAGE_CASENAME@: Avoiding double import of target '@PACKAGE_TARGET@'")
        endif()
    else()
        #message(STATUS "Trying to find @PACKAGE_CASENAME@ ${@PACKAGE_CASENAME@_FIND_VERSION} in CONFIG mode")
        # First look outside the prefix path
        find_package(@PACKAGE_CASENAME@ ${@PACKAGE_NAME@_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)
        
        # If not found, look also at the prefix path
        if (NOT @PACKAGE_CASENAME@_FOUND)
            message(STATUS "No system @PACKAGE_CASENAME@ found/available")
            find_package(@PACKAGE_CASENAME@ ${@PACKAGE_CASENAME@_FIND_VERSION} CONFIG
                QUIET
                PATHS ${CMAKE_PREFIX_PATH}
                NO_CMAKE_ENVIRONMENT_PATH
                NO_SYSTEM_ENVIRONMENT_PATH
                NO_CMAKE_BUILDS_PATH
                NO_CMAKE_PACKAGE_REGISTRY
                NO_CMAKE_SYSTEM_PATH
                NO_CMAKE_SYSTEM_PACKAGE_REGISTRY)
        endif()
    endif()
    
    # Restore the current module path
    # Sloppy as all are added to the front.. this will bite someone somewhere sometime :-p
    foreach(_ENTRY ${_READDME})
        LIST(INSERT CMAKE_MODULE_PATH 0 ${_ENTRY})
    endforeach()
endif()

if (@PACKAGE_CASENAME@_FIND_REQUIRED AND NOT @PACKAGE_CASENAME@_FOUND)
    message(FATAL_ERROR "Could not find @PACKAGE_CASENAME@ with either MODULE or CONFIG mode.\nCMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
endif()