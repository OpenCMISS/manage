# Provides the necessary logic to find an OpenCMISS libraries installation.
#
# Provides the target "opencmisslibs" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmisslibs)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmisslibs which is
# then poulated with all the top level libraries configured in OpenCMISS.

if (NOT TARGET opencmissdependencies)
    # Make sure we have a sufficient cmake version before doing anything else
    cmake_minimum_required(VERSION @OPENCMISS_CMAKE_MIN_VERSION@ FATAL_ERROR)

    # Compute the installation prefix relative to this file. It might be a mounted location or whatever.
    get_filename_component(_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
    #get_filename_component(_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX "${_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX}" DIRECTORY)

    #############################################################################
    # Helper functions
    # Debug verbose helper
    function(messaged TEXT)
        #message(STATUS "OpenCMISS Libraries (${_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX}/opencmisslibs-config.cmake): ${TEXT}")
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

    set(_CONTEXT_PATH "${_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX}${ARCHPATHNOMPI}")

    # Include the context settings info
    include(${_CONTEXT_PATH}/context-dependencies.cmake)

    ###########################################################################
    # Validate
    include(OCToolchainCompilers)
    getToolchain(CURRENT_TOOLCHAIN)
    if (NOT CURRENT_TOOLCHAIN STREQUAL CONTEXT_DEPENDENCIES_OPENCMISS_TOOLCHAIN)
        message(FATAL_ERROR "Mismatch between the current context toolchain (${CONTEXT_DEPENDENCIES_OPENCMISS_TOOLCHAIN}) and the toolchain in use (${CURRENT_TOOLCHAIN}).")
    endif ()

    # Add the prefix path so the config files can be found
    toAbsolutePaths(CONTEXT_DEPENDENCIES_OPENCMISS_PREFIX_PATH_IMPORT)
    list(APPEND CMAKE_PREFIX_PATH ${CONTEXT_DEPENDENCIES_OPENCMISS_PREFIX_PATH_IMPORT})
    set(OPENCMISS_MPI_BUILD_TYPE ${CONTEXT_DEPENDENCIES_OPENCMISS_MPI_BUILD_TYPE})

    messaged("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")

    ###########################################################################
    # Misc
    # For shared libs (default), use the correct install RPATH to enable binaries to find the shared libs.
    # See http://www.cmake.org/Wiki/CMake_RPATH_handling
    toAbsolutePaths(CONTEXT_DEPENDENCIES_OPENCMISS_LIBRARY_PATH_IMPORT)
    set(CMAKE_INSTALL_RPATH ${CONTEXT_DEPENDENCIES_OPENCMISS_LIBRARY_PATH_IMPORT})
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    ###########################################################################
    # Convenience targets
    #
    # Add the opencmisslibs library (INTERFACE type is new since 3.0)
    add_library(opencmissdependencies INTERFACE)

    set(_REQUIRED_COMPONENTS @OC_REQUIRED_COMPONENTS@)
    foreach(_component ${_REQUIRED_COMPONENTS})
        message(STATUS "Looking for ${_component} ...")
        find_package(${_component} QUIET)
if(TARGET ${${_component}_TARGETS})
message(STATUS "this component is a target: ${${_component}_TARGETS}")
else()
message(STATUS "this component is *not* a target: ${${_component}_TARGETS}")
endif()
        if (${_component}_FOUND)
            target_link_libraries(opencmissdependencies INTERFACE ${${_component}_TARGETS})
            message(STATUS "Looking for ${_component} ... Success")
        else ()
            message(STATUS "Looking for ${_component} ... Not found")
        endif ()
    endforeach()

    # Be a tidy kiwi
    unset(_OPENCMISS_DEPENDENCIES_IMPORT_PREFIX)
    unset(_CONTEXT_PATH)
endif ()

