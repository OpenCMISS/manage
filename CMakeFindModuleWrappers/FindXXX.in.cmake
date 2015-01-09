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

function(my_add_library TARGET LIB)
    add_library(${TARGET} UNKNOWN IMPORTED)
    set_property(TARGET ${TARGET} APPEND PROPERTY
        IMPORTED_CONFIGURATIONS ${CURRENT_BUILD_TYPE})
    # Treat apple frameworks separate
    # See http://stackoverflow.com/questions/12547624/cant-link-macos-frameworks-with-cmake
    if(APPLE AND ${LIB} MATCHES ".framework$")
        STRING(REGEX REPLACE ".*/([A-Za-z0-9.]+).framework$" "\\1" FW_NAME ${LIB})
        #message(STATUS "Matched '${FW_NAME}' to ${LIB}")
        SET(LIB "${LIB}/${FW_NAME}")
    endif()
    set_target_properties(${TARGET} PROPERTIES 
            IMPORTED_LOCATION_${CURRENT_BUILD_TYPE} ${LIB})
    # Simply add the m and rt libraries if suitable
    if(UNIX)
        append_link_library(${TARGET} m)
        if(NOT APPLE)
            append_link_library(${TARGET} rt)
        endif()
    endif()
    if (INCS)
        set_target_properties(${TARGET} PROPERTIES 
            INTERFACE_INCLUDE_DIRECTORIES "${INCS}")
    endif()
    #include(~/hpc/ocms/utilities/FunctionDefinitions.cmake)
    #echo_target(${ALL_TARGETS})
endfunction()

macro(MODULE_TO_TARGETS LIBS INCS)
    SET(LIBS ${LIBS})
    SET(ALL_TARGETS @PACKAGE_TARGETS@)
    
    #message(STATUS "Converting found module to imported targets for package @PACKAGE_NAME@")
        #":\nLibraries: ${LIBS}\nIncludes: ${INCS}")
    if (NOT CMAKE_CFG_INTDIR STREQUAL .)
        STRING(TOUPPER ${CMAKE_CFG_INTDIR} CURRENT_BUILD_TYPE)
    elseif(CMAKE_BUILD_TYPE)
        STRING(TOUPPER ${CMAKE_BUILD_TYPE} CURRENT_BUILD_TYPE)
    else()
        SET(CURRENT_BUILD_TYPE NOCONFIG)
    endif()
    #message(STATUS "Current build type: ${CMAKE_BUILD_TYPE} -- ${CURRENT_BUILD_TYPE}")
    
    LIST(LENGTH LIBS NUMLIBS)
    LIST(LENGTH ALL_TARGETS NUMTARGETS)
    # for only one target and one library stuff is easy 
    if(NUMLIBS EQUAL 1 AND NUMTARGETS EQUAL 1)
        message(STATUS "One target and one library: Matching '${ALL_TARGETS}' to library '${LIBS}'")
        my_add_library(${ALL_TARGETS} ${LIBS})
        LIST(APPEND DONE_TARGETS ${ALL_TARGETS})
    else()
        SET(DONE_TARGETS )
        SET(DONE_LIBS )
        foreach(TARGET ${ALL_TARGETS})
            #message(STATUS "Trying target ${TARGET}")
            SET(CURTARGET_DONE FALSE)
            
            # Try different patterns to guess/recognize the already installed packages
            # Here we loop patterns before libraries, so that exact matches are tried
            # against all library names before the more 'relaxed' patterns are tried for a name,
            # which could get a wrong match
            SET(PATTERNS )
            # If we have a version, look for that first
            if (@PACKAGE_NAME@_FIND_VERSION)
                LIST(APPEND PATTERNS 
                    "^(lib)?${TARGET}[-|_]${@PACKAGE_NAME@_FIND_VERSION}.(a|so|lib|dll)$"
                    "^(lib)?${TARGET}[-|_]${@PACKAGE_NAME@_FIND_VERSION}[^.]*")
            endif()
            LIST(APPEND PATTERNS 
                "^(lib)?${TARGET}.(a|so|lib|dll)$"
                "^(lib)?${TARGET}[^.]*"
                "^(lib)?.*${TARGET}[^.]*")
            foreach(PATTERN ${PATTERNS})
                foreach(LIB ${LIBS})
                    get_filename_component(LIBFILE ${LIB} NAME)
                    #message(STATUS "Trying pattern ${PATTERN} for ${LIBFILE}..")
                    if (LIBFILE MATCHES ${PATTERN})
                        message(STATUS "Matched target ${TARGET} to library '${LIB}' (${LIBFILE} MATCHES ${PATTERN})")
                        my_add_library(${TARGET} ${LIB})
                        SET(CURTARGET_DONE TRUE)
                        LIST(APPEND DONE_TARGETS ${TARGET})
                        LIST(APPEND DONE_LIBS ${LIB})
                        break()
                    endif()
                endforeach()
                if (CURTARGET_DONE)
                    break()
                endif()
            endforeach()
        endforeach()
        
        # Warn about non-found targets
        foreach(TARGET ${ALL_TARGETS})
            LIST(FIND DONE_TARGETS ${TARGET} POSI)
            if (POSI EQUAL -1)
                LIST(GET LIBS 0 DEFAULT_LIB)
                message(STATUS "Target ${TARGET} could not be matched to any library. Associating with (first listed) library ${DEFAULT_LIB}.")
                my_add_library(${TARGET} ${DEFAULT_LIB})
                LIST(APPEND DONE_TARGETS ${TARGET})
            endif()
        endforeach()
        
        # Add non-matched libraries as link libraries so nothing gets forgotten
        foreach(LIB ${LIBS})
            LIST(FIND DONE_LIBS ${LIB} POSI)
            if (POSI EQUAL -1)
                message(STATUS "Adding not-associated library ${LIB} to link interface of targets '${DONE_TARGETS}'")
                foreach(TARGET ${DONE_TARGETS})
                    append_link_library(${TARGET} ${LIB})
                endforeach()
            endif()
        endforeach()
        
        #foreach(TARGET ${ALL_TARGETS})
        #    get_target_property(HELP ${TARGET} INTERFACE_LINK_LIBRARIES)
        #    message(STATUS "@@@@@@@@@@@@ Link libs of ${TARGET}: ${HELP}")
        #endforeach()
    endif()
