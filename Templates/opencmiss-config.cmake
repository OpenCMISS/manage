# Provides the necessary logic to find an OpenCMISS installation.
#
# Provides the target "opencmiss" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the top level libraries configured in OpenCMISS.

# Make sure we have a sufficient cmake version before doing anything else
cmake_minimum_required(VERSION @OPENCMISS_CMAKE_MIN_VERSION@ FATAL_ERROR)

# Compute the installation prefix relative to this file. It might be a mounted location or whatever.
get_filename_component(_OPENCMISS_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)

#############################################################################
# Helper functions
# Debug verbose helper
function(messaged TEXT)
    #message(STATUS "OpenCMISS (${_OPENCMISS_IMPORT_PREFIX}/opencmiss-config.cmake): ${TEXT}")
endfunction()
function(messageo TEXT)
    message(STATUS "OpenCMISS: ${TEXT}")
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
# Initialize defaults - currently taken from latest OpenCMISS build (this file is replaced for each arch)
if (MPI)
    string(TOLOWER ${MPI} MPI)
else()
    set(MPI @OC_DEFAULT_MPI@)
    messageo("No MPI specified. Attempting to use OpenCMISS default '${MPI}'")
endif()
if (DEFINED MPI_BUILD_TYPE)
    string(TOUPPER "${MPI_BUILD_TYPE}" MPI_BUILD_TYPE)
else()
    set(MPI_BUILD_TYPE @OC_DEFAULT_MPI_BUILD_TYPE@)
    messageo("No MPI_BUILD_TYPE specified. Attempting to use OpenCMISS default MPI build type '@OC_DEFAULT_MPI_BUILD_TYPE@'")
endif()
set(BLA_VENDOR @BLA_VENDOR@)
set(SUPPORT_EMAIL @OC_INSTALL_SUPPORT_EMAIL@)
# See also CMAKE_HAVE_MULTICONFIG_ENV variable in OpenCMISSConfig.cmake
if (MSVC)
    set(CMAKE_HAVE_MULTICONFIG_ENV TRUE)
endif()

# Set the build type to OpenCMISS default if not explicitly given (and single-config env)
if (NOT CMAKE_HAVE_MULTICONFIG_ENV AND (CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT OR NOT CMAKE_BUILD_TYPE))
    set(CMAKE_BUILD_TYPE @CMAKE_BUILD_TYPE@)
    messageo("No build type specified. Using OpenCMISS default type @CMAKE_BUILD_TYPE@")
endif()

# Append the OpenCMISS module path to the current path
set(OPENCMISS_MODULE_PATH @OPENCMISS_MODULE_PATH_EXPORT@)
toAbsolutePaths(OPENCMISS_MODULE_PATH)
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})

#############################################################################
# Assemble architecture-path dependent search locations
set(ARCHPATH .)
if (@OC_USE_ARCHITECTURE_PATH@)
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
# No build-type dependent installation subfolders for multiconfig installations
if (CMAKE_HAVE_MULTICONFIG_ENV)
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
    if (@OC_USE_ARCHITECTURE_PATH@)
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
# Add the opencmiss library (INTERFACE type is new since 3.0)
add_library(opencmiss INTERFACE)

# Avoid cases where people write Iron/iron/IRON 
set(_TMP)
foreach(_ENTRY ${OpenCMISS_FIND_COMPONENTS})
    string(TOLOWER ${_ENTRY} _ENTRY)
    list(APPEND _TMP ${_ENTRY})
endforeach()
set(OpenCMISS_FIND_COMPONENTS ${_TMP})
unset(_TMP)
unset(_ENTRY)

