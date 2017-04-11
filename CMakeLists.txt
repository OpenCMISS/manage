
########################################################
# If your cmake is older than 3.4 - goodbye. 
cmake_minimum_required(VERSION 3.4.0 FATAL_ERROR)

########################################################################
# Ready to start the "build project"
project(OpenCMISS-Manage VERSION 1.3.0 LANGUAGES C CXX)
enable_language(Fortran OPTIONAL)
enable_testing()

mark_as_advanced(CMAKE_INSTALL_PREFIX)

set(OpenCMISSLibs_MAJOR_VERSION ${PROJECT_VERSION_MAJOR})
set(OpenCMISSLibs_MINOR_VERSION ${PROJECT_VERSION_MINOR})
set(OpenCMISSLibs_PATCH_VERSION ${PROJECT_VERSION_PATCH})
set(OpenCMISSLibs_VERSION ${OpenCMISSLibs_MAJOR_VERSION}.${OpenCMISSLibs_MINOR_VERSION}.${OpenCMISSLibs_PATCH_VERSION})
# This is the support email for general enquiries and support about building opencmiss using the new CMake system.
set(OPENCMISS_BUILD_SUPPORT_EMAIL "users@opencmiss.org")

# Determine if the OpenCMISSInstallationConfig should be considered finalised or not.
if (EXISTS "${CMAKE_CURRENT_BINARY_DIR}/config" OR EXISTS "${CMAKE_CURRENT_BINARY_DIR}/configs")
    set(_INSTALLATION_CONFIG_FINALISED TRUE)
else ()
    set(_INSTALLATION_CONFIG_FINALISED FALSE)
endif ()

