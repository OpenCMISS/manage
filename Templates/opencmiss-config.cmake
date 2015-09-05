# Provides the necessary logic to find an OpenCMISS installation.
#
# Provides the target "opencmiss" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the top level libraries configured in OpenCMISS.

# Compute the installation prefix relative to this file. It might be a mounted location or whatever.
get_filename_component(_OPENCMISS_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)

# Debug verbose helper
function(messaged TEXT)
    #message(STATUS ${TEXT})
endfunction()
function(messageo TEXT)
    message(STATUS "OpenCMISS: ${TEXT}")
endfunction()

# Make sure we have a sufficient cmake version before doing anything else
cmake_minimum_required(VERSION @OPENCMISS_CMAKE_MIN_VERSION@ FATAL_ERROR)

#############################################################################
# Initialize defaults - currently taken from latest OpenCMISS build (this file is replaced for each arch)
if (DEFINED MPI)
    string(TOLOWER ${MPI} MPI)
else()
    set(MPI @OC_DEFAULT_MPI@)
    messageo("No MPI specified. Attempting to use OpenCMISS default '@MPI@'")
endif()
if (DEFINED MPI_BUILD_TYPE)
    string(TOUPPER ${MPI_BUILD_TYPE} MPI_BUILD_TYPE)
else()
    set(MPI_BUILD_TYPE @OC_DEFAULT_MPI_BUILD_TYPE@)
    messageo("No MPI_BUILD_TYPE specified. Attempting to use OpenCMISS default MPI build type '@MPI_BUILD_TYPE@'")
endif()
set(BLA_VENDOR @BLA_VENDOR@)
set(SUPPORT_EMAIL @OC_INSTALL_SUPPORT_EMAIL@)

# Set the build type to OpenCMISS default if not explicitly given 
if (CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT OR NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE @CMAKE_BUILD_TYPE@)
    messageo("No build type specified. Using OpenCMISS default type @CMAKE_BUILD_TYPE@")
endif()

# Append the OpenCMISS module path to the current path
list(APPEND CMAKE_MODULE_PATH @OPENCMISS_MODULE_PATH_EXPORT@)

#############################################################################
# Assemble architecture-path dependent search locations
set(ARCHPATH .)
if (@OCM_USE_ARCHITECTURE_PATH@)
    include(OCArchitecturePath)
    getArchitecturePath(_UNUSED ARCHPATH)
endif()

# This is the order we look for opencmiss installations for a given build type.
# 1. Use OPENCMISS_BUILD_TYPE: This can be explicitly set to use a specific build type of OpenCMISS to link against
# 2. Use the CMAKE_BUILD_TYPE: Match the current build type
# 3. Release: If nothing else is given, use RELEASE
# 4. Debug: In case only the debug variant has been built, fall back to that
if (NOT OPENCMISS_BUILD_TYPE)
    messageo("No OpenCMISS build type specified. Trying to match ${CMAKE_BUILD_TYPE} first.")
endif()
set(_BUILDTYPES ${OPENCMISS_BUILD_TYPE} ${CMAKE_BUILD_TYPE} RELEASE DEBUG)
list(REMOVE_DUPLICATES _BUILDTYPES) # Remove double entries

set(_SEARCHED_PATHS )
set(_FOUND FALSE)
messaged("Checking possible subfolders: ${_BUILDTYPES}")
foreach(BUILDTYPE_SUFFIX ${_BUILDTYPES})
    # Have lowercase paths
    string(TOLOWER ${BUILDTYPE_SUFFIX} BUILDTYPE_SUFFIX_PATH)
    # Full install path
    set(_INSTALL_PATH "${_IMPORT_PREFIX}/${ARCHPATH}/${BUILDTYPE_SUFFIX_PATH}")
    list(APPEND _SEARCHED_PATHS "${_INSTALL_PATH}")
    
    set(OPENCMISS_CONTEXT ${_INSTALL_PATH}/context.cmake)
    if (EXISTS "${OPENCMISS_CONTEXT}")
        messageo("Looking for ${BUILDTYPE_SUFFIX} installation - ${OPENCMISS_CONTEXT} ... success")
        set(_FOUND TRUE)
        break()
    else()
        messageo("Looking for ${BUILDTYPE_SUFFIX} installation - ${OPENCMISS_CONTEXT} ... failed")
    endif()
endforeach()
if (NOT _FOUND)
    if (@OCM_USE_ARCHITECTURE_PATH@)
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
        _recurse(${_IMPORT_PREFIX})
        
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
    message(FATAL_ERROR "Could not find a matching OpenCMISS installation. Please check your compiler, MPI, build type etc. choices!\n${msg}")
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
        message(FATAL_ERROR "Your MPI choice ${MPI} does not match the installed version '${OPENCMISS_MPI}' at ${_INSTALL_PATH}")
    endif()
endif()
messageo("Verifying installation settings ... success")

###########################################################################
# This calls the FindMPI in the OpenCMISSExtraFindPackages folder, which
# respects the MPI settings exported in the OpenCMISS context
# OPENCMISS_MPI_VERSION is set in the OPENCMISS_CONTEXT file
find_package(MPI ${OPENCMISS_MPI_VERSION} REQUIRED)

# Add the prefix path so the config files can be found
list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH_IMPORT})

messaged("CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")

###########################################################################
# Misc

# For shared libs (default), use the correct install RPATH to enable binaries to find the shared libs.
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
# TODO FIXME/CHECKME
set(CMAKE_INSTALL_RPATH ${OPENCMISS_LIBRARY_PATH})
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

###########################################################################
# Add the opencmiss library (INTERFACE type is new since 3.0)
add_library(opencmiss INTERFACE)

# Add top level libraries of OpenCMISS framework if configured
if (OCM_USE_IRON)
    find_package(IRON ${IRON_VERSION} REQUIRED)
    target_link_libraries(opencmiss INTERFACE iron)
endif()
if (OCM_USE_ZINC)
    find_package(ZINC ${ZINC_VERSION} REQUIRED)
    target_link_libraries(opencmiss INTERFACE zinc)
endif()

# Add MPI stuff to the top-level interface library (only if iron is build)
if (OCM_USE_IRON)
    foreach(lang C CXX Fortran)
        if (MPI_${lang}_INCLUDE_PATH)
            target_include_directories(opencmiss INTERFACE ${MPI_${lang}_INCLUDE_PATH})
        endif()
        if (MPI_${lang}_INCLUDE_PATH)
            target_link_libraries(opencmiss INTERFACE ${MPI_${lang}_LIBRARIES})
        endif()
        if (MPI_${lang}_COMPILE_FLAGS)
            set(CMAKE_${lang}_FLAGS "${CMAKE_${lang}_FLAGS} ${MPI_${lang}_COMPILE_FLAGS}")
        endif()
    endforeach()
endif()

#get_target_property(ocd opencmiss INTERFACE_COMPILE_DEFINITIONS)
#get_target_property(oid opencmiss INTERFACE_INCLUDE_DIRECTORIES)
#get_target_property(oil opencmiss INTERFACE_LINK_LIBRARIES)
#message(STATUS "opencmiss target config:\nINTERFACE_COMPILE_DEFINITIONS=${ocd}\nINTERFACE_INCLUDE_DIRECTORIES=${oid}\nINTERFACE_LINK_LIBRARIES=${oil}")

# Be a tidy kiwi
unset(_INSTALL_PATH)
unset(_BUILDTYPES)
unset(_IMPORT_PREFIX)
unset(_SEARCHED)
unset(BUILDTYPE_SUFFIX)
