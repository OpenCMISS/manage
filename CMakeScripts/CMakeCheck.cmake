SET(CMAKE_MIN_VERSION_MAJ 3.2)
SET(CMAKE_MIN_VERSION ${CMAKE_MIN_VERSION_MAJ}.0-rc1)
message(STATUS "Checking CMake..")
if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
    if (WIN32)
        message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION}.\nAt least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\nPlease download & install from http://www.cmake.org/download/")
    else()
        # Fixes the library detection, as no project has been initialized yet and thus
        # the find_library wont work correctly. this will probably bite someone sometime :-|
        if (UNIX)
            SET(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES} .a .so)
            SET(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_FIND_LIBRARY_PREFIXES} lib)
        endif()
        find_package(OpenSSL QUIET)
        if (NOT OPENSSL_FOUND)
            message(FATAL_ERROR "No OpenSSL could be found on your system. Building CMake required OpenSSL to be available.")
        endif()
        
        SET(CMAKE_INSTALL_DIR ${OPENCMISS_ROOT}/install/utilities/cmake)
        SET(MY_CMAKE_EXECUTABLE ${CMAKE_INSTALL_DIR}/bin/cmake${CMAKE_EXECUTABLE_SUFFIX})
        
        # Check if the binary is already there and hint the user to it
        if (EXISTS ${MY_CMAKE_EXECUTABLE})
            message(FATAL_ERROR
                "@@@@@@@@@ OpenCMISS utilities @@@@@@@@@\n"
                "Your new CMake version has been built at\n${MY_CMAKE_EXECUTABLE}\nbut does not seem to be used.\nCurrently running version ${CMAKE_VERSION} at ${CMAKE_COMMAND}\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            )
            return()
        endif()
        # Otherwise .. need compilation!
        message(WARNING "Your CMake version is ${CMAKE_VERSION}, but at least version ${CMAKE_MIN_VERSION} is required for OpenCMISS. Building now..")
        
        SET(CMAKE_SRC_DIR ${OPENCMISS_ROOT}/src/utilities)
        SET(CMAKE_TARBALL cmake-${CMAKE_MIN_VERSION}.tar.gz)
        
        # Download
        if(NOT EXISTS ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
            SET(CMAKE_SRC_TAR http://www.cmake.org/files/v${CMAKE_MIN_VERSION_MAJ}/${CMAKE_TARBALL})
            message(STATUS "Downloading ${CMAKE_SRC_TAR}")
            FILE(DOWNLOAD ${CMAKE_SRC_TAR} ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
        endif()
            
        # Extract
        message(STATUS "Extracting ${CMAKE_SRC_DIR}/${CMAKE_TARBALL} [${CMAKE_COMMAND} -E tar xzvf ${CMAKE_TARBALL}]")
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_TARBALL} .
            WORKING_DIRECTORY ${CMAKE_SRC_DIR})
        file(REMOVE ${CMAKE_SRC_DIR}/${CMAKE_TARBALL})
        
        # Add top-level folder to src dir (default for cmake.org downloads)
        SET(CMAKE_SRC_DIR "${CMAKE_SRC_DIR}/cmake-${CMAKE_MIN_VERSION}")
        
        # Build config
        SET(CMAKE_DEFS -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_DIR}
            -DCMAKE_USE_OPENSSL=YES)
        
        # Create dir
        SET(CMAKEBUILD_BINARY_DIR ${OPENCMISS_ROOT}/build/utilities/cmake)
        file(MAKE_DIRECTORY ${CMAKEBUILD_BINARY_DIR})
        
        # Get build commands
        include(OCMSetupBuildMacros)
        GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND ${CMAKEBUILD_BINARY_DIR} TRUE)
        
        # Run cmake
        execute_process(COMMAND ${CMAKE_COMMAND}
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
        else()
            message(FATAL_ERROR
                "@@@@@@@@@ OpenCMISS utilities @@@@@@@@@\n" 
                "An up-to-date CMake version has been compiled at\n--> ${MY_CMAKE_EXECUTABLE} <--\nPlease re-invoke the build process using the new version.\n"
                "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            )
        endif()
    endif()
    return()   
endif()
message(STATUS "Checking CMake.. found ${CMAKE_VERSION} >= ${CMAKE_MIN_VERSION}")