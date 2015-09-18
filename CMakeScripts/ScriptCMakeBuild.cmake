# This script is intended to be used within the OpenCMISS build environment, called from CMakeCheck.cmake.
# Arguments passed to this script are:
# CMAKE_MODULE_PATH
# OPENCMISS_ROOT
# DCMAKE_MIN_MAJOR_VERSION_MAJ
# DCMAKE_MIN_MINOR_VERSION_MAJ
# DCMAKE_MIN_PATCH_VERSION_MAJ
# DOPENCMISS_CMAKE_MIN_VERSION

message(STATUS "Building CMake version ${OPENCMISS_CMAKE_MIN_VERSION} ..")
# Use the cmake binary with which this script was invoked as default 
SET(MY_CMAKE_COMMAND ${CMAKE_COMMAND})

MACRO(BUILD_CMAKE VERSION_TO_BUILD VERSION_TO_BUILD_MAJ BUILD_WITH_OPENSSL)
    # Download
    if(NOT EXISTS ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
        SET(CMAKE_SRC_TAR http://www.cmake.org/files/v${VERSION_TO_BUILD_MAJ}/${CMAKE_TARBALL})
        message(STATUS "Downloading ${CMAKE_SRC_TAR}")
        FILE(DOWNLOAD ${CMAKE_SRC_TAR} ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
    endif()
        
    # Extract
    message(STATUS "Extracting ${CMAKE_SRC_DIR}/${CMAKE_TARBALL} [${CMAKE_COMMAND} -E tar xzvf ${CMAKE_TARBALL}]")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_TARBALL} .
        WORKING_DIRECTORY ${CMAKE_SRC_DIR})
    file(REMOVE ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
    
    # Add top-level folder to src dir (default for cmake.org downloads)
    SET(CMAKE_SRC_DIR "${CMAKE_SRC_DIR}/cmake-${VERSION_TO_BUILD}")
    
    # Build config
    SET(CMAKE_DEFS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_DIR}
        -DCMAKE_USE_OPENSSL=${BUILD_WITH_OPENSSL})
    
    # Create dir
    SET(CMAKEBUILD_BINARY_DIR ${OPENCMISS_ROOT}/build/utilities/cmake-${VERSION_TO_BUILD})
    file(MAKE_DIRECTORY ${CMAKEBUILD_BINARY_DIR})
    
    # Get build commands
    include(OCComponentSetupMacros)
    getBuildCommands(BUILD_COMMAND INSTALL_COMMAND ${CMAKEBUILD_BINARY_DIR} YES)
    
    # Run cmake
    execute_process(COMMAND ${MY_CMAKE_COMMAND}
        ${CMAKE_DEFS}
        ${CMAKE_SRC_DIR}
        WORKING_DIRECTORY ${CMAKEBUILD_BINARY_DIR}
    )
    
    # Run build
    #execute_process(COMMAND ${BUILD_COMMAND})
    
    # Run build/install
    execute_process(COMMAND ${INSTALL_COMMAND})
    
    if (NOT EXISTS ${MY_CMAKE_EXECUTABLE})
        message(FATAL_ERROR
            "@@@@@@@@@ OpenCMISS utilities @@@@@@@@@\n"
            "Building a newer CMake version failed. Please check & build manually.\n"
            "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        )
    endif()
ENDMACRO()
     
SET(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
SET(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})

# Check if the binary is already there and hint the user to it
if (NOT EXISTS ${MY_CMAKE_EXECUTABLE})

    # Otherwise .. need compilation!
    message(WARNING "Your CMake version is ${CMAKE_VERSION}, but at least version ${OPENCMISS_CMAKE_MIN_VERSION} is required for OpenCMISS. Building now..")
    
    SET(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
    SET(CMAKE_INTERMEDIATE_VERSION_MAJ 2.8)
    SET(CMAKE_INTERMEDIATE_VERSION ${CMAKE_INTERMEDIATE_VERSION_MAJ}.4)
    
    # compile intermediate version of cmake if present is too old
    if (CMAKE_VERSION VERSION_LESS ${CMAKE_INTERMEDIATE_VERSION})
        message(WARNING "Your CMake version is too old: ${CMAKE_VERSION}!\n"
                        "A newer version is required to build version ${OPENCMISS_CMAKE_MIN_VERSION}. Building now..")
        # set up the paths for an intermediate version of cmake
        SET(CMAKE_TARBALL cmake-${CMAKE_INTERMEDIATE_VERSION}.tar.gz)
        SET(CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake-${CMAKE_INTERMEDIATE_VERSION})
        SET(CMAKE_INSTALL_DIR ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
        SET(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
        # TODO: we could do a check again in case an intermediate version was built before?
        BUILD_CMAKE(${CMAKE_INTERMEDIATE_VERSION} ${CMAKE_INTERMEDIATE_VERSION_MAJ} NO)
        SET(MY_CMAKE_COMMAND ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
    endif()
    
    # check if ssl library is installed on the system before building final cmake version
    # Fixes the library detection, as no project has been initialized yet and thus
    # the find_library wont work correctly. this will probably bite someone sometime :-|
    if (UNIX)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} .a .so)
        SET(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} lib)
    endif()
    find_package(OpenSSL QUIET)
    # can't build cmake without OpenSSL (otherwise, no https downloads)
    if (NOT OPENSSL_FOUND)
        message(WARNING "No OpenSSL could be found on your system via normal check.\n"
                        "Performing package config check now..\n")
        find_package(PkgConfig REQUIRED)
        pkg_search_module(OPENSSL QUIET openssl)

        if (OPENSSL_FOUND)
            message(STATUS "Found OpenSSL ${OPENSSL_VERSION}")
            message(STATUS "OpenSSL include directory: ${OPENSSL_INCLUDE_DIR}")
        else()
            message(FATAL_ERROR "No OpenSSL could be found on your system via package config check.\n"
                                "Building CMake required OpenSSL to be available.\n"
                                "Please install OpenSSL before reinvoking the CMake build process.\n")
        endif()
    endif()
    
    # reset the paths for latest cmake version
    SET(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
    SET(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
    SET(CMAKE_TARBALL cmake-${OPENCMISS_CMAKE_MIN_VERSION}.tar.gz)
    BUILD_CMAKE(${OPENCMISS_CMAKE_MIN_VERSION} ${CMAKE_MIN_MAJOR_VERSION}.${CMAKE_MIN_MINOR_VERSION} YES)
    SET(MY_CMAKE_COMMAND ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
    message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
            " Successfully built CMake version ${OPENCMISS_CMAKE_MIN_VERSION}.\n"
            " Install directory: ${CMAKE_INSTALL_DIR}/bin/\n"
            " You may now start building OpenCMISS by re-invoking the CMake configuration step using the new CMake binary.\n"
            "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    
    # remove intermediate cmake version if it was built
    #file(REMOVE ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
    
elseif(EXISTS ${MY_CMAKE_EXECUTABLE})
    # TODO print message pointing to new binary.
    message(STATUS "Using own build of CMake ${OPENCMISS_CMAKE_MIN_VERSION} at ${CMAKE_INSTALL_DIR}")
    #SET(MY_CMAKE_COMMAND ${MY_CMAKE_EXECUTABLE})
endif()
        
endif()
