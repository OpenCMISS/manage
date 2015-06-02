set(EXPORT_VARS 
    CMAKE_C_COMPILER CMAKE_CXX_COMPILER CMAKE_Fortran_COMPILER
    CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_Fortran_FLAGS
    CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE CMAKE_Fortran_FLAGS_RELEASE
    CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG CMAKE_Fortran_FLAGS_DEBUG
    MPI_C_COMPILER MPI_CXX_COMPILER MPI_Fortran_COMPILER
    MPI MPI_HOME
    FORTRAN_MANGLING BUILD_SHARED_LIBS
    CMAKE_POSITION_INDEPENDENT_CODE
    OPENCMISS_PREFIX_PATH
    OCM_USE_MT OCM_SYSTEM_MPI
    OPENCMISS_TARGETS OPENCMISS_COMPONENTS)
# Add the build type if on single-config platform
if (DEFINED CMAKE_BUILD_TYPE AND NOT "" STREQUAL CMAKE_BUILD_TYPE)
    list(APPEND EXPORT_VARS CMAKE_BUILD_TYPE)
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
set(OPENCMISS_TARGETS )
foreach(OCM_COMP ${PACKAGES_WITH_TARGETS})
    if (OCM_USE_${OCM_COMP})
        list(APPEND OPENCMISS_TARGETS ${${OCM_COMP}_TARGETS})
    endif()
endforeach()

# OpenCMISS modules - wrapper and FindOpenCMISS.cmake
set(OPENCMISS_MODULE_PATH ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/cmake/modules)
list(APPEND EXPORT_VARS OPENCMISS_MODULE_PATH)

set(CFILE ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}/OpenCMISSBuildContext.cmake)
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

# Second part - copy the FindModule files so that the installation folder is self-contained
message(STATUS "Exporting OpenCMISS wrapper module files to ${OPENCMISS_MODULE_PATH}")
file(COPY ${OPENCMISS_MANAGE_DIR}/CMakeModules/FindOpenCMISS.cmake
    DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/cmake/modules)
file(COPY ${OPENCMISS_MANAGE_DIR}/CMakeFindModuleWrappers/ 
    DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/cmake/modules
    PATTERN FindXXX.cmake EXCLUDE)
    
# Third part - export an INTERFACE target opencmiss
#add_library(opencmiss INTERFACE)
#target_link_libraries(opencmiss INTERFACE ${OPENCMISS_TARGETS})
#set_target_properties(opencmiss PROPERTIES
#  INTERFACE_LINK_LIBRARIES "${OPENCMISS_TARGETS}"
#)
#install(TARGETS opencmiss EXPORT opencmiss-config)
#install(EXPORT opencmiss-config DESTINATION cmake)