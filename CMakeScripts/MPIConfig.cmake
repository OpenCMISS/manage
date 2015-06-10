#################################
# Construct installation path
# For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
# MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
# Only the debug/release versions of MPI are located in different folders (for own builds only - the behaviour using system mpi
# in debug mode is unspecified) 
get_architecture_path(SHORT_ARCH_PATH SHORT)
# This is where our own build of MPI will reside if compilation is needed
set(OWN_MPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/${SHORT_ARCH_PATH}/mpi/${MPI}/${MPI_BUILD_TYPE})
    
if (NOT DEFINED MPI_HOME)
    # If no system MPI is allowed, search ONLY at MPI_HOME, which is our own bake
    if(NOT OCM_SYSTEM_MPI)
        set(MPI_HOME ${OWN_MPI_INSTALL_DIR})
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
    # This is supported yet only on Unix systems
    if (UNIX)
        # Set the forward dependencies of MPI only if we build it ourselves
        SET(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
        # The choice is ... 
        if (MPI STREQUAL openmpi)
            SET(_MPI_VERSION ${OPENMPI_VERSION})
            SET(_MPI_EXTRA_PARAMS )
            #set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            #set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            #set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        elseif (MPI STREQUAL mpich)
            SET(_MPI_VERSION ${MPICH_VERSION})
            if (MPI_BUILD_TYPE STREQUAL release)
                SET(_MPI_EXTRA_PARAMS "--enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars")
            elseif(MPI_BUILD_TYPE STREQUAL debug)
                SET(_MPI_EXTRA_PARAMS "--disable-fast")
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OWN_MPI_INSTALL_DIR}/bin/mpifort)
        elseif (MPI STREQUAL mvapich2)
            SET(_MPI_VERSION ${MVAPICH2_VERSION})
            if (MPI_BUILD_TYPE STREQUAL release)
                SET(_MPI_EXTRA_PARAMS "--enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars")
            elseif(MPI_BUILD_TYPE STREQUAL debug)
                SET(_MPI_EXTRA_PARAMS "--disable-fast")
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
        message(STATUS "Build params: ${_MPI_EXTRA_PARAMS}")
        
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
    		    ${_MPI_EXTRA_PARAMS}
    		BINARY_DIR ${_MPI_BINARY_DIR}
    		
    		#--Build step-----------------
    		BUILD_COMMAND make -j #${BUILD_COMMAND}
    		
    		#--Install step---------------
    		# currently set as extra arg (above), somehow does not work
    		#INSTALL_DIR ${OPENMPI_INSTALL_DIR}
    		INSTALL_COMMAND make install #${INSTALL_COMMAND}
    		
    		#LOG_CONFIGURE 1
    		#LOG_BUILD 1
    		#LOG_INSTALL 1
    		STEP_TARGETS install
    	)
        ADD_DOWNSTREAM_DEPS(MPI)
    else()
        message(FATAL_ERROR "MPI (${MPI}) installation support not yet implemented for this platform.")
    endif()
endif()