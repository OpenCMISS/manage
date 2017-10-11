# Need to have function name templates to have the correct package info at call time!
# Took some time to figure this quiet function re-definition stuff out..
function(my_stupid_package_dependent_message_function_mpi MSG)
    message(STATUS "FindMPI wrapper: ${MSG}")
endfunction()
function(my_stupid_package_dependent_message_function_debug_mpi MSG)
    #message(STATUS "DEBUG FindMPI wrapper: ${MSG}")
endfunction()

my_stupid_package_dependent_message_function_debug_mpi("Entering script. CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}, _IMPORT_PREFIX=${_IMPORT_PREFIX}")

# The default way is to look for components in the current PREFIX_PATH, e.g. own build components.
# If the OC_SYSTEM_MPI flag is set for a package, the MODULE and CONFIG modes are tried outside the PREFIX PATH first.
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

#=============================================================================
# Convenience link targets
#
# This function creates imported targets mpi-$lang and an interface target mpi
# to be linked against if no compiler wrappers are already used as project compilers
function(create_mpi_target lang)
    if (NOT TARGET mpi)
        add_library(mpi UNKNOWN IMPORTED)
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
          INTERFACE_LINK_LIBRARIES "${MPI_${lang}_LINK_FLAGS} ${MPI_${lang}_LIBRARIES}"
          INTERFACE_COMPILE_OPTIONS "${MPI_${lang}_COMPILE_FLAGS}"
          IMPORTED_LINK_INTERFACE_LANGUAGES "${lang}"
        )
        my_stupid_package_dependent_message_function_debug_mpi("Creating imported target '${target}' with properties
          IMPORTED_LOCATION \"${FIRSTLIB}\"
          INTERFACE_INCLUDE_DIRECTORIES \"${MPI_${lang}_INCLUDE_PATH}\"
          INTERFACE_LINK_LIBRARIES \"${MPI_${lang}_LINK_FLAGS} ${MPI_${lang}_LIBRARIES}\"
          INTERFACE_COMPILE_OPTIONS \"${MPI_${lang}_COMPILE_FLAGS}\"
          IMPORTED_LINK_INTERFACE_LANGUAGES \"${lang}\"
        )")
        set_property(TARGET mpi APPEND PROPERTY INTERFACE_LINK_LIBRARIES ${target})
    endif()
endfunction()

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

if (NOT MPI_FOUND)
    my_stupid_package_dependent_message_function_mpi("Trying to find version ${MPI_FIND_VERSION} on system in CONFIG mode")

    # First look outside the prefix path
    my_stupid_package_dependent_message_function_debug_mpi("Calling find_package(MPI ${MPI_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)")
    find_package(MPI ${MPI_FIND_VERSION} CONFIG QUIET NO_CMAKE_PATH)

    # If not found, look also at the prefix path
    if (MPI_FOUND)
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
            my_stupid_package_dependent_message_function_mpi("Found at ${MPI_DIR} in CONFIG mode")
        endif()
    endif()
endif()

if (MPI_FOUND)
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
endif ()

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
