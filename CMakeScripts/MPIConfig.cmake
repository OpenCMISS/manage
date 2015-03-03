########################################################################
# This script takes care of all the MPI subtleties 
# and is only executed if "OCM_USE_MPI" is TRUE.
#
# The logic is as follows, and is implemented partially here and in the FindMPI.cmake module.
# The "communication interface" between the two scripts are the MPI/MPI_HOME/ADDITIONAL_MPI_PATHS variables
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

# Cleanup - Have cmake truly re-look for everything MPI-related.
# This is ONLY here because if this fails in the first run, then the own mpi is used, the next run will
# detect the own mpi already here as paths and compilers are cached.
UNSET(MPIEXEC CACHE)
foreach (lang C CXX Fortran)
    UNSET(MPI_${lang}_INCLUDE_PATH CACHE)
    UNSET(MPI_${lang}_LIBRARIES CACHE)
    UNSET(MPI_${lang}_COMPILER CACHE)
    SET(MPI_${lang}_FOUND FALSE) 
endforeach()

############################################################################################
# No MPI mnemonic specified - use defaults as good as possible
############################################################################################
# The default implementation to use in all last-resort/unimplemented cases
SET(OPENCMISS_MPI_DEFAULT mpich)

#@3. MPI_HOME specified - use that and fail if there's no MPI
if(DEFINED MPI_HOME)
    find_package(MPI QUIET)
    if (NOT MPI_FOUND)
        message(FATAL_ERROR "No MPI found at MPI_HOME=${MPI_HOME}")
    endif()
# @1. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
elseif(NOT DEFINED MPI)
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
endif()

# @2. MPI mnemonic/variable specified: As of here we always have MPI specified, either directly, detected or suggested.

#################################
# Construct installation path
# For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
# MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
get_architecture_path(ARCHITECTURE_PATH_MPI SHORT)
get_build_type_extra(BUILDTYPEEXTRA)
set(_MPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/${ARCHITECTURE_PATH_MPI}/mpi/${MPI}/${BUILDTYPEEXTRA})
# Always have FindMPI look at our own install location as last resort
SET(ADDITIONAL_MPI_PATHS ${_MPI_INSTALL_DIR})
    
#################################
# Look again if not yet found
# Only bother if we dont have the auto-detect + infer type case above, meaning 
if(NOT MPI_FOUND)
    # If no system MPI is allowed, search ONLY at MPI_HOME
    if(NOT OCM_SYSTEM_MPI)
        set(MPI_HOME ${_MPI_INSTALL_DIR})
    else()
        # Educated guesses are used to look for an MPI implementation
        # This bit of logic is covered inside the FindMPI module where MPI is consumed
        message(STATUS "Looking for ${MPI} including local system..")
    endif()
    
    # This call either only looks at MPI_HOME if no system lookup is allowed or searches at system locations + ADDITIONAL_MPI_PATHS
    find_package(MPI QUIET)
endif()

#####################################################################
# MPI build
#####################################################################
# If we get here without having found an MPI implementation, we need to build it.
# But we will always have the MPI mnemonic set if we reach here.
if (NOT MPI_FOUND)
    # This is supported yet only on Unix systems
    if (UNIX)
        # Set the forward dependencies of MPI only if we build it ourselves
        SET(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
        # The choice is ... 
        if (MPI STREQUAL openmpi)
            SET(_MPI_VERSION ${OPENMPI_VERSION})
            SET(_MPI_EXTRA_PARAMS )
        elseif (MPI STREQUAL mpich)
            SET(_MPI_VERSION ${MPICH_VERSION})
            if (CMAKE_BUILD_TYPE STREQUAL RELEASE)
                SET(_MPI_EXTRA_PARAMS "--enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars")
            elseif(CMAKE_BUILD_TYPE STREQUAL DEBUG)
                SET(_MPI_EXTRA_PARAMS "--disable-fast")
            endif()
        elseif (MPI STREQUAL mvapich2)
            SET(_MPI_VERSION ${MVAPICH2_VERSION})
            if (CMAKE_BUILD_TYPE STREQUAL RELEASE)
                SET(_MPI_EXTRA_PARAMS "--enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars")
            elseif(CMAKE_BUILD_TYPE STREQUAL DEBUG)
                SET(_MPI_EXTRA_PARAMS "--disable-fast")
            endif()
        else()
    	    message(FATAL_ERROR "Own build of MPI - ${MPI} not yet implemented")
        endif()
        
        message(STATUS "Using shipped MPI (${MPI}-${_MPI_VERSION})")
        
        set(MPI_HOME ${_MPI_INSTALL_DIR})   
        SET(_MPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/dependencies/${MPI})
        SET(_MPI_BINARY_DIR ${OPENCMISS_ROOT}/build/${ARCHITECTURE_PATH_MPI}/mpi/${MPI}/${BUILDTYPEEXTRA})
        SET(_MPI_BRANCH v${_MPI_VERSION})
        
        message(STATUS "Configuring build of MPI (${MPI}-${_MPI_VERSION}) in ${_MPI_BINARY_DIR}...")
        
        ExternalProject_Add(MPI
    		PREFIX ${_MPI_BINARY_DIR}
    		TMP_DIR ${_MPI_BINARY_DIR}/ep_tmp
    		STAMP_DIR ${_MPI_BINARY_DIR}/ep_stamp
    		
    		#--Download step--------------
    		DOWNLOAD_DIR ${_MPI_SOURCE_DIR}/src-download
            URL https://github.com/OpenCMISS-Dependencies/${MPI}/archive/${_MPI_BRANCH}.zip
            #http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.4.tar.gz
            #URL_HASH SHA1=22002fc226f55e188e21be0fdc3602f8d024e7ba
             
    		#--Configure step-------------
    		SOURCE_DIR ${_MPI_SOURCE_DIR}
    		CONFIGURE_COMMAND ${_MPI_SOURCE_DIR}/configure 
    		    --prefix ${_MPI_INSTALL_DIR}
    		    CC=${CMAKE_C_COMPILER}
    		    CXX=${CMAKE_CXX_COMPILER}
    		    FC=${CMAKE_Fortran_COMPILER}
    		    ${_MPI_EXTRA_PARAMS}
    		BINARY_DIR ${_MPI_BINARY_DIR}
    		
    		#--Build step-----------------
    		BUILD_COMMAND make -j12 #${BUILD_COMMAND}
    		
    		#--Install step---------------
    		# currently set as extra arg (above), somehow does not work
    		#INSTALL_DIR ${OPENMPI_INSTALL_DIR}
    		INSTALL_COMMAND make install #${INSTALL_COMMAND}
    		
    		#LOG_CONFIGURE 1
    		#LOG_BUILD 1
    		#LOG_INSTALL 1
    	)
    ADD_DOWNSTREAM_DEPS(MPI)
    else()
        message(FATAL_ERROR "MPI (${MPI}) installation support not yet implemented for this platform.")
    endif()
endif()