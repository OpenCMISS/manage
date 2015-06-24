# Provides the necessary logic to find an OpenCMISS installation.
# Does not yet listen to "REQUIRED" or "QUIET" modifiers but throws an error if anything is missing.
#
# Provides the target "opencmiss" that can be consumed like
# target_link_libraries(mytarget [PRIVATE|PUBLIC] opencmiss)
#
# Developer note:
# This script essentially defines an INTERFACE target opencmiss which is
# then poulated with all the top level libraries configured in OpenCMISS.

# Find the build context (normally either in same location as this file or at OPENCMISS_INSTALL_DIR)
string(TOLOWER "${CMAKE_BUILD_TYPE}" _BUILDTYPE)
get_filename_component(_HERE ${CMAKE_CURRENT_LIST_FILE} PATH)
find_file(OPENCMISS_BUILD_CONTEXT OpenCMISSBuildContext.cmake
    HINTS ${OPENCMISS_INSTALL_DIR}
        ${CMAKE_MODULE_PATH}
        ${OPENCMISS_INSTALL_DIR}/${_BUILDTYPE} 
        ${OPENCMISS_INSTALL_DIR}/release 
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/release
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/debug
        ${_HERE} 
    ENV OPENCMISS_INSTALL_DIR
)
set(OPENCMISS_FOUND NO)
if (OPENCMISS_BUILD_CONTEXT)
    
    # Include the build context
    include(${OPENCMISS_BUILD_CONTEXT})
    
    message(STATUS "Using OpenCMISS-${OPENCMISS_BUILD_TYPE} installation at ${OPENCMISS_INSTALL_DIR}")
    
    # MPI setup
    set(HAVE_MPI_WRAPPER NO)
    foreach(lang C CXX Fortran)
        if (MPI_${lang}_COMPILER)
            if (EXISTS ${MPI_${lang}_COMPILER})
                set(CMAKE_${lang}_COMPILER ${MPI_${lang}_COMPILER})
                set(HAVE_MPI_WRAPPER YES)
            else()
                message(FATAL_ERROR "The MPI compiler ${MPI_${lang}_COMPILER} could not be found.")
            endif()
        endif() 
    endforeach()
    if (NOT HAVE_MPI_WRAPPER)
        find_package(MPI REQUIRED)
        include_directories(${MPI_C_INCLUDE_PATH} ${MPI_CXX_INCLUDE_PATH} ${MPI_Fortran_INCLUDE_PATH})
    endif()
    
    # TODO: Maybe set mpi compiler wrappers here if used
    
    macro(OPENCMISS_IMPORT)
        message(STATUS "--")
        message(STATUS "Initializing OpenCMISS environment...")
        
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
        message(STATUS "Initializing OpenCMISS environment... success")
        message(STATUS "--")
    endmacro()
    
    #get_target_property(ocd opencmiss INTERFACE_COMPILE_DEFINITIONS)
    #get_target_property(oid opencmiss INTERFACE_INCLUDE_DIRECTORIES)
    #get_target_property(oil opencmiss INTERFACE_LINK_LIBRARIES)
    #message(STATUS "opencmiss target config:\nINTERFACE_COMPILE_DEFINITIONS=${ocd}\nINTERFACE_INCLUDE_DIRECTORIES=${oid}\nINTERFACE_LINK_LIBRARIES=${oil}")
    
    set(OPENCMISS_FOUND YES)
else()
    message(FATAL_ERROR "Could not find OpenCMISS. Missing OpenCMISSBuildContext.cmake (HINTS: ${OPENCMISS_INSTALL_DIR})")
endif()
