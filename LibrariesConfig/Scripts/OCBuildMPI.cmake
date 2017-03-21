
#####################################################################
# MPI build
#####################################################################
# If we get here without having found an MPI implementation, we need to build it.
# But we will always have the MPI mnemonic set if we reach here.
# **Always** include OCDetermineMPI before this file.
#
if (NOT MPI_FOUND)
    
    # This is supported yet only on Unix systems
message(STATUS "OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX: ${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}")
    if (UNIX)
        # No shared libs!
        set(_MPI_EXTRA_PARAMS --disable-shared)
        set(MPI_C_FLAGS -fPIC) 
        if (OPENCMISS_MPI STREQUAL openmpi)
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
            set(MPI_C_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpifort)
message(STATUS "OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX: ${OPENCMISS_DEPENDENCIES_INSTALL_NO_MPI_PREFIX}")
        elseif (OPENCMISS_MPI STREQUAL mpich)
            set(_MPI_VERSION ${MPICH_VERSION})
            if (OPENCMISS_MPI_BUILD_TYPE STREQUAL Release)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(OPENCMISS_MPI_BUILD_TYPE STREQUAL Debug)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast --enable-g=all)
                set(MPI_C_FLAGS "${MPI_C_FLAGS} -g3")
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpifort)
        elseif (OPENCMISS_MPI STREQUAL mvapich2)
            set(_MPI_VERSION ${MVAPICH2_VERSION})
            if (OPENCMISS_MPI_BUILD_TYPE STREQUAL Release)
                list(APPEND _MPI_EXTRA_PARAMS --enable-fast=O3,ndebug --disable-error-checking --without-timing --without-mpit-pvars)
            elseif(OPENCMISS_MPI_BUILD_TYPE STREQUAL Debug)
                list(APPEND _MPI_EXTRA_PARAMS --disable-fast --enable-g=all)
                set(MPI_C_FLAGS "${MPI_C_FLAGS} -g3")
            endif()
            # Define the MPI compilers that will be used later already - the configuration stage
            # needs them so that other dependencies with MPI have the correct compilers defined right away.
            set(MPI_C_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicc)
            set(MPI_CXX_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpicxx)
            set(MPI_Fortran_COMPILER ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}/bin/mpifort)
        else()
            log("Own build of MPI - ${OPENCMISS_MPI} not yet implemented" ERROR)
        endif()
        
        set(OPENCMISS_MPI_HOME ${OPENCMISS_OWN_MPI_INSTALL_PREFIX} CACHE STRING "Installation directory of own/local MPI build" FORCE)
        string(TOUPPER ${OPENCMISS_MPI} OPENCMISS_MPI_COMPONENT)
        set(_MPI_SOURCE_DIR ${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${OPENCMISS_MPI})
        set(_MPI_BINARY_DIR ${OPENCMISS_DEPENDENCIES_BINARY_NO_MPI_DIR}/${OPENCMISS_MPI}/${MPI_BUILD_TYPE_LOWER})
        set(_MPI_BRANCH v${_MPI_VERSION})
        
        log("Configuring build of '${OPENCMISS_MPI_COMPONENT} ${_MPI_VERSION}' in ${_MPI_BINARY_DIR}...")
        log("Extra MPI build parameters: ${_MPI_EXTRA_PARAMS}" DEBUG)
        
        # Dont download again if the target source folder already contains files 
        file(GLOB _MPI_FILES ${_MPI_SOURCE_DIR}/)
        set(DOWNLOAD_COMMANDS DOWNLOAD_COMMAND "")
        if("" STREQUAL "${_MPI_FILES}")
            set(DOWNLOAD_COMMANDS 
                DOWNLOAD_DIR ${_MPI_SOURCE_DIR}/src-download
                URL https://github.com/OpenCMISS-Dependencies/${OPENCMISS_MPI}/archive/${_MPI_BRANCH}.zip
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
        
        # Log settings
        if (OC_CREATE_LOGS)
            set(_LOGFLAG 1)
        else()
            set(_LOGFLAG 0)
        endif()
        
message(STATUS "OPENCMISS_OWN_MPI_INSTALL_PREFIX: ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}")
message(STATUS "OPENCMISS_MPI_HOME: ${OPENCMISS_MPI_HOME}")
message(STATUS "MPI_Fortran_COMPILER: ${MPI_Fortran_COMPILER}")
        ExternalProject_Add(${OC_EP_PREFIX}${OPENCMISS_MPI_COMPONENT}
            PREFIX ${_MPI_BINARY_DIR}
            TMP_DIR ${_MPI_BINARY_DIR}/extproj/tmp
            STAMP_DIR ${_MPI_BINARY_DIR}/extproj/stamp

            #--Download step--------------
            # ${DOWNLOAD_COMMANDS}
            DOWNLOAD_COMMAND ""

            #--Configure step-------------
            SOURCE_DIR ${_MPI_SOURCE_DIR}
            CONFIGURE_COMMAND ${_MPI_SOURCE_DIR}/configure
                --prefix ${OPENCMISS_OWN_MPI_INSTALL_PREFIX}
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

            # Logging
            LOG_CONFIGURE ${_LOGFLAG}
            LOG_BUILD ${_LOGFLAG}
            LOG_INSTALL ${_LOGFLAG}
            STEP_TARGETS install
        )
        # Set the forward dependencies of MPI to have it build before the consuming components
        set(${OPENCMISS_MPI_COMPONENT}_FWD_DEPS ${OPENCMISS_COMPONENTS_WITHMPI})
        addDownstreamDependencies(${OPENCMISS_MPI_COMPONENT} FALSE)
    else()
        unset(MPI_HOME CACHE)
        unset(MPI_HOME)
        log("MPI (${OPENCMISS_MPI}) installation support not yet implemented for this platform." ERROR)
    endif()
else()
    log("Found MPI: ${MPI_C_INCLUDE_DIRECTORY} / ${MPI_C_LIBRARIES}" DEBUG)
endif()
