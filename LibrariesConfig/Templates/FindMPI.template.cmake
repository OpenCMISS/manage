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

# Need to have function name templates to have the correct package info at call time!
# Took some time to figure this quiet function re-definition stuff out..
function(my_stupid_package_dependent_message_function_mpi MSG)
    message(STATUS "FindMPI wrapper: ${MSG}")
endfunction()
function(my_stupid_package_dependent_message_function_debug_mpi MSG)
    #message(STATUS "DEBUG FindMPI wrapper: ${MSG}")
endfunction()

my_stupid_package_dependent_message_function_debug_mpi("Entering script. CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}, _IMPORT_PREFIX=${_IMPORT_PREFIX}")

# Default: Not found
SET(MPI_FOUND NO)
    
# The default way is to look for components in the current PREFIX_PATH, e.g. own build components.
# If the OC_SYSTEM_MPI flag is set for a package, the MODULE and CONFIG modes are tried outside the PREFIX PATH first.
if (NOT OC_SYSTEM_MPI)
     set(OC_SYSTEM_MPI NO) # set it to NO so that we have a value if none is set at all (debug output)
     find_package(MPI ${MPI_FIND_VERSION} CONFIG
        PATHS ${CMAKE_PREFIX_PATH}
        QUIET
        NO_DEFAULT_PATH)
    if (MPI_FOUND)
        set(MPI_FOUND YES)
        my_stupid_package_dependent_message_function_mpi("Found version ${MPI_FIND_VERSION} at ${MPI_DIR} in CONFIG mode")
    endif()