# The default opencmiss root is the grandparent directory of "manage"
if (NOT DEFINED OPENCMISS_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
    if (NOT DEFINED OPENCMISS_LIBRARIES_ROOT AND NOT DEFINED OPENCMISS_DEPENDENCIES_ROOT AND NOT DEFINED OPENCMISS_CMAKE_MODULES_ROOT AND NOT _INSTALLATION_CONFIG_FINALISED)
        # Standard installation scenario and the module path can be found relative to this directory
        get_filename_component(OPENCMISS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." REALPATH)
    endif ()
    if (NOT DEFINED OPENCMISS_CMAKE_MODULE_PATH)
        # Standard installation scenario and the module path can be found relative to this directory
        get_filename_component(OPENCMISS_CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../install/share/cmake" REALPATH) 
    endif ()
endif ()

if (DEFINED OPENCMISS_ROOT)
    if (_INSTALLATION_CONFIG_FINALISED)
        unset(OPENCMISS_ROOT CACHE)
    else ()
        set(OPENCMISS_ROOT "${OPENCMISS_ROOT}" CACHE PATH "Root location for building OpenCMISS from source.")
        set(OPENCMISS_ROOT_CONFIG OpenCMISSRoot)
        set(OPENCMISS_OWN_MPI_CONFIG OpenCMISSOwnMPIRoot)
    endif ()
else ()
    if (_INSTALLATION_CONFIG_FINALISED)
        unset(OPENCMISS_LIBRARIES_ROOT CACHE)
        unset(OPENCMISS_DEPENDENCIES_ROOT CACHE)
        unset(OPENCMISS_EXAMPLES_ROOT CACHE)
        unset(OPENCMISS_CMAKE_MODULES_ROOT CACHE)
    else ()
        set(OPENCMISS_LIBRARIES_ROOT "${OPENCMISS_LIBRARIES_ROOT}" CACHE PATH "Root location for building OpenCMISS libraries from source.")
        set(OPENCMISS_DEPENDENCIES_ROOT "${OPENCMISS_DEPENDENCIES_ROOT}" CACHE PATH "Root location for building OpenCMISS dependencies from source.")
        set(OPENCMISS_EXAMPLES_ROOT "${OPENCMISS_EXAMPLES_ROOT}" CACHE PATH "Root location for building OpenCMISS examples from source.")
        set(OPENCMISS_CMAKE_MODULES_ROOT "${OPENCMISS_CMAKE_MODULES_ROOT}" CACHE PATH "Root location for building OpenCMISS cmake modules from source.")
        set(OPENCMISS_ROOT_CONFIG OpenCMISSIndependentRoots)
        set(OPENCMISS_OWN_MPI_CONFIG OpenCMISSOwnMPIIndependentRoots)
    endif ()
endif ()

if (NOT EXISTS "${OPENCMISS_CMAKE_MODULE_PATH}/Modules/OpenCMISS/OCArchitecturePathFunctions.cmake")
    message(FATAL_ERROR "'${OPENCMISS_CMAKE_MODULE_PATH}/Modules/OpenCMISS/OCArchitecturePathFunctions.cmake' does not exists.  The OpenCMISS CMake modules may not be installed/available.")
endif ()

# OPENCMISS_CMAKE_MODULE_PATH must be set
set(OPENCMISS_CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}" CACHE PATH "Location of the OpenCMISS CMake modules.")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/Scripts")
list(APPEND CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}/Modules")
list(APPEND CMAKE_MODULE_PATH "${OPENCMISS_CMAKE_MODULE_PATH}/Modules/OpenCMISS")

set(CONFIGURED_FILES_DIR "${CMAKE_CURRENT_BINARY_DIR}/ConfiguredFiles")
list(APPEND CMAKE_MODULE_PATH "${CONFIGURED_FILES_DIR}")
if (NOT _INSTALLATION_CONFIG_FINALISED)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/${OPENCMISS_OWN_MPI_CONFIG}.template.cmake" "${CONFIGURED_FILES_DIR}/OpenCMISSOwnMPI.cmake" @ONLY)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/${OPENCMISS_ROOT_CONFIG}.template.cmake" "${CONFIGURED_FILES_DIR}/OpenCMISSRoots.cmake" @ONLY)
endif ()

include(OCArchitecturePathFunctions)
include(OCMiscFunctions)
include(OCMultiConfigEnvironment)
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

# Look for an OpenCMISS installation file
SET(OC_INSTALLATION_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSInstallationConfig.cmake")
set(OC_DEVELOPER NO)
if (NOT EXISTS "${OC_INSTALLATION_CONFIG}")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/OpenCMISSInstallationConfig.cmake"
        DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
endif ()

message(STATUS "Applying OpenCMISS installation configuration at ${OC_INSTALLATION_CONFIG}...")
include("${OC_INSTALLATION_CONFIG}")
unset(OC_INSTALLATION_CONFIG)

# Path for own MPI BUILD?
include(OpenCMISSOwnMPI)

include(OCToolchainCompilers)
include(OCDetermineMPI)

# Hide some of the variables in the interface that we don't want to see.
tidy_gui_variables()

########################################################################
# Misc targets for convenience
# include(OCMainTargets) # TODO: Add this back in

getToolchain(CURRENT_TOOLCHAIN)

set(OPENCMISS_TOOLCHAIN ${CURRENT_TOOLCHAIN} CACHE STRING "Specify the toolchain mnemonic.")
set(OPENCMISS_MPI ${OPENCMISS_MPI} CACHE STRING "Specify the MPI mnemonic.")
set(OPENCMISS_BUILD_OWN_MPI NO CACHE BOOL "Build own MPI if system MPI is unavailable.")
set(OPENCMISS_INSTRUMENTATION "none" CACHE STRING "Specify the instrumentation.")
set(OPENCMISS_USER_PART_ARCHITECTURE_PATH "" CACHE STRING "User specifed part of the architecture path.")
mark_as_advanced(OPENCMISS_USER_PART_ARCHITECTURE_PATH)

function(GET_COMPILER_PATH_FOR_TOOLCHAIN TOOLCHAIN_MNEMONIC VAR_NAME)

    set(OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/CompilerPath/")
    file(MAKE_DIRECTORY "${OUTPUT_DIRECTORY}")
    set(OUTPUT_FILENAME "${OUTPUT_DIRECTORY}/output.txt")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" -DTOOLCHAIN=${TOOLCHAIN_MNEMONIC} -DOPENCMISS_CMAKE_MODULE_PATH=${OPENCMISS_CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/CompilerPath/"
        WORKING_DIRECTORY "${OUTPUT_DIRECTORY}"
        RESULT_VARIABLE RESULT
        OUTPUT_FILE "${OUTPUT_FILENAME}"
        ERROR_FILE "${OUTPUT_FILENAME}"
        )

    if ("${RESULT}" STREQUAL "0")
        file(STRINGS "${OUTPUT_FILENAME}" OUTPUT_CONTENTS)

        foreach(line ${OUTPUT_CONTENTS})
            if ("${line}" MATCHES "COMPILER_PART=*")
                string(SUBSTRING "${line}" 14 -1 CREATED_COMPILER_PATH)
                set(${VAR_NAME} ${CREATED_COMPILER_PATH} PARENT_SCOPE)
            endif ()
        endforeach()
        file(REMOVE_RECURSE "${OUTPUT_DIRECTORY}")
    else ()
        message(STATUS "Things have gone pear shaped.")
        set(${VAR_NAME} "error" PARENT_SCOPE)
    endif ()
endfunction()

# Get the compiler part
get_compiler_path_for_toolchain(${OPENCMISS_TOOLCHAIN} COMPILER_PART)
getArchitecturePathGivenCompilerPart(${COMPILER_PART} ARCHITECTURE_NO_MPI_PATH ARCHITECTURE_MPI_PATH)

if (OPENCMISS_USE_ARCHITECTURE_PATH)
    set(ACTIVE_ARCHITECTURE_MPI_PATH ${ARCHITECTURE_MPI_PATH})
    set(ACTIVE_ARCHITECTURE_NO_MPI_PATH ${ARCHITECTURE_NO_MPI_PATH})
endif()

# Checks for known issues in toolchain configuration
include(OCToolchainChecks)

if (OPENCMISS_USE_ARCHITECTURE_PATH)
    set(PLURAL_S s)
else ()
    set(PLURAL_S)
endif ()

set(OPENCMISS_INSTALLATION_CACHE_FILE "${CMAKE_CURRENT_BINARY_DIR}/OpenCMISSCache.cmake")

# All arguments passed to construct the currently specified configuration
set(CURRENT_CONFIGURATION_ARGS)
if (DEFINED OPENCMISS_DEPENDENCIES_ONLY)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_DEPENDENCIES_ONLY="${OPENCMISS_DEPENDENCIES_ONLY}")
endif ()

if (OPENCMISS_ZINC_ONLY)
	list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_IRON=NO)
