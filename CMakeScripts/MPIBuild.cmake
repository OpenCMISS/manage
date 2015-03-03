########################################################################
# This script takes care of building own MPI implementations.
# See the Config/MPIChecks script for a scenario overview.
# 
# But we will always have the MPI mnemonic set for this script.

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
    
    # For MPI we use a slightly different architecture path - we dont need to re-build MPI for static/shared builds nor do we need the actual
    # MPI mnemonic in the path. Instead, we use "mpi" as common top folder to collect all local MPI builds.
    get_architecture_path(ARCHITECTURE_PATH_MPI SHORT)
    get_build_type_extra(BUILDTYPEEXTRA)
    set(_MPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/${ARCHITECTURE_PATH_MPI}/mpi/${MPI}/${BUILDTYPEEXTRA})
        
    # Check if already installed locally
    #SET(MPI_HOME ${_MPI_INSTALL_DIR} CACHE PATH "MPI home directory" FORCE)
    SET(MPI_HOME ${_MPI_INSTALL_DIR})
    find_package(MPI QUIET)
        
    if (NOT MPI_FOUND)
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
    		#BUILD_IN_SOURCE 1
    		
    		#--Install step---------------
    		# currently set as extra arg (above), somehow does not work
    		#INSTALL_DIR ${OPENMPI_INSTALL_DIR}
    		INSTALL_COMMAND make install #${INSTALL_COMMAND}
    		
    		#LOG_CONFIGURE 1
    		#LOG_BUILD 1
    		#LOG_INSTALL 1
    	)
    	ADD_DOWNSTREAM_DEPS(MPI)
	endif()
else()
    message(FATAL_ERROR "MPI (${MPI}) installation support not yet implemented for this platform.")
endif()