endmacro()

#message(STATUS "OpenCMISS Find@PACKAGE_NAME@ wrapper called. (CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH})")

# Default: Not found
SET(@PACKAGE_NAME@_FOUND NO)
    
# The default way is to look for components in the current PREFIX_PATH, e.g. own build components.
# If a LOCAL flag is set for a package, the MODULE and CONFIG modes are tried outside the PREFIX PATH first.
if (NOT OCM_@PACKAGE_NAME@_LOCAL)
     find_package(@PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} CONFIG
        PATHS ${CMAKE_PREFIX_PATH}
        QUIET
        NO_DEFAULT_PATH)
else()
    # If local lookup is enabled, try to look for packages in old-fashioned module mode and then config modes 
    
    message(STATUS "Local search of component @PACKAGE_NAME@ enabled")
    # Remove all paths resolving to this one here so that recursive calls wont search here again
    SET(_MODPATHCOPY ${CMAKE_MODULE_PATH})
    SET(_READDME )
    foreach(_ENTRY ${_MODPATHCOPY})
        #message(STATUS "Test: ${_ENTRY} MATCHES .*/CMakeFindModuleWrappers(/)?$")
        if(_ENTRY MATCHES ".*/CMakeFindModuleWrappers(/)?$")
            #message(STATUS "Test positive")
            LIST(REMOVE_ITEM CMAKE_MODULE_PATH ${_ENTRY})
            LIST(APPEND _READDME ${_ENTRY})
        endif()
    endforeach()
    
    # Make "native" call to find_package in MODULE mode first
    message(STATUS "Trying to find @PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} in MODULE mode")
    #message(STATUS "(CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH})")
    
    # Temporarily disable the required flag (if set from outside)
    SET(_PKG_REQ_OLD ${@PACKAGE_NAME@_FIND_REQUIRED})
    UNSET(@PACKAGE_NAME@_FIND_REQUIRED)
    
    # Remove CMAKE_INSTALL_PREFIX from CMAKE_SYSTEM_PREFIX_PATH - we dont want the module search to "accidentally"
    # discover the packages in our install directory, collect libraries and then re-turn them into targets (redundant round-trip)
    LIST(REMOVE_ITEM CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
    
    # Actual MODULE mode find call
    find_package(@PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} MODULE QUIET)
    
    # Restore stuff
    SET(@PACKAGE_NAME@_FIND_REQUIRED ${_PKG_REQ_OLD})
    LIST(APPEND CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
    
    if (@PACKAGE_NAME@_FOUND)
        message(STATUS "Found package @PACKAGE_NAME@: ${@PACKAGE_NAME@_LIBRARIES}")
        SET(INCS )
        foreach(DIRSUFF _INCLUDE_DIRS _INCLUDES _INCLUDE_PATH _INCLUDE_DIR)
            #message(STATUS "Trying @PACKAGE_NAME@${DIRSUFF}..")
            if (DEFINED @PACKAGE_NAME@${DIRSUFF})
                LIST(APPEND INCS ${@PACKAGE_NAME@${DIRSUFF}})
            endif()
        endforeach()
        
        MODULE_TO_TARGETS("${@PACKAGE_NAME@_LIBRARIES}" "${INCS}")
    else()
        message(STATUS "Trying to find @PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} in CONFIG mode")
        # First look outside the prefix path
        find_package(@PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)
        
        # If not found, look also at the prefix path
        if (NOT @PACKAGE_NAME@_FOUND)
        
            find_package(@PACKAGE_NAME@ ${@PACKAGE_NAME@_FIND_VERSION} CONFIG
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

if (@PACKAGE_NAME@_FIND_REQUIRED AND NOT @PACKAGE_NAME@_FOUND)
    message(FATAL_ERROR "Could not find @PACKAGE_NAME@ with either MODULE or CONFIG mode.\nCMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
endif()