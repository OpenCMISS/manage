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
UNSET(MPIEXEC CACHE)
UNSET(MPI_FOUND CACHE)
foreach (lang C CXX Fortran)
    UNSET(MPI_${lang}_INCLUDE_PATH CACHE)
    UNSET(MPI_${lang}_LIBRARIES CACHE)
    UNSET(MPI_${lang}_COMPILER CACHE)
    SET(MPI_${lang}_FOUND FALSE)
endforeach()

# The default implementation to use in all last-resort/unimplemented cases
SET(OPENCMISS_MPI_DEFAULT mpich)

# We did not get any user choice in terms of MPI
if(NOT DEFINED MPI)
    # MPI_HOME specified - use that and fail if there's no MPI
    if (DEFINED MPI_HOME)
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
        # If we find MPI, we need to infer the MPI implementation for use in e.g. architecture paths
        SET(MNEMONICS mpich mpich2 openmpi intel mvapich2 msmpi)
        # Patterns to match the include path
        SET(PATTERNS ".*mpich([/|-].*|$)" ".*mpich(2)?([/|-].*|$)" ".*openmpi([/|-].*|$)"
         ".*(intel|impi)[/|-].*" ".*mvapich(2)?([/|-].*|$)" ".*microsoft(.*|$)")
        foreach(IDX RANGE 5)
            LIST(GET MNEMONICS ${IDX} MNEMONIC)
            LIST(GET PATTERNS ${IDX} PATTERN)
            STRING(TOLOWER "${MPI_C_INCLUDE_PATH}" C_INC_PATH)
            STRING(TOLOWER "${MPI_CXX_INCLUDE_PATH}" CXX_INC_PATH)
            message(STATUS "Architecture: checking '${MPI_C_INCLUDE_PATH} MATCHES ${PATTERN} OR ${MPI_CXX_INCLUDE_PATH} MATCHES ${PATTERN}'")
            if (C_INC_PATH MATCHES ${PATTERN} OR CXX_INC_PATH MATCHES ${PATTERN})
                SET(DETECTED_MPI ${MNEMONIC})
                break()
            endif()
        endforeach()
        if (NOT DETECTED_MPI)
            if (MPI_C_COMPILER)
                get_filename_component(COMP_NAME ${MPI_C_COMPILER} NAME)
                STRING(TOLOWER DETECTED_MPI "unknown_${COMP_NAME}")
            else()
                SET(DETECTED_MPI "unknown") # This value is also checked against in FindMPI.cmake!
            endif()
            message(WARNING "MPI compiler '${MPI_C_COMPILER}' with include path '${MPI_C_INCLUDE_PATH}' not recognized.")
        endif()
        set(MPI ${DETECTED_MPI} CACHE STRING "Detected MPI implementation" FORCE)
        unset(DETECTED_MPI)
    else()
        # No MPI found - Prescribe a reasonable system default choice and go with that
        if (UNIX)
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
        else()
            message(WARNING "No default MPI suggestion implemented for your platform. Using '${OPENCMISS_MPI_DEFAULT}'")
            SET(SUGGESTED_MPI ${OPENCMISS_MPI_DEFAULT})
        endif()
        set(MPI ${SUGGESTED_MPI} CACHE STRING "Auto-suggested MPI implementation" FORCE)
        unset(SUGGESTED_MPI)
    endif()
endif()