if(iron IN_LIST OpenCMISS_FIND_COMPONENTS)
    # Add top level libraries of OpenCMISS framework if configured
    message(STATUS "Looking for OpenCMISS-Iron ...")
    find_package(IRON ${IRON_VERSION} QUIET)
    if (IRON_FOUND)
        target_link_libraries(opencmiss INTERFACE iron)
        
        # Add the C bindings target if built
        if (TARGET iron_c)
            target_link_libraries(opencmiss INTERFACE iron_c)
        endif()
        
        ###########################################################################
        # This calls the FindMPI in the OpenCMISSExtraFindPackages folder, which
        # respects the MPI settings exported in the OpenCMISS context
        # OPENCMISS_MPI_VERSION is set there, too
        find_package(MPI ${OPENCMISS_MPI_VERSION} REQUIRED)
        # Convenience: linking against opencmiss will automatically import the correct MPI settings here.
        # See FindMPI.cmake for declaration of 'mpi' target
        target_link_libraries(opencmiss INTERFACE mpi)
        
        # On some platforms (windows), we do not have the mpi.mod file or it could not be compatible for inclusion
        # This variable is set by the FindMPI.cmake module in OPENCMISS_INSTALL_DIR/cmake/OpenCMISSExtraFindModules
        if (NOT MPI_Fortran_MODULE_COMPATIBLE)
            add_definitions(-DNOMPIMOD)
        endif()
        
        message(STATUS "Looking for OpenCMISS-Iron ... Success")
    else()
        message(FATAL_ERROR "OpenCMISS installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Iron")
    endif()
endif()

if(zinc IN_LIST OpenCMISS_FIND_COMPONENTS)
    message(STATUS "Looking for OpenCMISS-Zinc ...")
    find_package(ZINC ${ZINC_VERSION} QUIET)
    if (ZINC_FOUND)
        target_link_libraries(opencmiss INTERFACE zinc)
        message(STATUS "Looking for OpenCMISS-Zinc ... Success")
    else()
        message(FATAL_ERROR "OpenCMISS installation at ${_OPENCMISS_IMPORT_PREFIX} does not contain Zinc")
    endif()
endif()

# Be a tidy kiwi
unset(_INSTALL_PATH)
unset(_BUILDTYPES)
unset(_OPENCMISS_IMPORT_PREFIX)
unset(_SEARCHED)
unset(BUILDTYPE_SUFFIX)

#################################################################################
# Extra functions to use within CMake-enabled OpenCMISS applications and examples

 # Composes a native PATH-compatible variable to use for DLL/SO finding.
# Each extra argument is assumed a path to add. Added in the order specified.
function(get_library_path OUTPUT_VARIABLE)
    if (WIN32)
        set(PSEP "\\;")
        #set(HAVE_MULTICONFIG_ENV YES)
        set(LD_VARNAME "PATH")
    elseif(APPLE)
        set(LD_VARNAME "DYLD_LIBRARY_PATH")
        set(PSEP ":")
    elseif(UNIX)
        set(LD_VARNAME "LD_LIBRARY_PATH")
        set(PSEP ":")
    else()
        message(WARNING "get_library_path not implemented for '${CMAKE_HOST_SYSTEM}'")
    endif()
    # Load system environment - on windows its separated by semicolon, so we need to protect those 
    string(REPLACE ";" "\\;" LD_PATH "$ENV{${LD_VARNAME}}")
    foreach(_PATH ${ARGN})
        # For now: We dont have /Release or /Debug subfolders in any installed/packaged structure.
        #if (HAVE_MULTICONFIG_ENV)
        #    file(TO_NATIVE_PATH "${_PATH}/$<CONFIG>" _PATH)
        #else()
            file(TO_NATIVE_PATH "${_PATH}" _PATH)
        #endif()
        set(LD_PATH "${_PATH}${PSEP}${LD_PATH}")
    endforeach()
    set(${OUTPUT_VARIABLE} "${LD_VARNAME}=${LD_PATH}" PARENT_SCOPE)
endfunction()

# Convenience function to add the currently found OpenCMISS runtime environment to any
# test using OpenCMISS libraries
# Intended use is the OpenCMISS User SDK.
function(add_opencmiss_environment TESTNAME)
    get_library_path(PATH_DEFINITION "${OPENCMISS_INSTALL_DIR_ARCHPATH}/bin")
    messaged("Setting environment for test ${TESTNAME}: ${LD_PATH}")
    # Set up the correct environment for the test
    # See https://cmake.org/pipermail/cmake/2009-May/029464.html
    get_test_property(${TESTNAME} ENVIRONMENT EXISTING_TEST_ENV)
    if (EXISTING_TEST_ENV)
        set_tests_properties(${TESTNAME} PROPERTIES
            ENVIRONMENT "${EXISTING_TEST_ENV};${PATH_DEFINITION}")
    else()
        set_tests_properties(${TESTNAME} PROPERTIES
            ENVIRONMENT "${PATH_DEFINITION}")
    endif()
endfunction()
