# Template for packaging projects
# Configured in OCPackaging.cmake in CMakeScripts.

cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)
project("@PACKAGE_NAME@" VERSION @OpenCMISSLibs_VERSION@ LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH ${PACKAGING_MODULE_PATH})

include(OCPackagingFunctions)

set(OC_PACKAGE_FILES_DIR "@OC_PACKAGE_FILES_DIR@")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "@CPACK_PACKAGE_DESCRIPTION_SUMMARY@")

# Include the correct bit size info
set(MACHINE_ARCH 64)
if (CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(MACHINE_ARCH 32)
endif()
# For windows, the NSIS generator seems to need four \. Wild turkey!
if (WIN32)
    set(PSEP "\\\\")
else()
    set(PSEP "/")
endif()

get_package_system_name(_PACKAGE_SYSTEM_NAME)
set(_PACKAGE_VERSION "@OpenCMISSLibs_VERSION@")
if (NOT OPENCMISS_RELEASE)
    string(TIMESTAMP _TIMESTAMP "%Y%m%d%H%M%S" UTC)
    set(_PACKAGE_VERSION "${_PACKAGE_VERSION}.${_TIMESTAMP}")
endif ()

# The website developer versions script relies on this package file name to be written in four parts with '_' between each section.  This
# means that each individual section cannot use the '_' symbol.
set(_PACKAGE_FILE_NAME @PACKAGE_NAME_BASE@_${_PACKAGE_VERSION}_@PACKAGE_TYPE_NAME@_${_PACKAGE_SYSTEM_NAME})
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/CPackRunConfig.cmake)
file(WRITE "${CPACK_PROJECT_CONFIG_FILE}"
#"set(CPACK_PACKAGE_FILE_NAME \"@PACKAGE_NAME_BASE@_@OPENCMISS_MPI_IMPLEMENTATION@_${CMAKE_SYSTEM_NAME}${MACHINE_ARCH}_\${CPACK_BUILD_CONFIG}\")"
"set(CPACK_PACKAGE_FILE_NAME \"${_PACKAGE_FILE_NAME}\")"
)

# NEVER CHANGE THIS AFTER THE FIRST SDK RELEASES.
# The windows registry key is (automatically) constructed using the vendor. 
set(CPACK_PACKAGE_VENDOR "Auckland Bioengineering Institute")

# Avoids a "top-level" folder at the root of zip/tgz packages
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY NO)

set(CPACK_PACKAGE_DESCRIPTION_FILE "${OC_PACKAGE_FILES_DIR}/description_@PACKAGE_TYPE@.txt")
set(CPACK_PACKAGE_ICON "${OC_PACKAGE_FILES_DIR}${PSEP}opencmiss.png")

# Maybe for future use
#set(CPACK_INSTALL_SCRIPT "@OC_PACKAGE_FILES_DIR@/CPackInstallExtras.cmake")
#set(CPACK_INSTALL_COMMANDS "${CMAKE_COMMAND} -E echo \"@@@@@@@@@@@@@@@@@@@@ hello\"")

if (WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    
    # NSIS specific options
    set(CPACK_NSIS_PACKAGE_NAME "@PACKAGE_NAME@ @OpenCMISSLibs_VERSION@")
    set(CPACK_NSIS_DISPLAY_NAME "${CPACK_NSIS_PACKAGE_NAME} (@MPI@, ${MACHINE_ARCH})")
    if(CMAKE_CL_64)
        SET(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
    endif()
    set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "@PACKAGE_NAME@")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "@PACKAGE_NAME@")
    set(CPACK_NSIS_MUI_ICON "${OC_PACKAGE_FILES_DIR}\\\\opencmiss.ico")
    set(CPACK_NSIS_MUI_UNIICON "${OC_PACKAGE_FILES_DIR}\\\\opencmiss.ico")
    set(CPACK_NSIS_MODIFY_PATH "ON" )
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL YES)
    set(CPACK_NSIS_HELP_LINK "http://staging.opencmiss.org/downloads.html")
    set(CPACK_NSIS_URL_INFO_ABOUT "http://www.opencmiss.org")
    set(CPACK_NSIS_CONTACT "Hugh Sorby <h.sorby@auckland.ac.nz>")
    
    #set(CPACK_NSIS_MUI_FINISHPAGE_RUN Neon)
elseif(APPLE)
    set(CPACK_GENERATOR "TGZ")
elseif(UNIX)
    set(CPACK_GENERATOR "TGZ")
endif()

# Put the package output directory on the same level as source and build folders
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../package")


# Here the effective install components of the opencmiss projects are listed and forwarded to CPACK_INSTALL_CMAKE_PROJECTS
#set(INSTALL_QUADS "@INSTALL_QUADS@")
get_install_quads(@PACKAGE_TYPE@ INSTALL_QUADS)
set(CPACK_INSTALL_CMAKE_PROJECTS )
foreach(_ELEM ${INSTALL_QUADS})
    list(APPEND CPACK_INSTALL_CMAKE_PROJECTS ${_ELEM})
endforeach()

# Let the CMake module do the rest for now
include(CPack)
