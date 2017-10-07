########################################################################
# This script takes care to have the right MPI mnemonic set.
#
# The case of "no MPI" is not implemented yet, but can easily be done by having to specify "MPI=none" and let the script
# handle it.
#
# 1. MPI_HOME specified - Look exclusively at that location for binaries/libraries
#  a. MPI FOUND - ok, detect type and use that
#  b. MPI NOT FOUND - Error and abort
# 2. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
#  a. OPENCMISS_MPI_USE_SYSTEM = NO AND/OR No MPI found - Prescribe a reasonable system default choice and go with that
#  b. OPENCMISS_MPI_USE_SYSTEM = YES AND MPI found - Use the MPI implementation found on PATH/environment 
# 3. MPI mnemonic/variable specified
#  b. OPENCMISS_MPI_USE_SYSTEM = YES Try to find the specific version on the system
#  a. OPENCMISS_MPI_USE_SYSTEM = NO Build your own (unix only)

macro(clearFindMPIVariables)
    unset(MPI_FOUND)
    foreach ( _lang C CXX Fortran)
        unset(MPI_${_lang}_FOUND)
        unset(MPI_${_lang}_COMPILER)
        unset(MPI_${_lang}_COMPILER_FLAGS)
        unset(MPI_${_lang}_INCLUDE_PATH)
        unset(MPI_${_lang}_LINK_FLAGS)
        unset(MPI_${_lang}_LIBRARIES)
    endforeach ()
    unset(MPI_Fortran_MODULE_COMPATIBLE)
    unset(MPI_DETECTED)
    unset(MPIEXEC CACHE)
    unset(MPIEXEC_NUMPROC_FLAG CACHE)
    unset(MPIEXEC_PREFLAGS CACHE)
    unset(MPIEXEC_POSTFLAGS CACHE)
    unset(MPIEXEC_MAX_NUMPROCS CACHE)
endmacro()

