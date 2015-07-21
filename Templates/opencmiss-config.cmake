# Provides the necessary logic to find an OpenCMISS installation.
#
# Provides the target "opencmiss" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the top level libraries configured in OpenCMISS.

######### Find the toolchain info file
# This is the order we look for opencmiss installations for a given build type.
# 1. Use OPENCMISS_BUILD_TYPE: This can be explicitly set to use a specific build type of OpenCMISS to link against
# 2. Use the CMAKE_BUILD_TYPE: Match the current build type
# 3. Release: If nothing else is given, use RELEASE
# 4. Debug: In case only the debug variant has been built, fall back to that
set(_BUILDTYPES ${OPENCMISS_BUILD_TYPE} ${CMAKE_BUILD_TYPE} release debug)
get_filename_component(_HERE ${CMAKE_CURRENT_LIST_FILE} PATH)
set(_SEARCHED )
#message(STATUS "Checking possible subfolders: ${_BUILDTYPES}")
foreach(_SUFFIX ${_BUILDTYPES})
    string(TOLOWER ${_SUFFIX} _SUFFIX)
    set(_INSTALL_PATH "${_HERE}/${_SUFFIX}")
    set(OPENCMISS_VARIABLES ${_INSTALL_PATH}/context.cmake)
    #message(STATUS "Checking suffix ${_SUFFIX} - ${OPENCMISS_VARIABLES}")
    if (EXISTS "${OPENCMISS_VARIABLES}")
        #message(STATUS "Match suffix ${_SUFFIX} - ${OPENCMISS_VARIABLES}")
        set(_FOUND TRUE)
        break()
    endif()
    list(APPEND _SEARCHED "${OPENCMISS_VARIABLES}")
endforeach()
if (NOT _FOUND) 
    message(FATAL_ERROR "Could not find OpenCMISS. Missing context.cmake (Locations: ${_SEARCHED})")
endif()

# Include the build context
include(${OPENCMISS_VARIABLES})

message(STATUS "Using OpenCMISS-${OPENCMISS_BUILD_TYPE} installation at ${_INSTALL_PATH}")

# Make sure we have a sufficient cmake version
cmake_minimum_required(VERSION @OPENCMISS_CMAKE_MIN_VERSION@ FATAL_ERROR)

# Append the OpenCMISS module path to the current path
list(APPEND CMAKE_MODULE_PATH ${OPENCMISS_MODULE_PATH})

# Add the prefix path so the config files can be found
set(CMAKE_PREFIX_PATH ${OPENCMISS_PREFIX_PATH} ${CMAKE_PREFIX_PATH})

#message(STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}\nCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")

# For shared libs, use the correct install RPATH to enable binaries to find the shared libs.
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
if (OPENCMISS_BUILD_SHARED_LIBS)
    set(CMAKE_INSTALL_RPATH ${OPENCMISS_INSTALL_DIR}/lib)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

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

#get_target_property(ocd opencmiss INTERFACE_COMPILE_DEFINITIONS)
#get_target_property(oid opencmiss INTERFACE_INCLUDE_DIRECTORIES)
#get_target_property(oil opencmiss INTERFACE_LINK_LIBRARIES)
#message(STATUS "opencmiss target config:\nINTERFACE_COMPILE_DEFINITIONS=${ocd}\nINTERFACE_INCLUDE_DIRECTORIES=${oid}\nINTERFACE_LINK_LIBRARIES=${oil}")

# Be a tidy kiwi
unset(_INSTALL_PATH)
unset(_BUILDTYPES)
unset(_HERE)
unset(_SEARCHED)
unset(_SUFFIX)
