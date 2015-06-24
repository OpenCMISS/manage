set(EXPORT_VARS 
    CMAKE_C_COMPILER CMAKE_CXX_COMPILER CMAKE_Fortran_COMPILER
    CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_Fortran_FLAGS
    CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE CMAKE_Fortran_FLAGS_RELEASE
    CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG CMAKE_Fortran_FLAGS_DEBUG
    MPI_C_COMPILER MPI_CXX_COMPILER MPI_Fortran_COMPILER
    MPI MPI_HOME MPI_BUILD_TYPE
    FORTRAN_MANGLING BUILD_SHARED_LIBS
    CMAKE_POSITION_INDEPENDENT_CODE
    OPENCMISS_PREFIX_PATH
    OCM_USE_MT OCM_SYSTEM_MPI
    OPENCMISS_COMPONENTS BLA_VENDOR
    OPENCMISS_CMAKE_MIN_VERSION
    CMAKE_COMMAND)
# Add the build type if on single-config platform
if (DEFINED CMAKE_BUILD_TYPE AND NOT "" STREQUAL CMAKE_BUILD_TYPE)
    set(OPENCMISS_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    list(APPEND EXPORT_VARS OPENCMISS_BUILD_TYPE)
endif() 
foreach(OCM_COMP ${OPENCMISS_COMPONENTS})
    list(APPEND EXPORT_VARS OCM_USE_${OCM_COMP} OCM_SYSTEM_${OCM_COMP})
    # Export the "correct" cased names for components as well (we have solely uppercase names,
    # but some packages have case-sensitive names like LibXml2 :-(
    if (${OCM_COMP}_CASENAME)
        list(APPEND EXPORT_VARS ${OCM_COMP}_CASENAME)
    endif()
    if (${OCM_COMP}_VERSION)
        list(APPEND EXPORT_VARS ${OCM_COMP}_VERSION)
    endif()
endforeach()

# OpenCMISS find modules - wrapper
set(OPENCMISS_MODULE_PATH
    ${OPENCMISS_FINDMODULE_WRAPPER_DIR}
    ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSExtraFindModules)
list(APPEND EXPORT_VARS OPENCMISS_MODULE_PATH)

set(CFILE ${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSBuildContext.cmake)
message(STATUS "Exporting OpenCMISS build context to ${CFILE}")
file(WRITE ${CFILE} "#Exported OpenCMISS configuration\r\n")
foreach(VARNAME ${EXPORT_VARS})
    if (DEFINED ${VARNAME})
        # Flags need to be in quotes
        if (VARNAME MATCHES "^CMAKE_.*_FLAGS.*")
            file(APPEND ${CFILE} "set(${VARNAME} \"${${VARNAME}}\")\r\n")
        else()
            file(APPEND ${CFILE} "set(${VARNAME} ${${VARNAME}})\r\n")
        endif()
    endif()    
endforeach()
unset(EXPORT_VARS)
unset(CFILE)