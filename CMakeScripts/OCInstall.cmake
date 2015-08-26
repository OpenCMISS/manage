########################################################################
# Installation stuff - create & export config files
#
set(OPENCMISS_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
# The build tree uses the folder manage/CMakeModules directly, but the
# installed OpenCMISS wont necessarily have the manage folder and needs to
# be self-contained
set(OPENCMISS_MODULE_PATH
    ${OPENCMISS_FINDMODULE_WRAPPER_DIR}
    ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSExtraFindModules
    ${OPENCMISS_INSTALL_ROOT}/cmake)

# ExportVariables defines OPENCMISS_VARS
include(OCInstallExportVariables)
install(
    FILES ${OPENCMISS_CONTEXT}
    DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI}
)

# Assemble toolchain info
# This file is split into parts so that the tc vars can be easily inserted 
#file(READ ${OPENCMISS_MANAGE_DIR}/Templates/opencmisstoolchain-config_begin.cmake _TMP)
#file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/export/opencmisstoolchain-config.cmake ${_TMP})
#file(READ ${CMAKE_CURRENT_BINARY_DIR}/export/toolchain_vars.cmake _TMP)
#file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/export/opencmisstoolchain-config.cmake ${_TMP})
#file(READ ${OPENCMISS_MANAGE_DIR}/Templates/opencmisstoolchain-config_end.cmake _TMP)
#file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/export/opencmisstoolchain-config.cmake ${_TMP})

###########################################################################################
# Create opencmiss-config

# There's litte to configure yet, but could become more
configure_file(${OPENCMISS_MANAGE_DIR}/Templates/opencmiss-config.cmake
 ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config.cmake @ONLY
)
# Version file
include(CMakePackageConfigHelpers)
WRITE_BASIC_PACKAGE_VERSION_FILE(
    ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config-version.cmake
    COMPATIBILITY AnyNewerVersion
)
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/export/opencmiss-config-version.cmake
    DESTINATION ${OPENCMISS_INSTALL_ROOT}
)

###########################################################################################

# Copy the config files to the non-build-type dependent install location    
#install(
#    FILES ${CMAKE_CURRENT_BINARY_DIR}/export/opencmisstoolchain-config.cmake 
#    DESTINATION ${OPENCMISS_COMPONENTS_INSTALL_PREFIX_MPI_NO_BUILD_TYPE}
#)

# Copy the FindModule files so that the installation folder is self-contained
install(DIRECTORY ${OPENCMISS_MANAGE_DIR}/CMakeModules/
    DESTINATION ${OPENCMISS_INSTALL_ROOT}/cmake/OpenCMISSExtraFindModules
    PATTERN "FindOpenCMISS*.cmake" EXCLUDE) 
install(FILES ${OPENCMISS_MANAGE_DIR}/CMakeScripts/OCArchitecturePath.cmake
    ${OPENCMISS_MANAGE_DIR}/CMakeScripts/OCToolchainCompilers.cmake
    DESTINATION ${OPENCMISS_INSTALL_ROOT}/cmake)