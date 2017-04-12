# Provides the necessary logic to find an OpenCMISS libraries installation.
#
# Provides the target "opencmisslibs" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmisslibs)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmisslibs which is
# then poulated with all the top level libraries configured in OpenCMISS.

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

#############################################################################
# Initialize defaults - currently taken from latest OpenCMISS libraries build (this file is replaced for each arch)
if (OPENCMISS_MPI)
    string(TOLOWER ${OPENCMISS_MPI} OPENCMISS_MPI)
else()
    set(OPENCMISS_MPI @OC_DEFAULT_MPI@)
    messageo("No MPI specified. Attempting to use OpenCMISS libraries default '${OPENCMISS_MPI}'")
endif()
if (DEFINED OPENCMISS_MPI_BUILD_TYPE)
    # Don't want an uppercase OPENCMISS_MPI_BUILD_TYPE testing without manipulation for now.
    #string(TOUPPER "${OPENCMISS_MPI_BUILD_TYPE}" OPENCMISS_MPI_BUILD_TYPE)
else()
    set(OPENCMISS_MPI_BUILD_TYPE @OC_DEFAULT_MPI_BUILD_TYPE@)
    messageo("No OPENCMISS_MPI_BUILD_TYPE specified. Attempting to use OpenCMISS libraries default MPI build type '@OC_DEFAULT_MPI_BUILD_TYPE@'")
endif()
set(BLA_VENDOR @BLA_VENDOR@)
set(SUPPORT_EMAIL @OPENCMISS_INSTALLATION_SUPPORT_EMAIL@)

# Append the OpenCMISS module path to the current patd
set(OPENCMISS_MODULE_PATH @OPENCMISS_MODULE_PATH_EXPORT@)
toAbsolutePaths(OPENCMISS_MODULE_PATH)
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})

# Sets OPENCMISS_HAVE_MULTICONFIG_ENV variable
include(OCMultiConfigEnvironment)

# Set the build type to OpenCMISS default if not explicitly given (and single-config env)
if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV AND (CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT OR NOT CMAKE_BUILD_TYPE))
    set(CMAKE_BUILD_TYPE @CMAKE_BUILD_TYPE@)
    messageo("No build type specified. Using OpenCMISS default type @CMAKE_BUILD_TYPE@")
endif()

#############################################################################
# Assemble architecture-path dependent search locations
set(ARCHPATH .)
if (@OPENCMISS_USE_ARCHITECTURE_PATH@)
    include(OCArchitecturePathFunctions)
    getArchitecturePath(_UNUSED ARCHPATH)
endif()

# This is the order we look for opencmiss installations for a given build type.
# 1. Use OPENCMISS_BUILD_TYPE: This can be explicitly set to use a specific build type of OpenCMISS libraries to link against
# 2. Use the CMAKE_BUILD_TYPE: Match the current build type
# 3. Release: If nothing else is given, use RELEASE
# 4. Debug: In case only the debug variant has been built, fall back to that
if (NOT OPENCMISS_BUILD_TYPE)
    messageo("No OpenCMISS libraries build type specified. Trying to match ${CMAKE_BUILD_TYPE} first.")
