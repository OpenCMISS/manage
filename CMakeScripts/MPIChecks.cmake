########################################################################
# This script takes care of all the MPI subtleties 
# and is only executed if "OCM_USE_MPI" is TRUE.
#
# The logic is as follows, and is implemented partially here and in the FindMPI.cmake module.
# The "communication interface" between the two scripts are the MPI/MPI_HOME variables
#
# Additionally, any relevant values are passed on to any dependency that might use MPI.
# Passed on variables are MPI,MPI_HOME,MPI_<lang>_COMPILER,MPI_<lang>_FLAGS
#
# 1. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
#  a. OCM_SYSTEM_MPI = NO AND/OR No MPI found - Prescribe a reasonable system default choice and go with that
#  b. OCM_SYSTEM_MPI = YES AND MPI found - Infer the MPI implementation from the PATH and use that
# 2. MPI_HOME specified - Look exclusively at that location for binaries/libraries
#  a. MPI FOUND - ok
#  b. MPI NOT FOUND - Error and abort
# 3. MPI mnemonic/variable specified
#  a. OCM_SYSTEM_MPI = NO - Build own MPI according to choice
#  b. OCM_SYSTEM_MPI = YES - Set PATHs to educated guess and look for an MPI implementation
#     i. MPI found AND correct implementation - Go ahead and use
#     ii. MPI found AND wrong implementation - FindMPI returns MPI_FOUND false (along with a message)
#     iii. MPI NOT FOUND - Build own MPI according to choice
# 4. MPI_<lang>_COMPILER specified
#  a. Value is a full path to an executable - Interrogate that compiler and use it
#  b. Value is something else - Assume its a compiler name and use it to look for binaries having that name

############################################################################################
# No MPI mnemonic specified - use defaults as good as possible
############################################################################################
# The default implementation to use in all last-resort/unimplemented cases
SET(OPENCMISS_MPI_DEFAULT mpich)

# This bit makes sure that if no MPI was set in the configuration we infer the detected MPI from the include path.
# @1. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
if(NOT DEFINED MPI AND NOT DEFINED MPI_HOME)
    if (OCM_SYSTEM_MPI)
        # Do a quiet search without any specifications
        find_package(MPI QUIET)
        # @b. OCM_SYSTEM_MPI = YES AND MPI found - Infer the MPI implementation from the PATH and use that
        if (MPI_FOUND)
            # If we find MPI, we need to infer the MPI implementation for use in e.g. architecture paths
            SET(MNEMONICS mpich mpich2 openmpi intel mvapich2)
            # Patterns to match the include path
            SET(PATTERNS ".*mpich([/|-].*|$)" ".*mpich(2)?([/|-].*|$)" ".*openmpi([/|-].*|$)" ".*(intel|impi)[/|-].*" ".*mvapich(2)?([/|-].*|$)")
            foreach(IDX RANGE 4)
                LIST(GET MNEMONICS ${IDX} MNEMONIC)
                LIST(GET PATTERNS ${IDX} PATTERN)
                STRING(TOLOWER "${MPI_C_INCLUDE_PATH}" C_INC_PATH)
                STRING(TOLOWER "${MPI_CXX_INCLUDE_PATH}" CXX_INC_PATH)
                #message(STATUS "Architecture: checking '${MPI_C_INCLUDE_PATH} MATCHES ${PATTERN} OR ${MPI_CXX_INCLUDE_PATH} MATCHES ${PATTERN}'")
                if (C_INC_PATH MATCHES ${PATTERN} OR CXX_INC_PATH MATCHES ${PATTERN})
                    SET(MPI ${MNEMONIC})
                    break()
                endif()
            endforeach()
            if (NOT MPI)
                if (MPI_C_COMPILER)
                    get_filename_component(COMP_NAME ${MPI_C_COMPILER} NAME)
                    STRING(TOLOWER MPI "unknown_${COMP_NAME}")
                else()
                    SET(MPI "unknown-mpi")
                endif()
                message(WARNING "MPI compiler '${MPI_C_COMPILER}' with include path '${MPI_C_INCLUDE_PATH}' not recognized.")
            endif()
        endif()
    endif()
    # @a. OCM_SYSTEM_MPI = NO AND/OR No MPI found - Prescribe a reasonable system default choice and go with that
    if (NOT MPI_FOUND)
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
            if (LINUX_DISTRIBUTION STREQUAL "Ubuntu" OR LINUX_DISTRIBUTION STREQUAL "Scientific")
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
        #set(MPI ${SUGGESTED_MPI} CACHE STRING "MPI implementation" FORCE)
        set(MPI ${SUGGESTED_MPI})
        unset(SUGGESTED_MPI)
    endif()
#@3. MPI_HOME specified
elseif(DEFINED MPI_HOME)
    find_package(MPI QUIET)
    if (NOT MPI_FOUND)
        message(FATAL_ERROR "No MPI found at MPI_HOME=${MPI_HOME}")
    endif()
# @2. MPI mnemonic/variable specified
else()
    # We already have a mnemonic and allow system lookup.
    if(OCM_SYSTEM_MPI)
        message(STATUS "Starting system MPI lookup (MPI=${MPI})")
        #@b. OCM_SYSTEM_MPI = YES - Set PATHs to educated guess and look for an MPI implementation
        # This bit of logic is covered inside the FindMPI module where MPI is set
        find_package(MPI QUIET)
    endif()
    #@a. OCM_SYSTEM_MPI = NO - Build own MPI according to choice
endif()

#####################################################################
# MPI build
#####################################################################
# Later, the script MPIBuild.cmake takes care of own builds.
# It is invoked if the above did not lead to successful selection of an MPI implementation.