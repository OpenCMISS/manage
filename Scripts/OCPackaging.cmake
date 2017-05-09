##
# OpenCMISS packaging
# ===================
#
# End user
# --------
#
# Binaries only: Neon, Iron, Zinc binaries/libraries
#
# User SDK
# --------
# 
# - No Neon
# - Iron / Zinc binaries with Python/C bindings
# - CMake config files
# - maybe debug libraries as well?
#
# Developer SDK
# -------------
# 
# - Manage repo
# - No Neon
# - Zinc/iron sources - ideally git repositories?
# - Static libraries for all dependencies
# - Header files
# - CMake config files
# - Option for Debug libraries? 
#

# List directories in "${CMAKE_CURRENT_BINARY_DIR}/config(s)" that contain a build_config.stamp file.
set(CONFIG_BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}/config${PLURAL_S}")

if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(_CMAKE_MODULES_BUILD_ELEM release)
endif ()

# This is where additional packaging files are located
set(OC_PACKAGE_FILES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Packaging")
# Base directory for produced packages - you can specify your own one
set(OC_PACKAGE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/packaging" CACHE PATH "Base directory for produced packages")
file(MAKE_DIRECTORY "${OC_PACKAGE_ROOT}")

function(DIRECTORY_LIST result curdir)
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if (IS_DIRECTORY ${curdir}/${child})
            list(APPEND dirlist ${child})
        endif ()
    endforeach()
    set(${result} ${dirlist} PARENT_SCOPE)
endfunction()

macro(CREATE_PACKAGING_TARGET)    
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/Templates/CPackProject.template.cmake"
        "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/source/CMakeLists.txt"
        @ONLY
    )
    file(MAKE_DIRECTORY "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/build")
    add_custom_target(package_${PACKAGE_TYPE}
        COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" -DPACKAGING_MODULE_PATH="${CMAKE_CURRENT_SOURCE_DIR}/Packaging" -DCONFIG_BASE_DIR="${CONFIG_BASE_DIR}" -DCMAKE_MODULES_BINARY_DIR="${OPENCMISS_CMAKE_MODULES_BINARY_DIR}/${_CMAKE_MODULES_BUILD_ELEM}" -DOPENCMISS_RELEASE=${OPENCMISS_RELEASE} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} ../source
        COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG> --target package
        WORKING_DIRECTORY "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/build"
    )
    set_target_properties(package_${PACKAGE_TYPE} PROPERTIES FOLDER "Packaging")
endmacro()

#set(PACKAGE_NAME "OpenCMISS Libraries")
#set(PACKAGE_TYPE "opencmisslibs")
#set(PACKAGE_REGISTRY_KEY "OpenCMISS")
#set(PACKAGE_NAME_BASE "OpenCMISS_Libraries_${OpenCMISSLibs_VERSION}")
#set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS Libraries Summary")

#CREATE_PACKAGING_TARGET()

set(PACKAGE_NAME "OpenCMISS Libraries SDK")
set(PACKAGE_TYPE "sdk")
set(PACKAGE_TYPE_NAME "SDK")
#set(PACKAGE_REGISTRY_KEY "OpenCMISSLibsUserSDK")
set(PACKAGE_NAME_BASE "OpenCMISS-Libraries")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS Libraries SDK Summary")

CREATE_PACKAGING_TARGET()

#set(PACKAGE_NAME "OpenCMISS Libraries Developer SDK")
#set(PACKAGE_TYPE "developersdk")
#set(PACKAGE_REGISTRY_KEY "OpenCMISSLibsDeveloperSDK")
#set(PACKAGE_NAME_BASE "OpenCMISS_Libraries_${OpenCMISSLibs_VERSION}_DeveloperSDK")
#set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS Libraries Developer SDK Summary")

#CREATE_PACKAGING_TARGET()
