# Provides the necessary logic to find an OpenCMISS libraries installation.
#
# Provides the target "opencmisslibs" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmisslibs)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmisslibs which is
# then poulated with all the top level libraries configured in OpenCMISS.

if (NOT TARGET opencmisslibs)
    # Make sure we have a sufficient cmake version before doing anything else
    cmake_minimum_required(VERSION @OPENCMISS_CMAKE_MIN_VERSION@ FATAL_ERROR)

    # Compute the installation prefix relative to this file. It might be a mounted location or whatever.
    get_filename_component(_OPENCMISS_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
    #get_filename_component(_OPENCMISS_IMPORT_PREFIX "${_OPENCMISS_IMPORT_PREFIX}" DIRECTORY)

    #############################################################################
    # Helper functions
    # Debug verbose helper
    function(messaged TEXT)
        #message(STATUS "OpenCMISS Libraries (${_OPENCMISS_IMPORT_PREFIX}/opencmisslibs-config.cmake): ${TEXT}")
    endfunction()
    function(messageo TEXT)
        message(STATUS "OpenCMISS Libraries: ${TEXT}")
    endfunction()
    function(toAbsolutePaths LIST_VARNAME)
        set(RES )
        foreach(entry ${${LIST_VARNAME}})
            get_filename_component(abs_entry "${entry}" ABSOLUTE)
            list(APPEND RES "${abs_entry}")
        endforeach()
        set(${LIST_VARNAME} ${RES} PARENT_SCOPE)
    endfunction()

    set(SUPPORT_EMAIL @OPENCMISS_INSTALLATION_SUPPORT_EMAIL@)

    # Append the OpenCMISS module path to the current module path
    set(OPENCMISS_MODULE_PATH @OPENCMISS_MODULE_PATH_EXPORT@)
    toAbsolutePaths(OPENCMISS_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})

    # Sets OPENCMISS_HAVE_MULTICONFIG_ENV variable
    include(OCMultiConfigEnvironment)

    # Set the build type to OpenCMISS default if not explicitly given (and single-config env)
    #if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV AND (CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT OR NOT CMAKE_BUILD_TYPE))
    #    set(CMAKE_BUILD_TYPE @CMAKE_BUILD_TYPE@)
    #    messageo("No build type specified. Using OpenCMISS default type @CMAKE_BUILD_TYPE@")
    #endif()

    include(OCDetermineMPIFunctions)
    include(OCPreSelectMPI)
    include(OCSelectMPI)
    include(OCPostSelectMPI)

    #############################################################################
    # Assemble architecture-path dependent search locations
    set(ARCHPATH /.)
    set(ARCHPATHNOMPI /.)
    if (@OPENCMISS_USE_ARCHITECTURE_PATH@)
        include(OCArchitecturePathFunctions)
        getArchitecturePath(ARCHPATHNOMPI ARCHPATH)
    endif()

    set(_CONTEXT_PATH "${_OPENCMISS_IMPORT_PREFIX}${ARCHPATHNOMPI}")

    # Include the context settings info
    include(${_CONTEXT_PATH}/context.cmake)

    ###########################################################################
    # Validate
    include(OCToolchainCompilers)
    getToolchain(CURRENT_TOOLCHAIN)
    if (NOT CURRENT_TOOLCHAIN STREQUAL CONTEXT_OPENCMISS_TOOLCHAIN)
        message(FATAL_ERROR "Mismatch between the current context toolchain (${CONTEXT_OPENCMISS_TOOLCHAIN}) and the toolchain in use (${CURRENT_TOOLCHAIN}).")
    endif ()

    # Add the prefix path so the config files can be found
    toAbsolutePaths(CONTEXT_OPENCMISS_PREFIX_PATH_IMPORT)
    list(APPEND CMAKE_PREFIX_PATH ${CONTEXT_OPENCMISS_PREFIX_PATH_IMPORT})
    set(OPENCMISS_MPI_BUILD_TYPE ${CONTEXT_OPENCMISS_MPI_BUILD_TYPE})

    messaged("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")

    ###########################################################################
    # Misc
    # For shared libs (default), use the correct install RPATH to enable binaries to find the shared libs.
    # See http://www.cmake.org/Wiki/CMake_RPATH_handling
    toAbsolutePaths(CONTEXT_OPENCMISS_LIBRARY_PATH_IMPORT)
    set(CMAKE_INSTALL_RPATH ${CONTEXT_OPENCMISS_LIBRARY_PATH_IMPORT})
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    toAbsolutePaths(CONTEXT_OPENCMISS_BINARIES_PATH_IMPORT)
    set(OPENCMISS_BINARIES_PATH ${CONTEXT_OPENCMISS_BINARIES_PATH_IMPORT})

    ###########################################################################
    # Convenience targets
    #
    # Add the opencmisslibs library (INTERFACE type is new since 3.0)
    add_library(opencmisslibs INTERFACE)

    # Avoid cases where people write Iron/iron/IRON 
    set(_TMP)
    foreach(_ENTRY ${OpenCMISSLibs_FIND_COMPONENTS})
        string(TOLOWER ${_ENTRY} _ENTRY)
        list(APPEND _TMP ${_ENTRY})
    endforeach()
    set(OpenCMISSLibs_FIND_COMPONENTS ${_TMP})
    unset(_TMP)
    unset(_ENTRY)

    if(iron IN_LIST OpenCMISSLibs_FIND_COMPONENTS OR NOT OpenCMISSLibs_FIND_COMPONENTS)
        # Add top level libraries of OpenCMISS framework if configured
        # Validate MPI for the found context
        if (NOT OPENCMISS_MPI_IMPLEMENTATION STREQUAL CONTEXT_OPENCMISS_MPI_IMPLEMENTATION)
            message(FATAL_ERROR "Mismatch between the current context MPI (${CONTEXT_OPENCMISS_MPI_IMPLEMENTATION}) and the MPI found (${OPENCMISS_MPI_IMPLEMENTATION}).")
        endif ()
        message(STATUS "Looking for OpenCMISS-Iron ...")
        find_package(IRON ${IRON_VERSION} QUIET)
        if (IRON_FOUND)
            target_link_libraries(opencmisslibs INTERFACE iron)

            # Add the C bindings target if built
            if (TARGET iron_c)
                target_link_libraries(opencmisslibs INTERFACE iron_c)
            endif()

            # On some platforms (windows), we do not have the mpi.mod file or it could not be compatible for inclusion
            # This variable is set by the FindMPI.cmake module in OPENCMISS_INSTALL_DIR/cmake/OpenCMISSExtraFindModules
            if (NOT MPI_Fortran_MODULE_COMPATIBLE)
                add_definitions(-DNOMPIMOD)
            endif()

            message(STATUS "Looking for OpenCMISS-Iron ... Success")
        elseif (OpenCMISSLibs_FIND_REQUIRED)
            message(FATAL_ERROR "OpenCMISS libraries installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Iron")
        else ()
            message(STATUS "Looking for OpenCMISS-Iron ... Not found")
        endif ()
    endif()

    if(zinc IN_LIST OpenCMISSLibs_FIND_COMPONENTS OR NOT OpenCMISSLibs_FIND_COMPONENTS)
        message(STATUS "Looking for OpenCMISS-Zinc ...")
        find_package(ZINC ${ZINC_VERSION} QUIET)
        if (ZINC_FOUND)
            target_link_libraries(opencmisslibs INTERFACE zinc)
            message(STATUS "Looking for OpenCMISS-Zinc ... Success")
        elseif (OpenCMISSLibs_FIND_REQUIRED)
            message(FATAL_ERROR "OpenCMISS libraries installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Zinc")
        else()
            message(STATUS "Looking for OpenCMISS-Zinc ... Not found")
        endif()
    endif()

    # Be a tidy kiwi
    unset(_OPENCMISS_IMPORT_PREFIX)
    unset(_CONTEXT_PATH)
endif ()

