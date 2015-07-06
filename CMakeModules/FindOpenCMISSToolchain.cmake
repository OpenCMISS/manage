# Provides the necessary logic to use the same toolchain that also built OpenCMISS.
# This module is intended to be included BEFORE any project calls, as those fix the compilers
# and a later change is not possible anymore.
#
# To import the OpenCMISS configuration and libraries, use the FindOpenCMISS module.

# Find the build context (normally either in same location as this file or at OPENCMISS_INSTALL_DIR)
string(TOLOWER "${CMAKE_BUILD_TYPE}" _BUILDTYPE)
get_filename_component(_HERE ${CMAKE_CURRENT_LIST_FILE} PATH)
find_file(OPENCMISS_TC_INFO OpenCMISSToolchainInfo.cmake
    HINTS ${OPENCMISS_INSTALL_DIR}
        ${CMAKE_MODULE_PATH}
        ${OPENCMISS_INSTALL_DIR}/${_BUILDTYPE} 
        ${OPENCMISS_INSTALL_DIR}/release 
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/release
        ${CMAKE_CURRENT_SOURCE_DIR}/../install/debug
        ${_HERE} 
    ENV OPENCMISS_INSTALL_DIR
)
set(OPENCMISSTOOLCHAIN_FOUND NO)
if (OPENCMISS_TC_INFO)
    
    # Include the toolchain info
    # This directly sets the CMAKE_XXXX compilers/flags etc as exported to the file.
    include(${OPENCMISS_TC_INFO})
    
    message(STATUS "Using OpenCMISS-${OPENCMISS_BUILD_TYPE} toolchain info at ${OPENCMISS_INSTALL_DIR}")
    
    # Setup
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
    # Modern MPI implementations provide wrappers that avoid setting libs/incs/flags manually.
    # However, e.g. on windows this is not yet provided, so we need manual settings here. 
    if (NOT HAVE_MPI_WRAPPER)
        # Instead of calling FindMPI again, we use the exported config from the OpenCMISS build environment;
        # this find_package call is supposed to be executed BEFORE any project command is issued; FindMPI however
        # may not be working in future versions if issued before any project command (which is the "normal" cmake case)
        foreach(lang C CXX Fortran)
            if (MPI_${lang}_INCLUDE_PATH)
                include_directories(${MPI_${lang}_INCLUDE_PATH})
            endif()
            if (MPI_${lang}_INCLUDE_PATH)
                link_libraries(MPI_${lang}_LIBRARIES)
            endif()
            if (MPI_${lang}_COMPILE_FLAGS)
                set(CMAKE_${lang}_FLAGS "${CMAKE_${lang}_FLAGS} ${MPI_${lang}_COMPILE_FLAGS}")
            endif()
        endforeach()
    endif()
    
    set(OPENCMISSTOOLCHAIN_FOUND YES)
else()
    message(FATAL_ERROR "Could not find OpenCMISS toolchain. Missing OpenCMISSToolchainInfo.cmake (HINTS: ${OPENCMISS_INSTALL_DIR})")
endif()
