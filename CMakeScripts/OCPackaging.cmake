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

# This is where additional packaging files are located
set(OC_PACKAGE_FILES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Packaging")
# Base directory for produced packages
set(OC_PACKAGE_ROOT "${CMAKE_CURRENT_BINARY_DIR}/packaging")
file(MAKE_DIRECTORY "${OC_PACKAGE_ROOT}")


set(PACKAGE_ARCH "${MPI}_${CMAKE_SYSTEM_NAME}_${MACHINE}")
set(PACKAGE_ARCH_DESC "${MPI} / ${CMAKE_SYSTEM_NAME} (${MACHINE}bit)")

macro(CREATE_PACKAGING_TARGET)    
    configure_file(
        "${OPENCMISS_MANAGE_DIR}/Templates/CPackProject.template.cmake"
        "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/source/CMakeLists.txt"
        @ONLY
    )
    file(MAKE_DIRECTORY "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/build")
    add_custom_target(package_${PACKAGE_TYPE}
        COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} ../source
        COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG> --target package
        WORKING_DIRECTORY "${OC_PACKAGE_ROOT}/${PACKAGE_TYPE}/build"
    )
    set_target_properties(package_${PACKAGE_TYPE} PROPERTIES FOLDER "Packaging")
endmacro()

set(PACKAGE_NAME "OpenCMISS")
set(PACKAGE_TYPE "opencmiss")
#set(PACKAGE_REGISTRY_KEY "OpenCMISS")
set(PACKAGE_NAME_BASE "OpenCMISS_${OpenCMISS_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS Summary")
set(INSTALL_QUADS 
    "${IRON_BINARY_DIR}" "Iron Runtime" Runtime "/${ARCHITECTURE_PATH_MPI}"
    "${IRON_BINARY_DIR}" "Iron C bindings" CBindings "/${ARCHITECTURE_PATH_MPI}"
    "${IRON_BINARY_DIR}" "Iron Python bindings" PythonBindings "/${ARCHITECTURE_PATH_MPI}/iron"
    "${ZINC_BINARY_DIR}" "Zinc Runtime" Runtime "/${ARCHITECTURE_PATH_MPI}"
    "${ZINC_BINARY_DIR}" "Zinc Python bindings" PythonBindings "/${ARCHITECTURE_PATH_MPI}/zinc"
    "${PROJECT_BINARY_DIR}" "OpenCMISS Runtime files" Runtime /
)
CREATE_PACKAGING_TARGET()

set(PACKAGE_NAME "OpenCMISS User SDK")
set(PACKAGE_TYPE "usersdk")
#set(PACKAGE_REGISTRY_KEY "OpenCMISSUserSDK")
set(PACKAGE_NAME_BASE "OpenCMISS_${OpenCMISS_VERSION}_UserSDK")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS User SDK Summary")
list(APPEND INSTALL_QUADS 
    "${IRON_BINARY_DIR}" "Iron Development" Development "/${ARCHITECTURE_PATH_MPI}"
    "${ZINC_BINARY_DIR}" "Zinc Development" Development "/${ARCHITECTURE_PATH_MPI}"
    "${PROJECT_BINARY_DIR}" "OpenCMISS Development" Development /
)
CREATE_PACKAGING_TARGET()

set(PACKAGE_NAME "OpenCMISS Developer SDK")
set(PACKAGE_TYPE "developersdk")
#set(PACKAGE_REGISTRY_KEY "OpenCMISSDeveloperSDK")
set(PACKAGE_NAME_BASE "OpenCMISS_${OpenCMISS_VERSION}_DeveloperSDK")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "OpenCMISS Developer SDK Summary")
set(INSTALL_QUADS )
foreach(COMP ${_OC_SELECTED_COMPONENTS})
    list(APPEND INSTALL_QUADS "${${COMP}_BINARY_DIR}" ${COMP} Development /)
endforeach()
#CREATE_PACKAGING_TARGET()
