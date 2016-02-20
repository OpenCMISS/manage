# Check for existing SDK directories 
if (DEFINED OPENCMISS_SDK_DIR)
    get_filename_component(OPENCMISS_SDK_DIR "${OPENCMISS_SDK_DIR}" ABSOLUTE)
    if (EXISTS "${OPENCMISS_SDK_DIR}")
        log("Using SDK installation directory: ${OPENCMISS_SDK_DIR}")
    else()
        log("The specified OPENCMISS_SDK_DIR '${OPENCMISS_SDK_DIR}' does not exist. Skipping." WARNING)
        unset(OPENCMISS_SDK_DIR)
    endif()
endif()    
if(NOT OPENCMISS_SDK_DIR AND NOT "$ENV{OPENCMISS_SDK_DIR}" STREQUAL "")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_SDK_DIR}" OPENCMISS_SDK_DIR)
    get_filename_component(OPENCMISS_SDK_DIR "${OPENCMISS_SDK_DIR}" ABSOLUTE)
    if (EXISTS "${OPENCMISS_SDK_DIR}")
        log("Using environment SDK installation directory: ${OPENCMISS_SDK_DIR}")
    else()
        log("The environment variable OPENCMISS_SDK_DIR='${OPENCMISS_SDK_DIR}' contains an invalid path. Skipping." WARNING)
        unset(OPENCMISS_SDK_DIR)
    endif()
endif()

# Wrap the inclusion of the sdk context into a function to protect the local scope
function(get_sdk_prefix_path DIR RESULT_VAR)
    get_filename_component(DIR ${DIR} ABSOLUTE)
    if (EXISTS ${DIR}/context.cmake)
        include(${DIR}/context.cmake)
        log("get_sdk_prefix_path: OPENCMISS_PREFIX_PATH_IMPORT=${OPENCMISS_PREFIX_PATH_IMPORT}" DEBUG)
        set(${RESULT_VAR} ${OPENCMISS_PREFIX_PATH_IMPORT} PARENT_SCOPE)
    endif()
endfunction()

##############
# Compile sdk arch directory
set(OPENCMISS_SDK_DIR_ARCH )
# In case we are provided with a direct install directory, use that and let the user make sure the installations are compatible
if (OPENCMISS_SDK_DIR_FORCE)
    get_filename_component(OPENCMISS_SDK_DIR_FORCE "${OPENCMISS_SDK_DIR_FORCE}" ABSOLUTE)
    set(OPENCMISS_SDK_DIR_ARCH "${OPENCMISS_SDK_DIR_FORCE}")
    if (NOT EXISTS "${OPENCMISS_SDK_DIR_FORCE}")
        log("Invalid OPENCMISS_SDK_DIR_FORCE directory: ${OPENCMISS_SDK_DIR_FORCE}" ERROR)
    endif()
# In case we are provided with a sdk root directory, we are creating the same sub-path as we are locally using
# to import the matching libraries
elseif(EXISTS "${OPENCMISS_SDK_DIR}")
    # The sdk installations always have to use an architecture path, and we're compiling our local
    # one to make sure a compatible architecture and configuration has been chosen.
    getArchitecturePath(_UNUSED ARCHITECTURE_PATH_MPI)
    
    set(ARCH_SUBPATH ${ARCHITECTURE_PATH_MPI}/${BUILDTYPEEXTRA})
    set(OPENCMISS_SDK_DIR_ARCH ${OPENCMISS_SDK_DIR}/${ARCH_SUBPATH})
endif()
##############
# Read sdk configuration 
if (EXISTS "${OPENCMISS_SDK_DIR_ARCH}")
    # Need to wrap this into a function as a separate scope is needed in order to avoid overriding
    # local values by those set in the opencmiss context file.
    get_sdk_prefix_path(${OPENCMISS_SDK_DIR_ARCH} SDK_PREFIX_PATH)
    log("Extracted SDK_PREFIX_PATH=${SDK_PREFIX_PATH} from OPENCMISS_SDK_DIR_ARCH=${OPENCMISS_SDK_DIR_ARCH}" DEBUG)
    if (SDK_PREFIX_PATH)
        log("Using OpenCMISS (SDK) component installation at ${OPENCMISS_SDK_DIR_ARCH}...")
        list(APPEND CMAKE_PREFIX_PATH ${SDK_PREFIX_PATH})
        list(APPEND OPENCMISS_PREFIX_PATH ${SDK_PREFIX_PATH})
        unset(SDK_PREFIX_PATH) 
    else()
        log("No matching OpenCMISS installation found for the current configuration subpath '${ARCH_SUBPATH}' under ${OPENCMISS_SDK_DIR}. Please check your local setup." ERROR)
    endif()
endif()

