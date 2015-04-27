SET(CMAKE_MIN_VERSION_MAJ 3.2)
SET(CMAKE_MIN_VERSION ${CMAKE_MIN_VERSION_MAJ}.0-rc1)
message(STATUS "Checking CMake version..")
# Use the cmake binary with which this script was invoked as default 
SET(MY_CMAKE_COMMAND ${CMAKE_COMMAND})

MACRO(BUILD_CMAKE VERSION_TO_BUILD VERSION_TO_BUILD_MAJ)
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
        -DCMAKE_USE_OPENSSL=YES)
    
    # Create dir
    SET(CMAKEBUILD_BINARY_DIR ${OPENCMISS_ROOT}/build/utilities/cmake)
    file(MAKE_DIRECTORY ${CMAKEBUILD_BINARY_DIR})
    
    # Get build commands
    include(OCMSetupBuildMacros)
    GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${CMAKEBUILD_BINARY_DIR} YES)
    
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

# check if ssl library is installed on the system
if (NOT WIN32)
    # Fixes the library detection, as no project has been initialized yet and thus
    # the find_library wont work correctly. this will probably bite someone sometime :-|
    if (UNIX)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} .a .so)
        SET(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} lib)
    endif()
    find_package(OpenSSL QUIET)
endif()

# check if system cmake has ssl support
include(HTTPSCheck)

if (WIN32)
    if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
        message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION}.\n"
                            "At least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                            "Please download & install from http://www.cmake.org/download/\n")
    endif()
else()
    # only build cmake if user specifically requires it
    if (BUILD_CMAKE)
        
        # can't build cmake without OpenSSL (otherwise, no https downloads)
        if (NOT OPENSSL_FOUND)
            message(FATAL_ERROR "No OpenSSL could be found on your system.\n"
                                "Building CMake required OpenSSL to be available.\n"
                                "Please install OpenSSL before reinvoking the CMake build process.\n")
        endif()
            
        SET(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
        SET(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
        
        # Check if the binary is already there and hint the user to it
        if (NOT EXISTS ${MY_CMAKE_EXECUTABLE})
        
            # Otherwise .. need compilation!
            message(WARNING "Your CMake version is ${CMAKE_VERSION}, but at least version ${CMAKE_MIN_VERSION} is required for OpenCMISS. Building now..")
            
            SET(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
            SET(CMAKE_INTERMEDIATE_VERSION_MAJ 2.6)
            SET(CMAKE_INTERMEDIATE_VERSION ${CMAKE_INTERMEDIATE_VERSION_MAJ}.0)
            
            # compile intermediate version of cmake if present is too old
            if (CMAKE_VERSION VERSION_LESS ${CMAKE_INTERMEDIATE_VERSION})
                message(WARNING "Your CMake version is too damn old:${CMAKE_VERSION}! A newer version is required to build version ${CMAKE_MIN_VERSION}. Building now..")
                # set up the paths for an intermediate version of cmake
                SET(CMAKE_TARBALL cmake-${CMAKE_INTERMEDIATE_VERSION}.tar.gz)
                SET(CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake-${CMAKE_INTERMEDIATE_VERSION})
                SET(CMAKE_INSTALL_DIR ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
                BUILD_CMAKE(${CMAKE_INTERMEDIATE_VERSION} ${CMAKE_INTERMEDIATE_VERSION_MAJ})
                SET(MY_CMAKE_COMMAND ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
            endif()
            
            # reset the paths for latest cmake version
            SET(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
            SET(CMAKE_TARBALL cmake-${CMAKE_MIN_VERSION}.tar.gz)
            BUILD_CMAKE(${CMAKE_MIN_VERSION} ${CMAKE_MIN_VERSION_MAJ})
            SET(MY_CMAKE_COMMAND ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
            
            # remove intermediate cmake version if it was built
            #file(REMOVE ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
            
        elseif(EXISTS ${MY_CMAKE_EXECUTABLE})
            message(STATUS "Using own build of CMake ${CMAKE_MIN_VERSION} at ${CMAKE_INSTALL_DIR}")
            #SET(MY_CMAKE_COMMAND ${MY_CMAKE_EXECUTABLE})
        endif()
        
    # if user hasn't specified to build cmake,
    # give hints, if version meets requirements and if ssl support is enabled
    # otherwise, ask to install ssl libraries first
    else()
        # check for cmake version, ssl support and if OpenSSL is installed
        if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
            if (NOT OPENSSL_FOUND)
                message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION}.\n"
                                    "At least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                                    "No OpenSSL could be found on your system. Building CMake required OpenSSL to be available.\n"
                                    "Please:\n"
                                    " (1) Install OpenSSL.\n"
                                    " (2) Reinvoke the CMake build process with -DBUILD_CMAKE=ON to build a newer version of CMake.\n")
            else()
                message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION}.\n"
                                    "At least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\n"
                                    "Please download & install a newer version of CMake or reinvoke the CMake build process with -DBUILD_CMAKE=ON to build a newer version of CMake.\n")
            endif()
        else()
            if (NOT HTTPS_SUCCESS)
                if (NOT OPENSSL_FOUND)
                    message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION} but does not support OpenSSL.\n"
                                        "No OpenSSL could be found on your system. Building CMake required OpenSSL to be available.\n"
                                        "Please:\n"
                                        " (1) Install OpenSSL.\n"
                                        " (2) Reinvoke the CMake build process with -DBUILD_CMAKE=ON to build CMake with OpenSSL support.\n")
                else()
                    message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION} but does not support OpenSSL.\n"
                                        "Please reinvoke the CMake build process with -DBUILD_CMAKE=ON to build CMake with OpenSSL support.\n")
                endif()
            endif()
        endif()
    endif()
endif()
