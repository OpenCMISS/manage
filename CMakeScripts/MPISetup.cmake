# This file takes care of own MPI builds according to the selected MPI implementation (Variable "MPI")
# This is supported yet only on Unix systems
if (UNIX)

    # Set the forward dependencies of MPI only if we build it ourselves
    SET(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
    # The choice is ... 
    if (MPI STREQUAL openmpi)
        SET(_MPI_VERSION ${OPENMPI_VERSION})
        SET(_MPI_FORTRAN_COMPILER_DEFNAME Fortran)
        SET(_MPI_EXTRA_PARAMS )
    elseif (MPI STREQUAL mpich2)
        SET(_MPI_VERSION ${MPICH2_VERSION})
        SET(_MPI_FORTRAN_COMPILER_DEFNAME FC)
        if (CMAKE_BUILD_TYPE STREQUAL RELEASE)
            SET(_MPI_EXTRA_PARAMS "--enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars")
        elseif(CMAKE_BUILD_TYPE STREQUAL DEBUG)
            SET(_MPI_EXTRA_PARAMS "--disable-fast")
        endif()
    else()
	    message(FATAL_ERROR "Own build of MPI - ${MPI} not yet implemented")
    endif()
    
    message(STATUS "Using shipped MPI (${MPI}-${_MPI_VERSION})")
    SET(_MPI_INSTALL_DIR ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/${MPI})
        
    # Check if already installed locally
    SET(MPI_HOME ${_MPI_INSTALL_DIR})
    find_package(MPI QUIET)
        
    if (NOT MPI_FOUND)
        get_build_type_extra(BUILDTYPEEXTRA)
        SET(_MPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/dependencies/${MPI})
        SET(_MPI_BINARY_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/dependencies/${MPI}/${BUILDTYPEEXTRA})                
        SET(_MPI_BRANCH v${_MPI_VERSION})
        #GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${OPENMPI_BINARY_DIR} TRUE)
        
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
    		    ${_MPI_FORTRAN_COMPILER_DEFNAME}=${CMAKE_Fortran_COMPILER}
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
    message(FATAL_ERROR "OpenMPI installation support not implemented for this platform.")
endif()