SET(CMAKE_MIN_VERSION 3.1.0)
message(STATUS "Checking CMake..")
if (CMAKE_VERSION VERSION_LESS ${CMAKE_MIN_VERSION})
    if (WIN32)
        message(FATAL_ERROR "Your CMake version is ${CMAKE_VERSION}.\nAt least version ${CMAKE_MIN_VERSION} is required for OpenCMISS.\nPlease download & install from http://www.cmake.org/download/")
    else()
        
        SET(CMAKE_INSTALL_DIR ${OPENCMISS_UTILITIES_DIR}/install/cmake)
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
        
        message(WARNING "Your CMake version is ${CMAKE_VERSION}, but at least version ${CMAKE_MIN_VERSION} is required for OpenCMISS. Building now..")
        execute_process(
            COMMAND git submodule update --init cmake
            WORKING_DIRECTORY ${OPENCMISS_UTILITIES_DIR})
        find_package(OpenSSL QUIET)
        SET(CMAKE_DEFS )
        if (OPENSSL_FOUND)
            SET(CMAKE_DEFS -DCMAKE_USE_OPENSSL=YES)
        else()
            message(WARNING "Building CMake 3.xx: OpenSSL could not be located on your system. See the OpenCMISS documentation for details.")
        endif()
        
        # Create dir
        file(MAKE_DIRECTORY ${OPENCMISS_UTILITIES_DIR}/build/cmake)
        # Get build commands
        include(OCMUtilsBuildMacros)
        GET_BUILD_COMMANDS(BUILD_COMMAND INSTALL_COMMAND . TRUE)
        # Run cmake
        execute_process(COMMAND ${CMAKE_COMMAND}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_DIR} ${CMAKE_DEFS} ${OPENCMISS_UTILITIES_DIR}/cmake
            WORKING_DIRECTORY ${OPENCMISS_UTILITIES_DIR}/build/cmake
        )
        # Run build
        execute_process(COMMAND ${BUILD_COMMAND}
            WORKING_DIRECTORY ${OPENCMISS_UTILITIES_DIR}/build/cmake
        )
        # Run build/install
        execute_process(COMMAND ${INSTALL_COMMAND}
            WORKING_DIRECTORY ${OPENCMISS_UTILITIES_DIR}/build/cmake
        )
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