########################################################################
# This script takes care to have the right MPI mnemonic set and configures
# own MPI builds
#
# The case of "no MPI" is not implemented yet, but can easily be done by having to specify "MPI=none" and let the script
# handle it.
#
# 1. MPI_HOME specified - Look exclusively at that location for binaries/libraries
#  a. MPI FOUND - ok, detect type and forward that
#  b. MPI NOT FOUND - Error and abort
# 2. Nothing specified - Call FindMPI and let it come up with whatever is found on the default path
#  a. SYSTEM_MPI = NO AND/OR No MPI found - Prescribe a reasonable system default choice and go with that
#  b. SYSTEM_MPI = YES AND MPI found - Use the MPI implementation found on PATH/environment 
# 3. MPI mnemonic/variable specified
#  Just forward that to the generated script

# MPI_HOME specified - use that and fail if there's no MPI
# We also infer the MPI mnemonic from the installation at MPI_HOME
if (DEFINED MPI_HOME AND NOT MPI_HOME STREQUAL "")
    log("Attempting to find an MPI implementation at MPI_HOME=${MPI_HOME}")
    # We ignore any set value of MPI if MPI_HOME is given - it's inferred in this case
    unset(MPI )
    find_package(MPI REQUIRED)
    # MPI_DETECTED is set by FindMPI.cmake to one of the mnemonics or unknown (MPI_TYPE_UNKNOWN in FindMPI.cmake)
    set(MPI ${MPI_DETECTED} CACHE STRING "Detected MPI implementation" FORCE)
    if (NOT DEFINED MPI_BUILD_TYPE)
        log("Using MPI via MPI_HOME variable.
If you want to use different build types for the same MPI implementation, please
you have to specify MPI_BUILD_TYPE
https://github.com/OpenCMISS/manage/issues/28        
        " WARNING)
    endif()
else()

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
        log("Cannot have debug MPI builds and SYSTEM_MPI at the same time. Setting SYSTEM_MPI=OFF" WARNING)
        set(SYSTEM_MPI OFF CACHE BOOL "Allow to use a system MPI if found" FORCE)
    endif()
    
    # We did not get any user choice in terms of MPI
    if(NOT DEFINED MPI)
        # No MPI or MPI_HOME - let cmake look and find the default MPI.
        if(SYSTEM_MPI)
            log("Looking for system MPI...")
            find_package(MPI QUIET)
        endif()
        
        # If there's a system MPI, set MPI to the detected version
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
                    log("No MPI preferences given. We suggest '${SUGGESTED_MPI}' on Linux/${LINUX_DISTRIBUTION}")
                else()
                    log("Unknown distribution '${LINUX_DISTRIBUTION}': No default MPI recommendation implemented. Using '${OPENCMISS_MPI_DEFAULT}'" WARNING)
                    SET(SUGGESTED_MPI ${OPENCMISS_MPI_DEFAULT})
                endif()
            elseif(APPLE)
                set(SUGGESTED_MPI openmpi)
            else()
                log("No default MPI suggestion implemented for your platform. Using '${OPENCMISS_MPI_DEFAULT}'" WARNING)
                SET(SUGGESTED_MPI ${OPENCMISS_MPI_DEFAULT})
            endif()
            set(MPI ${SUGGESTED_MPI} CACHE STRING "Auto-suggested MPI implementation" FORCE)
            unset(SUGGESTED_MPI)
        endif()
    endif()
endif()

####################################################################################################
# Find local MPI (own build dir or system-wide)
####################################################################################################
# As of here we always have an MPI mnemonic set.

# This variable is also used in the main CMakeLists file at path computations!
string(TOLOWER "${MPI_BUILD_TYPE}" MPI_BUILD_TYPE_LOWER)

if (NOT MPI_FOUND)
    # Construct installation path
    # For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
    # MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
    # Only the debug/release versions of MPI are located in different folders (for own builds only - the behaviour using system mpi
    # in debug mode is unspecified)
    set(SHORT_ARCH_PATH .)
    if (OC_USE_ARCHITECTURE_PATH)
        getShortArchitecturePath(SHORT_ARCH_PATH)
    endif()
    # This is where our own build of MPI will reside if compilation is needed    
    set(OWN_MPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/${SHORT_ARCH_PATH}/mpi/${MPI}/${MPI_BUILD_TYPE_LOWER})
    
    # If no system MPI is allowed, search ONLY at MPI_HOME, which is our own bake
    if(NOT SYSTEM_MPI)
        set(MPI_HOME ${OWN_MPI_INSTALL_DIR})
        log("Using own MPI '${MPI}': Setting MPI_HOME=${MPI_HOME}" DEBUG)
    else()
        # Educated guesses are used to look for an MPI implementation
        # This bit of logic is covered inside the FindMPI module where MPI is consumed
        log("Looking for '${MPI}' MPI on local system..")
    endif()
    # This call either only looks at MPI_HOME if no system lookup is allowed or searches at system locations
    find_package(MPI QUIET)
endif()

#####################################################################
# MPI build
#####################################################################
# If we get here without having found an MPI implementation, we need to build it.
# But we will always have the MPI mnemonic set if we reach here.
if (NOT MPI_FOUND)
    log("No system MPI found or not allowed: SYSTEM_MPI=${SYSTEM_MPI}" DEBUG)
    # This is supported yet only on Unix systems
    if (UNIX)
        # No shared libs!
        set(_MPI_EXTRA_PARAMS --disable-shared)
        set(MPI_C_FLAGS -fPIC) 
        if (MPI STREQUAL openmpi)
            # We need to build a static version of MPI so that symbols get pulled into iron
            # Having a shared-version of OpenMPI wont work with Python bindings
            # See http://stackoverflow.com/questions/26901663/error-when-running-openmpi-based-library
            # This is also the default in the old build system.
            set(_MPI_VERSION ${OPENMPI_VERSION})
            # HACK: disabling the shared builds for openmpi somehow causes error messages even though the code should have
            # been compiled with -fPIC :-( so we'll disable it for now (only relevant for remote installation stuff)
            set(_MPI_EXTRA_PARAMS )
            list(APPEND _MPI_EXTRA_PARAMS --enable-static --disable-heterogeneous)
            if (CMAKE_C_COMPILER_ID MATCHES Intel)
                list(APPEND _MPI_EXTRA_PARAMS --enable-contrib-no-build=libnbc,vt)
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        elseif (MPI STREQUAL mpich)
            set(_MPI_VERSION ${MPICH_VERSION})
            if (MPI_BUILD_TYPE STREQUAL RELEASE)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(MPI_BUILD_TYPE STREQUAL DEBUG)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast --enable-g=all)
                set(MPI_C_FLAGS "${MPI_C_FLAGS} -g3")
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        elseif (MPI STREQUAL mvapich2)
            set(_MPI_VERSION ${MVAPICH2_VERSION})
            if (MPI_BUILD_TYPE STREQUAL RELEASE)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(MPI_BUILD_TYPE STREQUAL DEBUG)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast --enable-g=all)
                set(MPI_C_FLAGS "${MPI_C_FLAGS} -g3")
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        else()
    	    log("Own build of MPI - ${MPI} not yet implemented" ERROR)
        endif()
        
        set(MPI_HOME ${OWN_MPI_INSTALL_DIR})
        set(_MPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/dependencies/${MPI})
        set(_MPI_BINARY_DIR ${OPENCMISS_ROOT}/build/${SHORT_ARCH_PATH}/mpi/${MPI}/${MPI_BUILD_TYPE_LOWER})
        set(_MPI_BRANCH v${_MPI_VERSION})
        
        log("Configuring build of 'MPI' (${MPI}-${_MPI_VERSION}) in ${_MPI_BINARY_DIR}...")
        log("Extra MPI build parameters: ${_MPI_EXTRA_PARAMS}" DEBUG)
        
        # Dont download again if the target source folder already contains files 
        file(GLOB _MPI_FILES ${_MPI_SOURCE_DIR}/)
        set(DOWNLOAD_COMMANDS DOWNLOAD_COMMAND "")
        if("" STREQUAL "${_MPI_FILES}")
            set(DOWNLOAD_COMMANDS 
                DOWNLOAD_DIR ${_MPI_SOURCE_DIR}/src-download
                URL https://github.com/OpenCMISS-Dependencies/${MPI}/archive/${_MPI_BRANCH}.zip
                #http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.4.tar.gz
                #URL_HASH SHA1=22002fc226f55e188e21be0fdc3602f8d024e7ba
            )
        endif()
        
        include(ProcessorCount)
        ProcessorCount(NUM_PROCESSORS)
        if (NUM_PROCESSORS EQUAL 0)
            set(NUM_PROCESSORS 1)
        #else()
        #    MATH(EXPR NUM_PROCESSORS ${NUM_PROCESSORS}+4)
        endif()
        
        ExternalProject_Add(${OC_EP_PREFIX}MPI
    		PREFIX ${_MPI_BINARY_DIR}
    		TMP_DIR ${_MPI_BINARY_DIR}/ep_tmp
    		STAMP_DIR ${_MPI_BINARY_DIR}/ep_stamp
    		
    		#--Download step--------------
    		${DOWNLOAD_COMMANDS}
             
    		#--Configure step-------------
    		SOURCE_DIR ${_MPI_SOURCE_DIR}
    		CONFIGURE_COMMAND ${_MPI_SOURCE_DIR}/configure 
    		    --prefix ${OWN_MPI_INSTALL_DIR}
    		    CC=${CMAKE_C_COMPILER}
    		    CXX=${CMAKE_CXX_COMPILER}
    		    FC=${CMAKE_Fortran_COMPILER}
    		    CFLAGS=${MPI_C_FLAGS}
    		    CXXFLAGS=-fPIC 
    		    FFLAGS=-fPIC
    		    ${_MPI_EXTRA_PARAMS}
    		BINARY_DIR ${_MPI_BINARY_DIR}
    		
    		#--Build step-----------------
    		BUILD_COMMAND make -j${NUM_PROCESSORS} #${BUILD_COMMAND}
    		
    		#--Install step---------------
    		# currently set as extra arg (above), somehow does not work
    		#INSTALL_DIR ${OPENMPI_INSTALL_DIR}
    		INSTALL_COMMAND make install #${INSTALL_COMMAND}
    		
    		#LOG_CONFIGURE 1
    		#LOG_BUILD 1
    		#LOG_INSTALL 1
    		STEP_TARGETS install
    	)
    	# Set the forward dependencies of MPI to have it build before the consuming components
        set(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
        addDownstreamDependencies(MPI FALSE)
    else()
        log("MPI (${MPI}) installation support not yet implemented for this platform." ERROR)
    endif()
else()
    log("Found MPI: ${MPI_C_INCLUDE_DIRECTORY} / ${MPI_C_LIBRARIES}" DEBUG)    
endif()