# This file takes care of own MPI builds according to the selected MPI implementation (Variable "MPI")
# This is supported yet only on Unix systems
if (UNIX)

    # Set the forward dependencies of MPI only if we build it ourselves
    SET(MPI_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
    # The choice is ... tadaaaaa OpenMPI
    if (MPI STREQUAL openmpi)
        SET(OPENMPI_INSTALL_DIR ${OPENCMISS_COMPONENTS_INSTALL_PREFIX}/openmpi)
        
        # Check if already installed locally
        SET(MPI_HOME ${OPENMPI_INSTALL_DIR})
        find_package(MPI QUIET)
        
        if (NOT MPI_FOUND)
            get_build_type_extra(BUILDTYPEEXTRA)
            SET(OPENMPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/dependencies/openmpi)
            SET(OPENMPI_BINARY_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR}/dependencies/openmpi/${BUILDTYPEEXTRA})                
            SET(OPENMPI_BRANCH v${OPENMPI_VERSION})
            GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${OPENMPI_BINARY_DIR} TRUE)
            
            message(STATUS "Configuring build of MPI(openmpi) in ${OPENMPI_BINARY_DIR}...")
            
            ExternalProject_Add(MPI
        		PREFIX ${OPENMPI_BINARY_DIR}
        		TMP_DIR ${OPENMPI_BINARY_DIR}/ep_tmp
        		STAMP_DIR ${OPENMPI_BINARY_DIR}/ep_stamp
        		
        		#--Download step--------------
        		DOWNLOAD_DIR ${OPENMPI_SOURCE_DIR}/src-download
                URL https://github.com/OpenCMISS-Utilities/openmpi/archive/${OPENMPI_BRANCH}.zip 
                #http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.4.tar.gz
                #URL_HASH SHA1=22002fc226f55e188e21be0fdc3602f8d024e7ba
                 
        		#--Configure step-------------
        		SOURCE_DIR ${OPENMPI_SOURCE_DIR}
        		CONFIGURE_COMMAND ${OPENMPI_SOURCE_DIR}/configure 
        		    --prefix ${OPENMPI_INSTALL_DIR}
        		    CC=${CMAKE_C_COMPILER}
        		    CXX=${CMAKE_CXX_COMPILER}
        		    Fortran=${CMAKE_Fortran_COMPILER}
        		#BINARY_DIR ${OPENMPI_BINARY_DIR}
        		
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
	    message(FATAL_ERROR "Own build of MPI - ${MPI} not yet implemented")
	endif()
else()
    message(FATAL_ERROR "OpenMPI installation support not implemented for this platform.")
endif()