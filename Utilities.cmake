# Generate the wrappers (if not existing)
SET(WRAPPER_DIR ${OPENCMISS_SETUP_DIR}/CMakeFindModuleWrappers)
foreach(PACKAGE_NAME ${PACKAGES_WITH_TARGETS})
    SET(FILE ${WRAPPER_DIR}/Find${PACKAGE_NAME}.cmake)
    #if(NOT EXISTS ${FILE})
        SET(PACKAGE_TARGETS ${${PACKAGE_NAME}_TARGETS})
        configure_file(${WRAPPER_DIR}/FindXXX.in.cmake ${FILE} @ONLY)
    #endif()
endforeach()

########################################################################
# MPI
if(OCM_USE_MPI)
    
    # Look for local one if allowed (default)
    if (OCM_MPI_LOCAL)
        find_package(MPI QUIET)
    endif()
    #message(STATUS "MPI_C_COMPILER: ${MPI_C_COMPILER}, MPI_CXX_COMPILER: ${MPI_CXX_COMPILER}")
        
    if (NOT MPI_FOUND)
        if (UNIX)
            SET(OPENMPI_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/openmpi)        
            
            # Check if already installed locally
            SET(MPI_HOME ${OPENMPI_INSTALL_DIR})
            find_package(MPI QUIET)
            
            if (MPI_FOUND)
                SET(MPI openmpi)
            else()
                message(STATUS "
                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    MPI is requested but no local MPI implementation could be found.
                    Adding default OpenMPI...
                    You will need to re-start setup (cmake & make) after MPI has been compiled.
                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    "
                )
                
                SET(OPENMPI_SOURCE_DIR ${OPENCMISS_ROOT}/src/utilities/openmpi)
                SET(OPENMPI_BINARY_DIR ${OPENCMISS_ROOT}/build/utilities/openmpi)                
                SET(OPENMPI_BRANCH v${OPENMPI_VERSION})
                # Set the MPI_HOME variable to our built version
                SET(MPI openmpi)
            
                ExternalProject_Add(OPENMPI
            		#DEPENDS ${${COMPONENT_NAME}_DEPS}
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
            		BUILD_COMMAND make -j12
            		BUILD_IN_SOURCE 1
            		
            		#--Install step---------------
            		# currently set as extra arg (above), somehow does not work
            		#INSTALL_DIR ${OPENMPI_INSTALL_DIR}
            		INSTALL_COMMAND make install
            		
            		LOG_CONFIGURE 1
            		LOG_BUILD 1
            		LOG_INSTALL 1
            	)
            	SET(BUILDING_MPI TRUE)
        	endif()
        else()
            message(FATAL_ERROR "OpenMPI installation support not implemented for this platform.")
        endif()
    endif()
endif()

# ... gtest, ..
