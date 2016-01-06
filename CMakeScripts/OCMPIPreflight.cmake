########################################################################
# This script takes care to have the right MPI mnemonic set to be able to generate the main build config folder.
#
# The case of "no MPI" is not implemented yet, but can easily be done by having to specify "MPI=NO" and let the script
# handle it.
#
# 1. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
#  a. SYSTEM_MPI = NO AND/OR No MPI found - Prescribe a reasonable system default choice and go with that
#  b. SYSTEM_MPI = YES AND MPI found - Use the MPI implementation found on PATH/environment 
# 2. MPI_HOME specified - Look exclusively at that location for binaries/libraries
#  a. MPI FOUND - ok, detect type and forward that
#  b. MPI NOT FOUND - Error and abort
# 3. MPI mnemonic/variable specified
#  Just forward that to the generated script

# Cleanup - Have cmake truly re-look for everything MPI-related, the generation phase
# is all about setup and does not need a cache
unset(MPIEXEC CACHE)
unset(MPI_FOUND CACHE)
foreach (lang C CXX Fortran)
    unset(MPI_${lang}_INCLUDE_PATH CACHE)
    unset(MPI_${lang}_LIBRARIES CACHE)
    unset(MPI_${lang}_COMPILER CACHE)
    set(MPI_${lang}_FOUND FALSE)
endforeach()

# Ensure lower-case mpi and upper case mpi build type
# Whether to allow a system search for MPI implementations
option(SYSTEM_MPI "Allow to use a system MPI if found" YES)
if (DEFINED MPI)
    string(TOLOWER ${MPI} MPI)
    set(MPI ${MPI} CACHE STRING "User-specified MPI implementation" FORCE)
endif()
if (DEFINED MPI_BUILD_TYPE)
    string(TOUPPER ${MPI_BUILD_TYPE} MPI_BUILD_TYPE)
    set(MPI_BUILD_TYPE ${MPI_BUILD_TYPE} CACHE STRING "User-specified MPI build type" FORCE)
else()
    set(MPI_BUILD_TYPE RELEASE CACHE STRING "MPI build type, initialized to default")    
endif()
if (MPI_BUILD_TYPE STREQUAL DEBUG AND SYSTEM_MPI)
    message(WARNING "Cannot have debug MPI builds and SYSTEM_MPI at the same time. Setting SYSTEM_MPI=OFF")
    set(SYSTEM_MPI OFF CACHE BOOL "Allow to use a system MPI if found" FORCE)
endif()

# The default implementation to use in all last-resort/unimplemented cases
SET(OPENCMISS_MPI_DEFAULT mpich)

# Check if a new MPI_HOME was specified
set(RECHECK_MPI FALSE)
if (MPI_HOME_OLD AND NOT MPI_HOME_OLD STREQUAL MPI_HOME)
    set(RECHECK_MPI TRUE)
    unset(MPI CACHE) # Currently also unsets MPI locally - contrary to documentation (cmake 3.4)
    unset(MPI)
endif()

# We did not get any user choice in terms of MPI
if(NOT DEFINED MPI)
    # MPI_HOME specified - use that and fail if there's no MPI
    if (DEFINED MPI_HOME AND NOT MPI_HOME STREQUAL "")
        find_package(MPI QUIET)
        if (NOT MPI_FOUND)
            message(FATAL_ERROR "No MPI found at MPI_HOME=${MPI_HOME}")
        endif()
    # No MPI or MPI_HOME - let cmake look and find MPI.
    elseif(SYSTEM_MPI)
        message(STATUS "Looking for system MPI...")
        find_package(MPI)
    endif()

    # If we have found MPI by now, it's either system MPI or the one specified at MPI_HOME.
    # Either way, we need to infer the MPI implementation from that.
    if (MPI_FOUND)
        # MPI_DETECTED is set by FindMPI.cmake to one of the mnemonics or unknown (MPI_TYPE_UNKNOWN in FindMPI.cmake)
        set(MPI ${MPI_DETECTED} CACHE STRING "Detected MPI implementation" FORCE)
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
                SET(SUGGESTED_MPI openmpi)
            elseif(LINUX_DISTRIBUTION STREQUAL "Fedora" OR LINUX_DISTRIBUTION STREQUAL "RedHat")
                SET(SUGGESTED_MPI mpich)
            endif()
            if (SUGGESTED_MPI)
                message(STATUS "No MPI preferences given. We suggest '${SUGGESTED_MPI}' on Linux/${LINUX_DISTRIBUTION}")
            else()
                message(WARNING "Unknown distribution '${LINUX_DISTRIBUTION}': No default MPI recommendation implemented. Using '${OPENCMISS_MPI_DEFAULT}'")
                SET(SUGGESTED_MPI ${OPENCMISS_MPI_DEFAULT})
            endif()
        elseif(APPLE)
            set(SUGGESTED_MPI openmpi)
        else()
            message(WARNING "No default MPI suggestion implemented for your platform. Using '${OPENCMISS_MPI_DEFAULT}'")
            SET(SUGGESTED_MPI ${OPENCMISS_MPI_DEFAULT})
        endif()
        set(MPI ${SUGGESTED_MPI} CACHE STRING "Auto-suggested MPI implementation" FORCE)
        unset(SUGGESTED_MPI)
    endif()
endif()

# Store the current MPI_HOME
set(MPI_HOME_OLD "${MPI_HOME}" CACHE INTERNAL "Latest value of MPI_HOME")