else()
    # If local lookup is enabled, try to look for packages in old-fashioned module mode and then config modes 
    
    my_stupid_package_dependent_message_function_mpi("System search enabled")
    
    # Remove all paths resolving to this one here so that recursive calls wont search here again
    set(_ORIGINAL_CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH})
    get_filename_component(_THIS_DIRECTORY ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
    foreach(_ENTRY ${_ORIGINAL_CMAKE_MODULE_PATH})
        get_filename_component(_ENTRY_ABSOLUTE ${_ENTRY} ABSOLUTE)
        if (_ENTRY_ABSOLUTE STREQUAL _THIS_DIRECTORY)
            list(REMOVE_ITEM CMAKE_MODULE_PATH ${_ENTRY})
        endif()
    endforeach()
    unset(_THIS_DIRECTORY)
    unset(_ENTRY_ABSOLUTE)
    
    # Make "native" call to find_package in MODULE mode first
    my_stupid_package_dependent_message_function_mpi("Trying to find version ${MPI_FIND_VERSION} on system in MODULE mode")
    my_stupid_package_dependent_message_function_debug_mpi("CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}\nCMAKE_SYSTEM_PREFIX_PATH=${CMAKE_SYSTEM_PREFIX_PATH}\nPATH=$ENV{PATH}\nLD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}")
    
    # Temporarily disable the required flag (if set from outside)
    SET(_PKG_REQ_OLD ${MPI_FIND_REQUIRED})
    UNSET(MPI_FIND_REQUIRED)
    
    # Remove CMAKE_INSTALL_PREFIX from CMAKE_SYSTEM_PREFIX_PATH - we dont want the module search to "accidentally"
    # discover the packages in our install directory, collect libraries and then re-turn them into targets (redundant round-trip)
    if (CMAKE_INSTALL_PREFIX AND CMAKE_SYSTEM_PREFIX_PATH)
        list(REMOVE_ITEM CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
        set(_readd YES)
    endif()
    
    # Actual MODULE mode find call
    #message(STATUS "find_package(MPI ${MPI_FIND_VERSION} MODULE QUIET)")
    find_package(MPI ${MPI_FIND_VERSION} MODULE QUIET)
    
    # Restore stuff
    SET(MPI_FIND_REQUIRED ${_PKG_REQ_OLD})
    if (_readd)
        list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
    endif()
    unset(_readd)
    
    # Restore the current module path
    # This needs to be done BEFORE any calls in CONFIG find mode - if the found config has our
    # xxx-config-dependencies, which in turn might be allowed as system lookup, the FindModuleWrapper dir
    # is missing and stuff breaks. Took a while to figure out the problem as you might guess ;-)
    # Scenario discovered on Michael Sprenger's Ubuntu 10 system with 
    # OC_SYSTEM_ZLIB=YES and found, OC_SYSTEM_LIBXML2=ON but not found. This broke the CELLML-build as
    # the wrapper call for LIBXML removed the wrapper dir from the module path, then found libxml2 in config mode,
    # which in turn called find_dependency(ZLIB), which used the native FindZLIB instead of the wrapper first.
    # This problem only was detected because the native zlib library is called "(lib)z", but we link against the 
    # "zlib" target, which is either provided by our own build or by the wrapper that creates it. 
    set(CMAKE_MODULE_PATH ${_ORIGINAL_CMAKE_MODULE_PATH})
    unset(_ORIGINAL_CMAKE_MODULE_PATH)
        
    if (MPI_FOUND)
        # Also set the casename variant as this is checked upon at the end ("newer" version; config mode returns
        # a xXx_FOUND variable that has the same case as used for the call find_package(xXx ..)
#=============================================================================
# Convenience link targets
#
# This function creates imported targets mpi-$lang and an interface target mpi
# to be linked against if no compiler wrappers are already used as project compilers
function(create_mpi_target lang)
    if (NOT TARGET mpi)
        add_library(mpi INTERFACE)
    endif()
    string(TOLOWER ${lang} _lang)
    set(target mpi-${_lang})
    if (MPI_${lang}_LIBRARIES AND NOT TARGET ${target})
        add_library(${target} UNKNOWN IMPORTED)
        # Get first library as "main" imported lib
        list(GET MPI_${lang}_LIBRARIES 0 FIRSTLIB)
        list(REMOVE_AT MPI_${lang}_LIBRARIES 0)

        separate_arguments(MPI_${lang}_COMPILE_FLAGS)
        separate_arguments(MPI_${lang}_LINK_FLAGS)
        set_target_properties(${target} PROPERTIES
          IMPORTED_LOCATION "${FIRSTLIB}"
          INTERFACE_INCLUDE_DIRECTORIES "${MPI_${lang}_INCLUDE_PATH}"
          INTERFACE_LINK_LIBRARIES "${MPI_${lang}_LIBRARIES}"
          INTERFACE_COMPILE_OPTIONS "${MPI_${lang}_COMPILE_FLAGS}"
          LINK_FLAGS "${MPI_${lang}_LINK_FLAGS}"
          IMPORTED_LINK_INTERFACE_LANGUAGES "${lang}"
        )
        messagev("Creating imported target '${target}' with properties
          IMPORTED_LOCATION \"${FIRSTLIB}\"
          INTERFACE_INCLUDE_DIRECTORIES \"${MPI_${lang}_INCLUDE_PATH}\"
          INTERFACE_LINK_LIBRARIES \"${MPI_${lang}_LIBRARIES}\"
          INTERFACE_COMPILE_OPTIONS \"${MPI_${lang}_COMPILE_FLAGS}\"
          LINK_FLAGS \"${MPI_${lang}_LINK_FLAGS}\"
          IMPORTED_LINK_INTERFACE_LANGUAGES \"${lang}\"
        )")
        target_link_libraries(mpi INTERFACE ${target})
    endif()
endfunction()
# Do the actual target creation.
# It is IMPORTANT that the order is with Fortran at first, as the include
# path is different from the one of the other languages (although it contains parts of the others)
# This is a problem of order whenever GNU/Intel compilers and MPI are mixed, as the gfortran mpi.mod file is located
# within the fortran include path.
foreach (lang Fortran C CXX)
    if (CMAKE_${lang}_COMPILER_WORKS)
        create_mpi_target(${lang})
    endif ()
endforeach()
        set(MPI_FOUND YES)
        if (NOT TARGET mpi)
            set(LIBS ${MPI_LIBRARIES})
            my_stupid_package_dependent_message_function_mpi("Found: ${LIBS}")
            
            SET(INCS )
            foreach(DIRSUFF _INCLUDE_DIRS _INCLUDES _INCLUDE_PATH _INCLUDE_DIR)
                if (DEFINED MPI${DIRSUFF})
                    LIST(APPEND INCS ${MPI${DIRSUFF}})
                endif()
            endforeach()
            my_stupid_package_dependent_message_function_debug_mpi("Include directories: ${INCS}")
            
            my_stupid_package_dependent_message_function_debug_mpi("Converting found module to imported targets")
            if (NOT CMAKE_CFG_INTDIR STREQUAL .)
                STRING(TOUPPER ${CMAKE_CFG_INTDIR} CURRENT_BUILD_TYPE)
            elseif(CMAKE_BUILD_TYPE)
                STRING(TOUPPER ${CMAKE_BUILD_TYPE} CURRENT_BUILD_TYPE)
            else()
                SET(CURRENT_BUILD_TYPE NOCONFIG)
            endif()
            my_stupid_package_dependent_message_function_debug_mpi("Current build type: CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -- CURRENT_BUILD_TYPE=${CURRENT_BUILD_TYPE}")
            
            list(GET LIBS 0 _FIRST_LIB)
            add_library(mpi UNKNOWN IMPORTED)
            # Treat apple frameworks separate
            # See http://stackoverflow.com/questions/12547624/cant-link-macos-frameworks-with-cmake
            if(APPLE AND ${_FIRST_LIB} MATCHES ".framework$")
                STRING(REGEX REPLACE ".*/([A-Za-z0-9.]+).framework$" "\\1" FW_NAME ${_FIRST_LIB})
                #message(STATUS "Matched '${FW_NAME}' to ${LIB}")
                SET(_FIRST_LIB "${_FIRST_LIB}/${FW_NAME}")
            endif()
            set_target_properties(mpi PROPERTIES 
                    IMPORTED_LOCATION_${CURRENT_BUILD_TYPE} ${_FIRST_LIB}
                    IMPORTED_CONFIGURATIONS ${CURRENT_BUILD_TYPE}
                    INTERFACE_INCLUDE_DIRECTORIES "${INCS}"
            )
            
            list(REMOVE_AT LIBS 0)
            # Add non-matched libraries as link libraries so nothing gets forgotten
            foreach(LIB ${LIBS})
                my_stupid_package_dependent_message_function_debug_mpi("Adding extra library ${LIB} to link interface")
                append_link_library(mpi ${LIB})
            endforeach()
        else()
            my_stupid_package_dependent_message_function_mpi("Avoiding double import of target 'mpi'")
        endif()
    else()
        my_stupid_package_dependent_message_function_mpi("Trying to find version ${MPI_FIND_VERSION} on system in CONFIG mode")
        
        # First look outside the prefix path
        my_stupid_package_dependent_message_function_debug_mpi("Calling find_package(MPI ${MPI_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)")
        find_package(MPI ${MPI_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)
        
        # If not found, look also at the prefix path
        if (MPI_FOUND)
            set(MPI_FOUND ${MPI_FOUND})
            my_stupid_package_dependent_message_function_mpi("Found at ${MPI_DIR} in CONFIG mode")
        else()
            my_stupid_package_dependent_message_function_mpi("No system package found/available.")
            find_package(MPI ${MPI_FIND_VERSION} CONFIG
                QUIET
                PATHS ${CMAKE_PREFIX_PATH}
                NO_CMAKE_ENVIRONMENT_PATH
                NO_SYSTEM_ENVIRONMENT_PATH
                NO_CMAKE_BUILDS_PATH
                NO_CMAKE_PACKAGE_REGISTRY
                NO_CMAKE_SYSTEM_PATH
                NO_CMAKE_SYSTEM_PACKAGE_REGISTRY
            )
            if (MPI_FOUND)
                set(MPI_FOUND ${MPI_FOUND})
                my_stupid_package_dependent_message_function_mpi("Found at ${MPI_DIR} in CONFIG mode")
            endif()
        endif()
    endif()
endif()

if (MPI_FIND_REQUIRED AND NOT MPI_FOUND)
    message(FATAL_ERROR "OpenCMISS FindModuleWrapper error!\n"
        "Could not find MPI ${MPI_FIND_VERSION} with either MODULE or CONFIG mode.\n"
        "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}\n"
        "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}\n"
        "Allow system MPI: ${OC_SYSTEM_MPI}\n"
        "Please check your OpenCMISSLocalConfig file and ensure to set USE_MPI=YES\n"
        "Alternatively, refer to CMake(Output|Error).log in ${PROJECT_BINARY_DIR}/CMakeFiles\n"
    )
endif()