unset(SUGGESTED_MPI)
# MPI_HOME specified - use that and fail if there's no MPI
# We also infer the MPI mnemonic from the installation at MPI_HOME
if (DEFINED MPI_HOME AND NOT MPI_HOME STREQUAL "")
    log("Using MPI implementation at MPI_HOME=${MPI_HOME}")
    find_package(MPI QUIET)
    if (NOT MPI_FOUND)
        log("No MPI implementation found at MPI_HOME. Please check." ERROR)
    endif()
    if (NOT DEFINED OPENCMISS_MPI)
        # MPI_DETECTED is set by FindMPI.cmake to one of the mnemonics or unknown (MPI_TYPE_UNKNOWN in FindMPI.cmake)
        set(OPENCMISS_MPI ${MPI_DETECTED} CACHE STRING "Detected MPI implementation" FORCE)
    endif()
    if (NOT DEFINED OPENCMISS_MPI_BUILD_TYPE)
        set(OPENCMISS_MPI_BUILD_TYPE USER_MPIHOME)
        log("Using MPI via MPI_HOME variable.
If you want to use different build types for the same MPI implementation, please
you have to specify OPENCMISS_MPI_BUILD_TYPE. Using '${OPENCMISS_MPI_BUILD_TYPE}'.
https://github.com/OpenCMISS/manage/issues/28        
        " WARNING)
    endif()
else ()
    # Ensure lower-case mpi and upper case mpi build type
    # Whether to allow a system search for MPI implementations
    option(OPENCMISS_MPI_USE_SYSTEM "Allow to use a system MPI if found" YES)
    if (DEFINED OPENCMISS_MPI)
        string(TOLOWER ${OPENCMISS_MPI} OPENCMISS_MPI)
        set(OPENCMISS_MPI ${OPENCMISS_MPI} CACHE STRING "User-specified MPI implementation" FORCE)
        set(_USER_SPECIFIED_MPI_FLAG TRUE) # ${OPENCMISS_MPI})
		log("Setting user specified MPI to TRUE")
    endif()
    if (DEFINED OPENCMISS_MPI_BUILD_TYPE)
        capitalise(${OPENCMISS_MPI_BUILD_TYPE})
        set(OPENCMISS_MPI_BUILD_TYPE ${OPENCMISS_MPI_BUILD_TYPE} CACHE STRING "User-specified MPI build type" FORCE)
    else()
        if (DEFINED OC_DEFAULT_MPI_BUILD_TYPE)
            set(OPENCMISS_MPI_BUILD_TYPE ${OC_DEFAULT_MPI_BUILD_TYPE} CACHE STRING "MPI build type, initialized to default of ${OC_DEFAULT_MPI_BUILD_TYPE}")
        else()
            set(OPENCMISS_MPI_BUILD_TYPE Release CACHE STRING "MPI build type, initialized to default of Release")
        endif()
    endif()
    if (OPENCMISS_MPI_BUILD_TYPE STREQUAL Debug AND OPENCMISS_MPI_USE_SYSTEM)
        log("Cannot have debug MPI builds and OPENCMISS_MPI_USE_SYSTEM at the same time. Setting OPENCMISS_MPI_USE_SYSTEM=OFF" WARNING)
        set(OPENCMISS_MPI_USE_SYSTEM OFF CACHE BOOL "Allow to use a system MPI if found" FORCE)
    endif()
    
    # We did not get any user choice in terms of MPI
    if(NOT DEFINED OPENCMISS_MPI)
        set(_USER_SPECIFIED_MPI_FLAG FALSE)
        # No OPENCMISS_MPI or MPI_HOME - let cmake look and find the default MPI.
        if(OPENCMISS_MPI_USE_SYSTEM)
            log("Looking for default system MPI...")
            find_package(MPI QUIET)
			log("System MPI found: ${MPI_DETECTED}, ${MPI_FOUND}")
        endif()
        
        # If there's a system MPI, set MPI to the detected version
        if (MPI_FOUND)
            # MPI_DETECTED is set by FindMPI.cmake to one of the mnemonics or unknown (MPI_TYPE_UNKNOWN in FindMPI.cmake)
            set(OPENCMISS_MPI ${MPI_DETECTED} CACHE STRING "Detected MPI implementation" FORCE)
            log("Found '${OPENCMISS_MPI}'")
        else()
            # No MPI found - Prescribe a reasonable system default choice and go with that
            if (UNIX AND NOT APPLE)
                if (NOT DEFINED LINUX_DISTRIBUTION)
                    SET(LINUX_DISTRIBUTION FALSE CACHE STRING "Distribution information")
                    find_program(LSB lsb_release
                        DOC "Distribution information tool")
                    if (LSB)
                        execute_process(COMMAND ${LSB} -i
                            RESULT_VARIABLE RETFLAG
                            OUTPUT_VARIABLE DISTINFO
                            ERROR_VARIABLE ERRDISTINFO
                            OUTPUT_STRIP_TRAILING_WHITESPACE
                        )
                        if (NOT RETFLAG)
                            STRING(SUBSTRING ${DISTINFO} 16 -1 LINUX_DISTRIBUTION)
                        endif()
                    endif()
                endif()
                if (LINUX_DISTRIBUTION STREQUAL "Ubuntu" OR LINUX_DISTRIBUTION STREQUAL "Scientific" OR LINUX_DISTRIBUTION STREQUAL "Arch")
                    SET(SUGGESTED_MPI mpich) # Previously this was openmpi but this doesn't work well when used through Python bindings.
                elseif(LINUX_DISTRIBUTION STREQUAL "Fedora" OR LINUX_DISTRIBUTION STREQUAL "RedHat")
                    SET(SUGGESTED_MPI mpich)
                endif()
                if (SUGGESTED_MPI)
                    log("No MPI preferences given. We suggest '${SUGGESTED_MPI}' on Linux/${LINUX_DISTRIBUTION}")
                else()
                    log("Unknown distribution '${LINUX_DISTRIBUTION}': No default MPI recommendation implemented. Using '${OC_DEFAULT_MPI}'" WARNING)
                    SET(SUGGESTED_MPI ${OC_DEFAULT_MPI})
                endif()
            elseif(APPLE)
                set(SUGGESTED_MPI mpich) # Previously this was openmpi but this doesn't work well when used through Python bindings.
            elseif(WIN32)
                set(SUGGESTED_MPI msmpi)
            else()
                log("No default MPI suggestion implemented for your platform. Using '${OC_DEFAULT_MPI}'" WARNING)
                SET(SUGGESTED_MPI ${OC_DEFAULT_MPI})
            endif()
            log("No MPI found - setting suggested MPI: ${SUGGESTED_MPI}")
            set(OPENCMISS_MPI ${SUGGESTED_MPI} CACHE STRING "Auto-suggested MPI implementation" FORCE)
        endif()
    endif()
endif()

####################################################################################################
# Find local MPI (own build dir or system-wide)
####################################################################################################
# As of here we always have an MPI mnemonic set, either by manual definition or detection
# of default MPI type. In the latter case we already have MPI_FOUND=TRUE.

# This variable is also used in the main CMakeLists file at path computations!
string(TOLOWER "${OPENCMISS_MPI_BUILD_TYPE}" MPI_BUILD_TYPE_LOWER)

if (NOT MPI_FOUND AND OPENCMISS_MPI_USE_SYSTEM) 
    # Educated guesses are used to look for an MPI implementation
    # This bit of logic is covered inside the FindMPI module where MPI is consumed
    log("Looking for '${OPENCMISS_MPI}' MPI on local system.")
    set(_CLEAR_MPI_VARIABLE FALSE)
    if (_USER_SPECIFIED_MPI_FLAG OR (NOT _USER_SPECIFIED_MPI_FLAG AND DEFINED SUGGESTED_MPI))
        set(_CLEAR_MPI_VARIABLE TRUE)
        set(MPI ${OPENCMISS_MPI})
        if (_USER_SPECIFIED_MPI_FLAG)
            log("Looking for MPI: ${MPI} specified by user.")
        else ()
            log("Looking for MPI: ${MPI} suggested by us.")
        endif ()
    endif ()
    find_package(MPI QUIET)
    if (_CLEAR_MPI_VARIABLE)
        unset(MPI)
    endif ()
endif()


# Last check before building - there might be an own already built MPI implementation
if (NOT MPI_FOUND)
    if (OPENCMISS_MPI_USE_SYSTEM)
        log("No (matching) system MPI found.")    
    endif()
    log("Checking if own build already exists.")
    
    # Construct installation path
    # For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
    # MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
    # Only the debug/release versions of MPI are located in different folders (for own builds only - the behaviour using system mpi
    # in debug mode is unspecified)
    set(_OWN_INSTALL_ARCH_PATH .)
    if (OPENCMISS_USE_ARCHITECTURE_PATH)
        getSystemPartArchitecturePath(SYSTEM_PART_ARCH_PATH)
        set(_OWN_INSTALL_ARCH_PATH ${SYSTEM_PART_ARCH_PATH}/no_mpi)
    endif()

    # This is where our own build of MPI will reside if compilation is needed
    set(OPENCMISS_OWN_MPI_INSTALL_PREFIX ${OPENCMISS_OWN_MPI_INSTALL_BASE}/${_OWN_INSTALL_ARCH_PATH}/${OPENCMISS_MPI}/${MPI_BUILD_TYPE_LOWER})

    # Set MPI_HOME to the install location - its not set outside anyways (see first if case at top)
    # Important: Do not unset(MPI_HOME) afterwards - this needs to get passed to all external projects the same way
    # it has been after building MPI in the first place.
    set(OPENCMISS_MPI_HOME "${OPENCMISS_OWN_MPI_INSTALL_PREFIX}" CACHE STRING "Installation directory of own/local MPI build" FORCE)
    set(MPI_HOME ${OPENCMISS_MPI_HOME})
    find_package(MPI QUIET)
    if (MPI_FOUND)
        log("Using own MPI: '${OPENCMISS_MPI}' found at ${OPENCMISS_MPI_HOME}")
    else ()
        unset(MPI_HOME)
    endif()
endif()

if (NOT MPI_FOUND)
    set(_NOT "not ")
endif ()
log("MPI is set to: ${OPENCMISS_MPI}, and it is ${_NOT}available")
unset(_NOT)
