
# If your cmake is older than 3.4 - goodbye. 
cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

# Ready to start the "build project".
project(OpenCMISS-Manage VERSION 1.3.0 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

mark_as_advanced(CMAKE_INSTALL_PREFIX)

# Set the OpenCMISS libriaries package to the project version.
set(OpenCMISSLibs_MAJOR_VERSION ${PROJECT_VERSION_MAJOR})
set(OpenCMISSLibs_MINOR_VERSION ${PROJECT_VERSION_MINOR})
set(OpenCMISSLibs_PATCH_VERSION ${PROJECT_VERSION_PATCH})
set(OpenCMISSLibs_VERSION ${OpenCMISSLibs_MAJOR_VERSION}.${OpenCMISSLibs_MINOR_VERSION}.${OpenCMISSLibs_PATCH_VERSION})

# This is the support email for general enquiries and support about building opencmiss using the new CMake system.
set(OPENCMISS_BUILD_SUPPORT_EMAIL "users@opencmiss.org")

# Determine if the OpenCMISSInstallationConfig should be considered finalised or not.
get_property(propIsSet CACHE OPENCMISS_INSTALLATION_TYPE PROPERTY TYPE SET)
if (propIsSet)
    get_property(propValue CACHE OPENCMISS_INSTALLATION_TYPE PROPERTY TYPE)
    if (propValue STREQUAL "INTERNAL")
        set(_INSTALLATION_CONFIG_FINALISED TRUE)
    else ()
        set(_INSTALLATION_CONFIG_FINALISED FALSE)
    endif ()
else ()
    set(_INSTALLATION_CONFIG_FINALISED FALSE)
endif ()

if (CLEAR_MPI_HOME)
    unset(MPI_HOME CACHE)
    unset(MPI_HOME_BUILD_TYPE CACHE)
    unset(CLEAR_MPI_HOME CACHE)
endif ()

# OPENCMISS_INSTALLATION_TYPE and OPENCMISS_INDEPENDENT_ROOTS define what variables should be set.  
# If OPENCMISS_INDEPENDENT_ROOTS is FALSE then the root locations may be determined relative
# to this file, otherwise the roots must be defined.  In either case the root directories must exist.
set(OPENCMISS_INSTALLATION_TYPE standard CACHE STRING "Define the type of installation to manage.")
set(INSTALLATION_TYPES standard libraries dependencies)
set_property(CACHE OPENCMISS_INSTALLATION_TYPE PROPERTY STRINGS ${INSTALLATION_TYPES})

set(OPENCMISS_INDEPENDENT_ROOTS FALSE CACHE BOOL "The roots are independently located; libraries, dependendencies, examples.")

#set(OPENCMISS_EXAMPLES FALSE) #  CACHE BOOL "Add in the OpenCMISS examples to this installation.")
# Preliminary set the root variables and module path for the installation type.
if (OPENCMISS_INSTALLATION_TYPE STREQUAL "standard" AND NOT OPENCMISS_INDEPENDENT_ROOTS)
    if (NOT DEFINED OPENCMISS_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
        # Standard installation scenario and the root directory can be found relative to the source directory
        get_filename_component(OPENCMISS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
    endif ()
    if (NOT DEFINED OPENCMISS_CMAKE_MODULE_PATH)
        # Standard installation scenario and the module path can be found from OPENCMISS_ROOT.
        set(OPENCMISS_CMAKE_MODULE_PATH "${OPENCMISS_ROOT}/install/share/cmake/Modules")
    endif ()
    set(OC_EXAMPLES TRUE)
    set(OPENCMISS_ROOT_CONFIG OpenCMISSStandardRoots)
    set(OPENCMISS_OWN_MPI_INSTALL_BASE "${OPENCMISS_ROOT}/install")
elseif (OPENCMISS_INSTALLATION_TYPE STREQUAL "standard" AND OPENCMISS_INDEPENDENT_ROOTS)
    set(OC_EXAMPLES TRUE)
    set(OPENCMISS_ROOT_CONFIG OpenCMISSStandardRootsIndependent)
    set(OPENCMISS_OWN_MPI_INSTALL_BASE "${OPENCMISS_DEPENDENCIES_ROOT}/install")
elseif (OPENCMISS_INSTALLATION_TYPE STREQUAL "libraries" AND NOT OPENCMISS_INDEPENDENT_ROOTS)
    if (NOT DEFINED OPENCMISS_LIBRARIES_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
        # Standard libraries installation scenario and the root directory can be found relative to the source directory
        get_filename_component(OPENCMISS_LIBRARIES_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
    endif ()
    set(OPENCMISS_ROOT_CONFIG OpenCMISSLibrariesRoots)
    set(OPENCMISS_LIBRARIES_ONLY TRUE)
    set(OC_EXAMPLES FALSE)
elseif (OPENCMISS_INSTALLATION_TYPE STREQUAL "libraries" AND OPENCMISS_INDEPENDENT_ROOTS)
    set(OPENCMISS_ROOT_CONFIG OpenCMISSLibrariesRootsIndependent)
    set(OPENCMISS_LIBRARIES_ONLY TRUE)
    set(OC_EXAMPLES FALSE)
elseif (OPENCMISS_INSTALLATION_TYPE STREQUAL "dependencies" AND NOT OPENCMISS_INDEPENDENT_ROOTS)
    set(OPENCMISS_DEPENDENCIES_ONLY TRUE)
    if (NOT DEFINED OPENCMISS_DEPENDENCIES_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
        # Standard libraries installation scenario and the root directory can be found relative to the source directory
        get_filename_component(OPENCMISS_DEPENDENCIES_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
    endif ()
    set(OPENCMISS_OWN_MPI_INSTALL_BASE "${OPENCMISS_DEPENDENCIES_ROOT}/install")
    if (NOT DEFINED OPENCMISS_CMAKE_MODULE_PATH)
        # Standard installation scenario and the module path can be found from OPENCMISS_ROOT.
        set(OPENCMISS_CMAKE_MODULE_PATH "${OPENCMISS_DEPENDENCIES_ROOT}/install/share/cmake/Modules")
    endif ()
    set(OC_EXAMPLES FALSE)
    set(OPENCMISS_ROOT_CONFIG OpenCMISSDependenciesRoots)
elseif (OPENCMISS_INSTALLATION_TYPE STREQUAL "dependencies" AND OPENCMISS_INDEPENDENT_ROOTS)
    set(OPENCMISS_DEPENDENCIES_ONLY TRUE)
    set(OPENCMISS_OWN_MPI_INSTALL_BASE "${OPENCMISS_DEPENDENCIES_ROOT}/install")
    set(OC_EXAMPLES FALSE)
    set(OPENCMISS_ROOT_CONFIG OpenCMISSDependenciesRoots)
else ()
    message(FATAL_ERROR "Unknown installation type asked for: ${OPENCMISS_INSTALLATION_TYPE}.  Try one from; ${INSTALLATION_TYPES}")
endif ()

set(OPENCMISS_CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}" CACHE PATH "Location of the OpenCMISS CMake modules.")
# Validate settings - First check we have the modules that we need
if (NOT EXISTS "${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCArchitecturePathFunctions.cmake")
    message(FATAL_ERROR "'${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS/OCArchitecturePathFunctions.cmake' does not exist.  The OpenCMISS CMake modules may not be installed/available.")
endif ()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/SharedModules")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Scripts")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Modules")
list(APPEND CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}/FindModuleWrappers")
list(APPEND CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}")
list(APPEND CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}/OpenCMISS")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}/SharedSettings")

set(CONFIGURED_FILES_DIR "${CMAKE_CURRENT_BINARY_DIR}/ConfiguredFiles")
list(APPEND CMAKE_MODULE_PATH "${CONFIGURED_FILES_DIR}")
if (NOT _INSTALLATION_CONFIG_FINALISED)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/${OPENCMISS_ROOT_CONFIG}.template.cmake" "${CONFIGURED_FILES_DIR}/OpenCMISSRoots.cmake" @ONLY)
endif ()

include(FileSyncedOptions)
include(OCArchitecturePathFunctions)
include(OCMiscFunctions)
include(OCMultiConfigEnvironment)
include(OCCompiler)
include(OpenCMISSRoots)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(GITHUB_USE_SSL FALSE)
if ( (NOT HAVE_SSH_GITHUB_ACCESS AND NOT SSH_GITHUB_ACCESS_CHECKED) OR FORCE_GITHUB_SSH_CHECK)
    check_ssh_github_access(HAVE_SSH_GITHUB_ACCESS)
    set(SSH_GITHUB_ACCESS_CHECKED TRUE CACHE BOOL "ssh access to github.com checked.")
    mark_as_advanced(SSH_GITHUB_ACCESS_CHECKED)
    message(STATUS "Have ssh access to GitHub.com: ${HAVE_SSH_GITHUB_ACCESS}")
    if (HAVE_SSH_GITHUB_ACCESS)
        set(GITHUB_USE_SSL TRUE)
    endif ()
endif ()

if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(OPENCMISS_BUILD_TYPE Release CACHE STRING "Choose the type of build to configure, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
    set(CMAKE_BUILD_TYPE Release CACHE INTERNAL "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
    #message(STATUS "Setting build type to: ${CMAKE_BUILD_TYPE}")
endif()

# Set the configuration variables.
set(OC_DEVELOPER NO)

set(OC_INSTALLATION_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}/Options/InstallationOptions.txt")
if (NOT _INSTALLATION_CONFIG_FINALISED)
    read_options(${OC_INSTALLATION_CONFIG})
endif ()

# Configure settings for components
include(OCComponentSettings)

set(VISIBLE_GUI_ENTRIES OPENCMISS_ROOT OPENCMISS_LIBRARIES_ROOT OPENCMISS_DEPENDENCIES_ROOT OPENCMISS_EXAMPLES_ROOT OPENCMISS_IRON_ROOT OPENCMISS_ZINC_ROOT OPENCMISS_DEPENDENCIES_INSTALL_PREFIX)
set(VISIBLE_standard_GUI_ENTRIES OPENCMISS_ROOT)
set(VISIBLE_standard_IND_GUI_ENTRIES OPENCMISS_LIBRARIES_ROOT OPENCMISS_EXAMPLES_ROOT OPENCMISS_DEPENDENCIES_ROOT)
set(VISIBLE_libraries_GUI_ENTRIES OPENCMISS_LIBRARIES_ROOT OPENCMISS_DEPENDENCIES_INSTALL_PREFIX)
set(VISIBLE_libraries_IND_GUI_ENTRIES OPENCMISS_ZINC_ROOT OPENCMISS_IRON_ROOT OPENCMISS_DEPENDENCIES_INSTALL_PREFIX)
set(VISIBLE_dependencies_GUI_ENTRIES OPENCMISS_DEPENDENCIES_ROOT)
set(VISIBLE_dependencies_IND_GUI_ENTRIES OPENCMISS_DEPENDENCIES_ROOT)

if (OPENCMISS_INDEPENDENT_ROOTS)
    set(IND_MARKER _IND)
endif ()

set(_VISIBLE_LIST VISIBLE_${OPENCMISS_INSTALLATION_TYPE}${IND_MARKER}_GUI_ENTRIES)
if (NOT _INSTALLATION_CONFIG_FINALISED)
    foreach(_R ${VISIBLE_GUI_ENTRIES})
        if ("${_R}" IN_LIST ${_VISIBLE_LIST})
            set(${_R} "${${_R}}" CACHE PATH "Root or install prefix: ${_R}")
        else ()
            unset(${_R} CACHE)
        endif ()
    endforeach()
endif ()

if (DEFINED OPENCMISS_IRON_ROOT AND OPENCMISS_ZINC_ONLY)
	unset(OPENCMISS_IRON_ROOT CACHE)
endif ()
if (DEFINED OPENCMISS_ZINC_ROOT AND OPENCMISS_IRON_ONLY)
	unset(OPENCMISS_ZINC_ROOT CACHE)
endif ()

# Validate settings and options.
set(INVALID_SETTINGS FALSE)
if (OPENCMISS_DEPENDENCIES_ONLY)
    if (OPENCMISS_IRON_ONLY OR OPENCMISS_ZINC_ONLY)
        set(INVALID_SETTINGS TRUE)
    endif ()
elseif (OPENCMISS_IRON_ONLY)
    if (OPENCMISS_DEPENDENCIES_ONLY OR OPENCMISS_ZINC_ONLY)
        set(INVALID_SETTINGS TRUE)
    endif ()
elseif (OPENCMISS_ZINC_ONLY)
    if (OPENCMISS_DEPENDENCIES_ONLY OR OPENCMISS_IRON_ONLY)
        set(INVALID_SETTINGS TRUE)
    endif ()
endif ()
if (INVALID_SETTINGS)
    message(FATAL_ERROR "The options OPENCMISS_IRON_ONLY, OPENCMISS_ZINC_ONLY, and OPENCMISS_DEPENDENCIES_ONLY are invalid.  Only one may be TRUE at any one time.")
endif ()

include(OCToolchainCompilers)

getToolchain(CURRENT_TOOLCHAIN)
set(OPENCMISS_TOOLCHAIN ${CURRENT_TOOLCHAIN} CACHE STRING "Specify the toolchain mnemonic.")

include(OCDetermineMPIFunctions)
include(OCPreSelectMPI)
include(OCSelectMPI)
include(OCPostSelectMPI)
include(OCDetermineCXX11)
include(OCVariables)
include(OCDefaultComponentConfig)
include(OCDetermineRequiredComponents)

# Hide some of the variables in the interface that we don't want to see.
tidy_gui_variables()

########################################################################
# Misc targets for convenience
# include(OCMainTargets) # TODO: Add this back in


set(OPENCMISS_MPI ${OPENCMISS_MPI} CACHE STRING "Specify the MPI mnemonic.")
set(OPENCMISS_BUILD_OWN_MPI NO CACHE BOOL "Build own MPI if system MPI is unavailable.")
set(OPENCMISS_INSTRUMENTATION "none" CACHE STRING "Specify the instrumentation.")
set(OPENCMISS_USER_PART_ARCHITECTURE_PATH "" CACHE STRING "User specifed part of the architecture path.")
mark_as_advanced(OPENCMISS_USER_PART_ARCHITECTURE_PATH)

# Get the compiler part
get_compiler_path_for_toolchain(${OPENCMISS_TOOLCHAIN} COMPILER_PART)
getArchitecturePathGivenCompilerPart(${COMPILER_PART} ARCHITECTURE_NO_MPI_PATH ARCHITECTURE_MPI_PATH)

if (OPENCMISS_USE_ARCHITECTURE_PATH)
    set(ACTIVE_ARCHITECTURE_MPI_PATH ${ARCHITECTURE_MPI_PATH})
    set(ACTIVE_ARCHITECTURE_NO_MPI_PATH ${ARCHITECTURE_NO_MPI_PATH})
    set(CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH ${ARCHITECTURE_MPI_PATH})
    set(CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH ${ARCHITECTURE_NO_MPI_PATH})
else()
    set(CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH .)
    set(CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH .)
endif()

if (FINALISE_INSTALLATION)
    finalise_options(${OC_INSTALLATION_CONFIG})
    set(OPENCMISS_INDEPENDENT_ROOTS ${OPENCMISS_INDEPENDENT_ROOTS} CACHE INTERNAL "Fix OPENCMISS_INDEPENDENT_ROOTS.")
    set(OPENCMISS_INSTALLATION_TYPE ${OPENCMISS_INSTALLATION_TYPE} CACHE INTERNAL "Fix OPENCMISS_INSTALLATION_TYPE.")
    set(OPENCMISS_CMAKE_MODULE_PATH ${OPENCMISS_CMAKE_MODULE_PATH} CACHE INTERNAL "Fix OPENCMISS_CMAKE_MODULE_PATH.")
    if (NOT OPENCMISS_USE_ARCHITECTURE_PATH)
        set(OPENCMISS_INSTRUMENTATION ${OPENCMISS_INSTRUMENTATION} CACHE INTERNAL "Fix OPENCMISS_INSTRUMENTATION.")
        set(OPENCMISS_BUILD_OWN_MPI ${OPENCMISS_BUILD_OWN_MPI} CACHE INTERNAL "Fix OPENCMISS_BUILD_OWN_MPI.")
        set(OPENCMISS_MPI ${OPENCMISS_MPI} CACHE INTERNAL "Fix OPENCMISS_MPI.")
        set(OPENCMISS_MPI_BUILD_TYPE ${OPENCMISS_MPI_BUILD_TYPE} CACHE INTERNAL "Fix OPENCMISS_MPI_BUILD_TYPE.")
        set(OPENCMISS_MPI_USE_SYSTEM ${OPENCMISS_MPI_USE_SYSTEM} CACHE INTERNAL "Fix OPENCMISS_MPI_USE_SYSTEM.")
        set(OPENCMISS_TOOLCHAIN ${OPENCMISS_TOOLCHAIN} CACHE INTERNAL "Fix OPENCMISS_TOOLCHAIN.")
    endif ()
    foreach(_R ${VISIBLE_GUI_ENTRIES})
        if ("${_R}" IN_LIST ${_VISIBLE_LIST})
            set(${_R} "${${_R}}" CACHE INTERNAL "Root or install prefix: ${_R}")
        endif ()
    endforeach()
endif ()

# Checks for known issues in toolchain configuration
include(OCToolchainChecks)

if (OPENCMISS_USE_ARCHITECTURE_PATH)
    set(PLURAL_S s)
else ()
    set(PLURAL_S)
endif ()

# Variable passed to configurations of libraries
set(SUPPORT_DIR "${CMAKE_CURRENT_BINARY_DIR}/support")

# All arguments passed to construct the currently specified configuration
set(CURRENT_CONFIGURATION_ARGS)

if (OPENCMISS_LIBRARIES_ONLY)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_DEPENDENCIES_INSTALL_PREFIX=${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX})
endif ()
if (OPENCMISS_ZINC_ONLY)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_IRON=OFF)
else ()
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_IRON=ON)
endif ()

if (OPENCMISS_IRON_ONLY)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_ZINC=OFF)
else ()
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_ZINC=ON)
endif ()

if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_BUILD_TYPE=${OPENCMISS_BUILD_TYPE})
endif ()

if (MPI_HOME)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DMPI_HOME=${MPI_HOME})
endif ()