endif()
# No build-type dependent installation subfolders for multiconfig installations
if (OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(_BUILDTYPES .)
else()
    set(_BUILDTYPES ${OPENCMISS_BUILD_TYPE} ${CMAKE_BUILD_TYPE} RELEASE DEBUG)
    list(REMOVE_DUPLICATES _BUILDTYPES) # Remove double entries
endif()

set(_SEARCHED_PATHS )
set(_FOUND FALSE)
messaged("Checking possible subfolders: ${_BUILDTYPES}")
foreach(BUILDTYPE_SUFFIX ${_BUILDTYPES})
    # Have lowercase paths
    string(TOLOWER ${BUILDTYPE_SUFFIX} BUILDTYPE_SUFFIX_PATH)
    # Full install path
    set(_INSTALL_PATH "${_OPENCMISS_IMPORT_PREFIX}/${ARCHPATH}/${BUILDTYPE_SUFFIX_PATH}")
    list(APPEND _SEARCHED_PATHS "${_INSTALL_PATH}")
    
    set(OPENCMISS_CONTEXT ${_INSTALL_PATH}/context.cmake)
    if (EXISTS "${OPENCMISS_CONTEXT}")
        messageo("Looking for ${BUILDTYPE_SUFFIX} installation - ${OPENCMISS_CONTEXT} ... success")
        set(OPENCMISS_INSTALL_DIR_ARCHPATH "${_INSTALL_PATH}")
        set(_FOUND TRUE)
        break()
    else()
        messageo("Looking for ${BUILDTYPE_SUFFIX} installation - ${OPENCMISS_CONTEXT} ... failed")
    endif()
endforeach()
if (NOT _FOUND)
    if (@OPENCMISS_USE_ARCHITECTURE_PATH@)
        set(POSSIBLE_FOLDERS )
        
        macro(_recurse DIR)
            file(GLOB content RELATIVE ${DIR} ${DIR}/*)
            foreach(entry ${content})
                set(fullentry ${DIR}/${entry})
                if(IS_DIRECTORY ${fullentry} AND NOT ${fullentry} MATCHES ".*/no_mpi/.*")
                    #if (fullentry MATCHES ".*cmake$")
                    if (EXISTS ${fullentry}/cmake)
                        list(APPEND POSSIBLE_FOLDERS ${fullentry}) 
                    else()
                        _recurse(${fullentry})
                    endif()
                endif()
            endforeach()
        endmacro()
        _recurse(${_OPENCMISS_IMPORT_PREFIX})
        
        message(STATUS "Searched in")
        foreach(PATH ${_SEARCHED_PATHS})
            message(STATUS "${PATH}")
        endforeach()
        message(STATUS "Possible locations are")
        foreach(PATH ${POSSIBLE_FOLDERS})
            message(STATUS "${PATH}")
        endforeach()
    endif()
    if (SUPPORT_EMAIL)
        set(msg "Please check your local settings or contact your installation administrator: ${SUPPORT_EMAIL}")
    else()
        set(msg "Please check your local settings. Unfortunately, the remote installation guy did not supply a contact eMail adress\nTrack him down, tell your worries and remind him to put in his eMail!")
    endif()
    message(FATAL_ERROR "Could not find a matching OpenCMISS libraries installation. Please check your compiler, MPI, build type etc. choices!\n${msg}")
endif()

# Include the build info
include(${OPENCMISS_CONTEXT})

###########################################################################
# Validation stuff
messageo("Verifying installation settings ...")
# Use the installed MPI_HOME directory if it exists on this machine - that covers the "all local" case
if (EXISTS "${OPENCMISS_MPI_HOME}")
    set(MPI_HOME "${OPENCMISS_MPI_HOME}")
else()
    # We yet need to validate that we've selected a compatible configuration. This is important at least when
    # the installation does not use an architecture path.
    
    # Validate we've found a matching installation
    if (NOT MPI STREQUAL OPENCMISS_MPI)
        message(FATAL_ERROR "Your MPI type '${MPI}' does not match the installed version '${OPENCMISS_MPI}' at ${_INSTALL_PATH}")
    endif()
endif()
messageo("Verifying installation settings ... success")

# Add the prefix path so the config files can be found
toAbsolutePaths(OPENCMISS_PREFIX_PATH_IMPORT)
list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH_IMPORT})

messaged("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")

###########################################################################
# Misc

# For shared libs (default), use the correct install RPATH to enable binaries to find the shared libs.
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
toAbsolutePaths(OPENCMISS_LIBRARY_PATH_IMPORT)
set(CMAKE_INSTALL_RPATH ${OPENCMISS_LIBRARY_PATH_IMPORT})
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

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

if(iron IN_LIST OpenCMISSLibs_FIND_COMPONENTS)
    # Add top level libraries of OpenCMISS framework if configured
    message(STATUS "Looking for OpenCMISS-Iron ...")
    find_package(IRON ${IRON_VERSION} QUIET)
    if (IRON_FOUND)
        target_link_libraries(opencmisslibs INTERFACE iron)
        
        # Add the C bindings target if built
        if (TARGET iron_c)
            target_link_libraries(opencmisslibs INTERFACE iron_c)
        endif()
        
        ###########################################################################
        # This calls the FindMPI in the OpenCMISS FindModuleWrappers folder, which
        # respects the MPI settings exported in the OpenCMISS context
        # OPENCMISS_MPI_VERSION is set there, too
        find_package(MPI ${OPENCMISS_MPI_VERSION} REQUIRED)
        # Convenience: linking against opencmisslibs will automatically import the correct MPI settings here.
        # See FindMPI.cmake for declaration of 'mpi' target
        target_link_libraries(opencmisslibs INTERFACE mpi)
        
        # On some platforms (windows), we do not have the mpi.mod file or it could not be compatible for inclusion
        # This variable is set by the FindMPI.cmake module in OPENCMISS_INSTALL_DIR/cmake/OpenCMISSExtraFindModules
        if (NOT MPI_Fortran_MODULE_COMPATIBLE)
            add_definitions(-DNOMPIMOD)
        endif()
        
        message(STATUS "Looking for OpenCMISS-Iron ... Success")
    else()
        message(FATAL_ERROR "OpenCMISS libraries installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Iron")
    endif()
endif()

if(zinc IN_LIST OpenCMISSLibs_FIND_COMPONENTS)
    message(STATUS "Looking for OpenCMISS-Zinc ...")
    find_package(ZINC ${ZINC_VERSION} QUIET)
    if (ZINC_FOUND)
        target_link_libraries(opencmisslibs INTERFACE zinc)
        message(STATUS "Looking for OpenCMISS-Zinc ... Success")
    else()
        message(FATAL_ERROR "OpenCMISS libraries installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Zinc")
    endif()
endif()

# Be a tidy kiwi
unset(_INSTALL_PATH)
unset(_BUILDTYPES)
unset(_OPENCMISS_IMPORT_PREFIX)
unset(_SEARCHED)
unset(BUILDTYPE_SUFFIX)