endif ()

if (OPENCMISS_IRON_ONLY)
	list(APPEND CURRENT_CONFIGURATION_ARGS -DOC_USE_ZINC=NO)
endif ()

if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_BUILD_TYPE=${OPENCMISS_BUILD_TYPE})
endif ()

list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_TOOLCHAIN=${OPENCMISS_TOOLCHAIN})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_MPI=${OPENCMISS_MPI})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_BUILD_OWN_MPI=${OPENCMISS_BUILD_OWN_MPI})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_INSTRUMENTATION=${OPENCMISS_INSTRUMENTATION})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_OWN_MPI_INSTALL_BASE=${OPENCMISS_OWN_MPI_INSTALL_BASE})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_INSTALLATION_CACHE_FILE=${OPENCMISS_INSTALLATION_CACHE_FILE})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOPENCMISS_CMAKE_MODULE_PATH=${OPENCMISS_CMAKE_MODULE_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DARCH_MPI_PATH=${ACTIVE_ARCHITECTURE_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DARCH_NO_MPI_PATH=${ACTIVE_ARCHITECTURE_NO_MPI_PATH})
list(APPEND CURRENT_CONFIGURATION_ARGS -DOpenCMISSLibs_VERSION=${OpenCMISSLibs_VERSION})

if ("${OPENCMISS_INSTRUMENTATION}" STREQUAL "scorep")
    foreach(_lang C CXX Fortran)
       if (CMAKE_${_lang}_COMPILER)
           string(CONCAT TEMP_${_lang}_COMPILER "scorep-" "${CMAKE_${_lang}_COMPILER}")
           list(APPEND CURRENT_CONFIGURATION_ARGS -DCMAKE_${_lang}_COMPILER=${TEMP_${_lang}_COMPILER})
       endif ()
    endforeach()
endif ()

string(REPLACE ";" " " CONFIGURATION_SETTINGS "${CURRENT_CONFIGURATION_ARGS}")
message(STATUS "CONFIGURATION_SETTINGS: ${CONFIGURATION_SETTINGS}")
# Variable used in create_config command
set(CONFIG_PATH "${CMAKE_CURRENT_BINARY_DIR}/config${PLURAL_S}${ACTIVE_ARCHITECTURE_MPI_PATH}")
if (NOT OPENCMISS_HAVE_MULTICONFIG_ENV)
    set(CONFIG_PATH "${CONFIG_PATH}/${OPENCMISS_BUILD_TYPE}")
endif ()
set(CREATE_CONFIG_STAMP_FILE "${CONFIG_PATH}/stamp/create_config.stamp")
add_custom_target(usage ALL
    COMMAND "${CMAKE_COMMAND}" -E echo "Perhaps try targets: create_config, build_config, do_config or help. For other options read the documentation."
    VERBATIM
)

# Variable used in the installtion cache passed to configurations
set(SUPPORT_DIR "${CMAKE_CURRENT_BINARY_DIR}/support")
# Indirection for configuring variable in create_config.in.cmake
set(DOLLAR_SYMBOL $)

# Packaging, creating SDKs etc.
include(OCPackaging)

########################################################################
# Create source management targets and download commands
# Iron, Zinc, Dependencies, ...
add_subdirectory(SourceManagement)

set(BUILD_CONFIG_COMMAND "${CMAKE_COMMAND}" --build . --target install)
if (OPENCMISS_HAVE_MULTICONFIG_ENV)
    list(APPEND BUILD_CONFIG_COMMAND --config $<CONFIG>)
#    set(BUILD_CONFIG_STAMP_FILES)
#    foreach(_possible_config ${CMAKE_CONFIGURATION_TYPES})
#        list(APPEND BUILD_CONFIG_STAMP_FILES "${CONFIG_PATH}/${_possible_config}/stamp/build_config.stamp")
#    endforeach()
#    set(BUILD_CONFIG_STAMP_FILE "${CONFIG_PATH}/$<CONFIG>/stamp/build_config.stamp")
else ()
    string(TOLOWER ${OPENCMISS_BUILD_TYPE} SINGLE_CONFIG_BUILD_TYPE)
endif ()
    set(BUILD_CONFIG_STAMP_FILE "${CONFIG_PATH}/stamp/build_config.stamp")
    set(BUILD_CONFIG_STAMP_FILES ${BUILD_CONFIG_STAMP_FILE})

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/OpenCMISSCache.in.cmake"
    "${OPENCMISS_INSTALLATION_CACHE_FILE}")

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/create_config.in.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/Scripts/create_config.cmake")

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Templates/build_config.in.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/Scripts/build_config.cmake")

