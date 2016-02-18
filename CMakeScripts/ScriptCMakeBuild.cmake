# This script is intended to be used within the OpenCMISS build environment, called from CMakeCheck.cmake.
# Arguments passed to this script are:
# CMAKE_MODULE_PATH
# OPENCMISS_ROOT
# CMAKE_MIN_MAJOR_VERSION
# CMAKE_MIN_MINOR_VERSION
# CMAKE_MIN_PATCH_VERSION
# OPENCMISS_CMAKE_MIN_VERSION

message(STATUS "Building CMake version ${OPENCMISS_CMAKE_MIN_VERSION} ..")
# Use the cmake binary with which this script was invoked as default 
set(MY_CMAKE_COMMAND ${CMAKE_COMMAND})

include("${CMAKE_CURRENT_LIST_DIR}/OCFunctionDownloadAndExtract.cmake")

macro(BUILD_CMAKE VERSION_TO_BUILD VERSION_TO_BUILD_MAJ BUILD_WITH_OPENSSL)
    
    set(_URL http://www.cmake.org/files/v${VERSION_TO_BUILD_MAJ}/${CMAKE_TARBALL})
    set(_TARBALL "${CMAKE_SRC_DIR}/${CMAKE_TARBALL}")
    DownloadAndExtract(${_URL} "${_TARBALL}")
    
    # Add top-level folder to src dir (default for cmake.org downloads)
    set(CMAKE_SRC_DIR "${CMAKE_SRC_DIR}/cmake-${VERSION_TO_BUILD}")
    
    # Build config
    set(CMAKE_DEFS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_DIR}
        -DCMAKE_USE_OPENSSL=${BUILD_WITH_OPENSSL})
    
    # Create dir
    set(CMAKEBUILD_BINARY_DIR ${OPENCMISS_ROOT}/build/utilities/cmake-${VERSION_TO_BUILD})
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
    
    # Run build/install
    execute_process(COMMAND ${INSTALL_COMMAND})
    
    set(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
    if (NOT EXISTS ${MY_CMAKE_EXECUTABLE})
        message(FATAL_ERROR
            "@@@@@@@@@ OpenCMISS utilities @@@@@@@@@\n"
            "Building a newer CMake version failed. Please check & build manually.\n"
            "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        )
    endif(NOT EXISTS ${MY_CMAKE_EXECUTABLE})
endmacro()

macro(printfinishmessage)
message("@@@@@@@@@@@@@@@@@@@@@@@@@@ ATTENTION @@@@@@@@@@@@@@@@@@@@@@@@@@\n"
            " Successfully built CMake version ${OPENCMISS_CMAKE_MIN_VERSION}.\n"
            " Install directory: ${CMAKE_INSTALL_DIR}/bin/\n"
            " CMake binary: ${MY_CMAKE_EXECUTABLE}\n"
            " You can now start building OpenCMISS by re-invoking the CMake configuration step using the new CMake binary.\n"
            "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
endmacro()
     
set(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
set(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})

# Add check to see if the mayhaps already built version is the desired one
if (EXISTS ${MY_CMAKE_EXECUTABLE})
    execute_process(COMMAND ${MY_CMAKE_EXECUTABLE} --version
        OUTPUT_VARIABLE OUT)
    string(REGEX MATCH "cmake version ([0-9.]*)" _MATCH "${OUT}")
    if (CMAKE_MATCH_1 VERSION_LESS OPENCMISS_CMAKE_MIN_VERSION)
        message(STATUS "Found already installed version ${CMAKE_MATCH_1}. Removing first..")
        file(REMOVE_RECURSE "${CMAKE_INSTALL_DIR}")
    endif (CMAKE_MATCH_1 VERSION_LESS OPENCMISS_CMAKE_MIN_VERSION)
endif(EXISTS ${MY_CMAKE_EXECUTABLE})

# Check if the binary is already there and hint the user to it
if (EXISTS ${MY_CMAKE_EXECUTABLE})
    printfinishmessage()
else(EXISTS ${MY_CMAKE_EXECUTABLE})

    # Otherwise .. need compilation!
    message(WARNING "Your CMake version is ${CMAKE_VERSION}, but at least version ${OPENCMISS_CMAKE_MIN_VERSION} is required for OpenCMISS. Building now..")
    
    set(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
    set(CMAKE_INTERMEDIATE_VERSION_MAJ 2.8)
    set(CMAKE_INTERMEDIATE_VERSION ${CMAKE_INTERMEDIATE_VERSION_MAJ}.4)
    
    # compile intermediate version of cmake if present is too old
    if (CMAKE_VERSION VERSION_LESS ${CMAKE_INTERMEDIATE_VERSION})
        message(WARNING "Your CMake version is too old: ${CMAKE_VERSION}!\n"
                        "A newer version is required to build version ${OPENCMISS_CMAKE_MIN_VERSION}. Building now..")
        # set up the paths for an intermediate version of cmake
        set(CMAKE_TARBALL cmake-${CMAKE_INTERMEDIATE_VERSION}.tar.gz)
        set(CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake-${CMAKE_INTERMEDIATE_VERSION})
        set(CMAKE_INSTALL_DIR ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
        BUILD_CMAKE(${CMAKE_INTERMEDIATE_VERSION} ${CMAKE_INTERMEDIATE_VERSION_MAJ} NO)
        set(MY_CMAKE_COMMAND "${MY_CMAKE_EXECUTABLE}")
    endif(CMAKE_VERSION VERSION_LESS ${CMAKE_INTERMEDIATE_VERSION})
    
    # check if ssl library is installed on the system before building final cmake version
    # Fixes the library detection, as no project has been initialized yet and thus
    # the find_library wont work correctly. this will probably bite someone sometime :-|
    if (UNIX)
        set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} .a .so)
        set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} lib)
    endif(UNIX)
    find_package(OpenSSL QUIET)
    # can't build cmake without OpenSSL (otherwise, no https downloads)
    if (NOT OPENSSL_FOUND)
        # Alternative: if available, use PkgConfig to locate OpenSSL  
        find_package(PkgConfig QUIET)
        if (PKGCONFIG_FOUND OR PKG_CONFIG_FOUND)
            pkg_search_module(OPENSSL QUIET openssl)
        endif(PKGCONFIG_FOUND OR PKG_CONFIG_FOUND)
    endif(NOT OPENSSL_FOUND)
        
    if (OPENSSL_FOUND)
        message(STATUS "Found OpenSSL ${OPENSSL_VERSION}: ${OPENSSL_INCLUDE_DIR}")
    else(OPENSSL_FOUND)
        message(FATAL_ERROR "No OpenSSL could be found on your system!
Building CMake required OpenSSL to be available.
Please install OpenSSL before reinvoking the CMake build process.

Here are the according package names for some systems:
Ubuntu - libssl-dev
RedHat - openssl-devel")
    endif(OPENSSL_FOUND)
    
    # reset the paths for latest cmake version
    set(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
    set(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
    set(CMAKE_TARBALL cmake-${OPENCMISS_CMAKE_MIN_VERSION}.tar.gz)
    BUILD_CMAKE(${OPENCMISS_CMAKE_MIN_VERSION} ${CMAKE_MIN_MAJOR_VERSION}.${CMAKE_MIN_MINOR_VERSION} YES)
    printfinishmessage()
    
    # remove intermediate cmake version if it was built
    #file(REMOVE ${CMAKE_INTERMEDIATE_VERSION_INSTALL_DIR})
endif(EXISTS ${MY_CMAKE_EXECUTABLE})