if (MPI_HOME_BUILD_TYPE)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DMPI_HOME_BUILD_TYPE=${MPI_HOME_BUILD_TYPE})
endif ()

list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_MPI_IMPLEMENTATION=${OPENCMISS_MPI_IMPLEMENTATION})
list(APPEND CURRENT_CONFIGURATION_ARGS -DMPIEXEC_EXECUTABLE=${MPIEXEC_EXECUTABLE})
foreach(_lang C CXX Fortran)
    if (MPI_${_lang}_COMPILER)
        list(APPEND CURRENT_CONFIGURATION_ARGS -DMPI_${_lang}_COMPILER=${MPI_${_lang}_COMPILER})
    endif ()
endforeach()
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_LIBRARIES_ONLY=${OPENCMISS_LIBRARIES_ONLY})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_DEPENDENCIES_ONLY=${OPENCMISS_DEPENDENCIES_ONLY})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_TOOLCHAIN=${OPENCMISS_TOOLCHAIN})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_BUILD_OWN_MPI=${OPENCMISS_BUILD_OWN_MPI})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_INSTRUMENTATION=${OPENCMISS_INSTRUMENTATION})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_OWN_MPI_INSTALL_BASE=${OPENCMISS_OWN_MPI_INSTALL_BASE})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_ROOTS_FILE=${CONFIGURED_FILES_DIR}/OpenCMISSRoots.cmake)
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_CMAKE_MODULE_PATH=${OPENCMISS_CMAKE_MODULE_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_SUPPORT_DIR=${SUPPORT_DIR})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_USE_ARCHITECTURE_PATH=${OPENCMISS_USE_ARCHITECTURE_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DARCH_MPI_PATH=${ACTIVE_ARCHITECTURE_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DARCH_NO_MPI_PATH=${ACTIVE_ARCHITECTURE_NO_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DCONFIG_PACKAGE_ARCHITECTURE_MPI_PATH=${CONFIG_PACKAGE_ARCHITECTURE_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DCONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH=${CONFIG_PACKAGE_ARCHITECTURE_NO_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DSHARED_MODULES_PATH=${CMAKE_CURRENT_LIST_DIR}/SharedModules)
list(APPEND CURRENT_CONFIGURATION_ARGS -DSHARED_SETTINGS_PATH=${CMAKE_CURRENT_BINARY_DIR}/SharedSettings)

if ("${OPENCMISS_INSTRUMENTATION}" STREQUAL "scorep")
    foreach(_lang C CXX Fortran)
       if (CMAKE_${_lang}_COMPILER)
           string(CONCAT TEMP_${_lang}_COMPILER "scorep-" "${CMAKE_${_lang}_COMPILER}")
           list(APPEND CURRENT_CONFIGURATION_ARGS -DCMAKE_${_lang}_COMPILER=${TEMP_${_lang}_COMPILER})
       endif ()
    endforeach()
endif ()

string(REPLACE ";" " " CONFIGURATION_SETTINGS "${CURRENT_CONFIGURATION_ARGS}")

# Variable used in create_config command
set(INSTALLATION_CONFIGS_PATH "${CMAKE_CURRENT_BINARY_DIR}/config${PLURAL_S}")
set(CONFIG_PATH "${INSTALLATION_CONFIGS_PATH}${ACTIVE_ARCHITECTURE_MPI_PATH}")
if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(CONFIG_PATH "${CONFIG_PATH}/${OPENCMISS_BUILD_TYPE}")
endif ()

# Packaging, creating SDKs etc.
if (OPENCMISS_INSTALLATION_TYPE STREQUAL "standard" OR OPENCMISS_INSTALLATION_TYPE STREQUAL "dependencies" AND NOT OPENCMISS_INDEPENDENT_ROOTS)
    include(OCPackaging)
endif ()

########################################################################
# Create source management targets and download commands
# Iron, Zinc, Dependencies, ...
add_subdirectory(SourceManagement)

set(BUILD_CONFIG_COMMAND ${CMAKE_COMMAND} --build . --target install --config $<CONFIG>)

# Stamp file definitions.
set(name manage_config)
get_configuration_subdir_suffix(cfgdir)

set(stamp_dir "${CONFIG_PATH}${cfgdir}/stamp")
set(create_config_stamp_file "${stamp_dir}/${name}-create")
set(build_config_stamp_file "${stamp_dir}/${name}-build")
set(done_stamp_file "${stamp_dir}/${name}-done")
set(mkdir_stamp_file ${stamp_dir}/${name}-mkdir)

set(cmf_dir ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles)
set(complete_stamp_file "${cmf_dir}${cfgdir}/${name}-complete")

add_custom_target(${name} ALL DEPENDS ${complete_stamp_file})

set(complete_outputs ${complete_stamp_file})
add_custom_command(
    OUTPUT ${complete_outputs}
    COMMENT "Completed '${name}'"
    COMMAND ${CMAKE_COMMAND} -E make_directory ${cmf_dir}${cfgdir}
    COMMAND ${CMAKE_COMMAND} -E touch ${complete_stamp_file}
    COMMAND ${CMAKE_COMMAND} -E touch ${done_stamp_file}
    DEPENDS ${build_config_stamp_file}
    VERBATIM
)

add_custom_command(APPEND
    OUTPUT ${complete_stamp_file}
    DEPENDS ${mkdir_stamp_file}
)

add_custom_command(OUTPUT ${mkdir_stamp_file}
    COMMENT "Creating directories."
    COMMAND ${CMAKE_COMMAND} -E make_directory ${stamp_dir}${cfgdir}
    COMMAND ${CMAKE_COMMAND} -E touch ${mkdir_stamp_file}
    DEPENDS get_sources
    VERBATIM
)

add_custom_command(OUTPUT ${create_config_stamp_file}
    COMMENT "Creating config."
    COMMAND ${CMAKE_COMMAND} "-G${CMAKE_GENERATOR}" ${CURRENT_CONFIGURATION_ARGS} ${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig
    COMMAND ${CMAKE_COMMAND} -E touch ${create_config_stamp_file}
    WORKING_DIRECTORY ${CONFIG_PATH}
    VERBATIM
)

add_custom_command(APPEND
    OUTPUT ${create_config_stamp_file}
    DEPENDS ${mkdir_stamp_file}
)

add_custom_target(create_config
    DEPENDS "${create_config_stamp_file}"
)

add_custom_command(APPEND
    OUTPUT ${complete_stamp_file}
    DEPENDS ${build_config_stamp_file}
)

add_custom_command(OUTPUT ${build_config_stamp_file}
    COMMENT "Building configuration."
    COMMAND ${BUILD_CONFIG_COMMAND}
    COMMAND ${CMAKE_COMMAND} -E touch ${build_config_stamp_file}
    WORKING_DIRECTORY ${CONFIG_PATH}
    VERBATIM
)

add_custom_command(APPEND
    OUTPUT ${build_config_stamp_file}
    DEPENDS ${create_config_stamp_file}
)

add_custom_target(build_config
    DEPENDS ${build_config_stamp_files}
)
#add_dependencies(build_config create_config)

add_custom_target(redo_config
    COMMAND ${CMAKE_COMMAND} -E remove ${create_config_stamp_file}
    COMMAND ${CMAKE_COMMAND} -E remove ${build_config_stamp_file}
    COMMAND ${CMAKE_COMMAND} -E remove ${done_stamp_file}
    COMMAND ${CMAKE_COMMAND} --build . --target ${name} --config $<CONFIG>
    VERBATIM
)

add_custom_target(keytests
    COMMAND ${CMAKE_COMMAND} --build . --target keytests --config $<CONFIG>
    WORKING_DIRECTORY ${CONFIG_PATH}
    COMMENT "Running keytests for active configuration."
)
add_custom_target(support
    COMMAND ${CMAKE_COMMAND} --build ${CONFIG_PATH} --target collect_logs --config $<CONFIG>
    COMMAND ${CMAKE_COMMAND}
        -DEMAIL=${OPENCMISS_INSTALLATION_SUPPORT_EMAIL}
        -DCONFIG_DIR=${CONFIG_PATH}
        -DSUPPORT_DIR=${SUPPORT_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/Scripts/OCCreateZip.cmake
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Generating support files archive"
    VERBATIM
)

if (EXISTS "${create_config_stamp_file}")
    file(REMOVE "${create_config_stamp_file}")
endif ()

message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@ SUMMARY @@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ OPENCMISS_TOOLCHAIN: ${OPENCMISS_TOOLCHAIN}")
message(STATUS "@ OPENCMISS_MPI_IMPLEMENTATION: ${OPENCMISS_MPI_IMPLEMENTATION}")
message(STATUS "@ ACTIVE_ARCHITECTURE_MPI_PATH: ${ACTIVE_ARCHITECTURE_MPI_PATH}")
message(STATUS "@")
message(STATUS "@ CONFIG PATH: ${CONFIG_PATH}")
message(STATUS "@ CONFIGURATION SETTINGS: ${CONFIGURATION_SETTINGS}")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@ NEXT STEPS @@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ - Change ${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSInstallationConfig.cmake according to your needs")
message(STATUS "@")
message(STATUS "@ Having trouble? Follow the galaxy hitchhiker's advice:")
message(STATUS "@ DONT PANIC ... and:")
message(STATUS "@ - Refer to http://staging.opencmiss.org/documentation/cmake/docs/config/index.html for customization instructions")
message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")

# get_cmake_property(_variableNames VARIABLES)
# foreach (_variableName ${_variableNames})
#     if (_variableName MATCHES "^OC_" OR _variableName MATCHES "^OPENCMISS_")
#         message(STATUS "${_variableName}=${${_variableName}}")
#     endif ()
# endforeach()
