function(messaged msg)
    #message(STATUS "@OCMPIConfig: ${msg}")
endfunction()
messaged("Entering script")
#################################
# Construct installation path
# For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
# MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
# Only the debug/release versions of MPI are located in different folders (for own builds only - the behaviour using system mpi
# in debug mode is unspecified)
set(SHORT_ARCH_PATH .)
if (OCM_USE_ARCHITECTURE_PATH)
    getShortArchitecturePath(SHORT_ARCH_PATH)
endif()
# This is where our own build of MPI will reside if compilation is needed
set(OWN_MPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/${SHORT_ARCH_PATH}/mpi/${MPI}/${MPI_BUILD_TYPE})
    
if (NOT DEFINED MPI_HOME)
    # If no system MPI is allowed, search ONLY at MPI_HOME, which is our own bake
    if(NOT OCM_SYSTEM_MPI)
        set(MPI_HOME ${OWN_MPI_INSTALL_DIR})
        messaged("Setting MPI_HOME=${MPI_HOME}")
    else()
        # Educated guesses are used to look for an MPI implementation
        # This bit of logic is covered inside the FindMPI module where MPI is consumed
        message(STATUS "Looking for '${MPI}' on local system..")
    endif()
endif()

# This call either only looks at MPI_HOME if no system lookup is allowed or searches at system locations
find_package(MPI QUIET)

#####################################################################
# MPI build
#####################################################################
# If we get here without having found an MPI implementation, we need to build it.
# But we will always have the MPI mnemonic set if we reach here.
if (NOT MPI_FOUND)
    messaged("No system MPI found or not allowed: OCM_SYSTEM_MPI=${OCM_SYSTEM_MPI}")
    # This is supported yet only on Unix systems
    if (UNIX)
        # No shared libs!
        set(_MPI_EXTRA_PARAMS --disable-shared) 
        if (MPI STREQUAL openmpi)
            # We need to build a static version of MPI so that symbols get pulled into iron
            # Having a shared-version of OpenMPI wont work with Python bindings
            # See http://stackoverflow.com/questions/26901663/error-when-running-openmpi-based-library
            # This is also the default in the old build system.
            set(_MPI_VERSION ${OPENMPI_VERSION})
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
            SET(_MPI_VERSION ${MPICH_VERSION})
            if (MPI_BUILD_TYPE STREQUAL release)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(MPI_BUILD_TYPE STREQUAL debug)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast)
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        elseif (MPI STREQUAL mvapich2)
            SET(_MPI_VERSION ${MVAPICH2_VERSION})
            if (MPI_BUILD_TYPE STREQUAL release)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(MPI_BUILD_TYPE STREQUAL debug)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast)
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        else()
    	    message(FATAL_ERROR "Own build of MPI - ${MPI} not yet implemented")
        endif()
        
        message(STATUS "Using shipped MPI (${MPI}-${_MPI_VERSION})")
        
        set(MPI_HOME ${OWN_MPI_INSTALL_DIR})
        SET(_MPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/dependencies/${MPI})
        SET(_MPI_BINARY_DIR ${OPENCMISS_ROOT}/build/${SHORT_ARCH_PATH}/mpi/${MPI}/${MPI_BUILD_TYPE})
        SET(_MPI_BRANCH v${_MPI_VERSION})
        
        message(STATUS "Configuring build of MPI (${MPI}-${_MPI_VERSION})")
        message(STATUS "Location: ${_MPI_BINARY_DIR}")
        message(STATUS "Extra build parameters: ${_MPI_EXTRA_PARAMS}")
        
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
            SET(NUM_PROCESSORS 1)
        #else()
        #    MATH(EXPR NUM_PROCESSORS ${NUM_PROCESSORS}+4)
        endif()
        
        string(TOUPPER ${MPI_BUILD_TYPE} _TYPE)
        ExternalProject_Add(MPI
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
    		    CFLAGS=-fPIC #${CMAKE_C_FLAGS_${_TYPE}} #TODO: does it make sense to pass on the flags to the mpi build?
    		    CXXFLAGS=-fPIC #${CMAKE_CXX_FLAGS_${_TYPE}}
    		    FFLAGS=-fPIC #${CMAKE_Fortran_FLAGS_${_TYPE}}
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
        SET(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
        addDownstreamDependencies(MPI FALSE)
    else()
        message(FATAL_ERROR "MPI (${MPI}) installation support not yet implemented for this platform.")
    endif()
else()
    messaged("Found MPI: ${MPI_C_INCLUDE_DIRECTORIES} / ${MPI_C_LIBRARIES}")    
endif()