add_custom_command(OUTPUT "${CREATE_CONFIG_STAMP_FILE}"
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/Scripts/create_config.cmake"
    COMMAND "${CMAKE_COMMAND}" -DSTAMP_FILE="${CREATE_CONFIG_STAMP_FILE}" -DBUILD_STAMP_FILE="${BUILD_CONFIG_STAMP_FILE}" -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/create_config.cmake"
    )

add_custom_target(create_config
    DEPENDS "${CREATE_CONFIG_STAMP_FILE}"
    )
add_dependencies(create_config get_sources)

string(REPLACE ";" "-<semi-colon>-" BUILD_CONFIG_COMMAND_TMP "${BUILD_CONFIG_COMMAND}")
add_custom_command(OUTPUT "${BUILD_CONFIG_STAMP_FILES}"
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/Scripts/build_config.cmake"
    COMMAND "${CMAKE_COMMAND}" -DBUILD_COMMAND="${BUILD_CONFIG_COMMAND_TMP}" -DSTAMP_FILE="${BUILD_CONFIG_STAMP_FILE}" -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/build_config.cmake"
    )

add_custom_target(build_config
    DEPENDS "${BUILD_CONFIG_STAMP_FILES}"
    )
add_dependencies(build_config create_config)

add_custom_target(do_config
    )
add_dependencies(do_config create_config build_config)

if (EXISTS "${CREATE_CONFIG_STAMP_FILE}")
    file(REMOVE "${CREATE_CONFIG_STAMP_FILE}")
endif ()

message(STATUS "@")
message(STATUS "@@@@@@@@@@@@@@@@@@@@@ SUMMARY @@@@@@@@@@@@@@@@@@@@@@@")
message(STATUS "@")
message(STATUS "@ OPENCMISS_TOOLCHAIN: ${OPENCMISS_TOOLCHAIN}")
message(STATUS "@ OPENCMISS_MPI: ${OPENCMISS_MPI}")
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

