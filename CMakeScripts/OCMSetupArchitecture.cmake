MACRO(GET_COMPILER_NAME VARNAME)
	# Get the compiler name
	IF( MINGW )
		SET(${VARNAME} "mingw" )
	ELSEIF( MSYS )
		SET(${VARNAME} "msys" )
	ELSEIF( BORLAND )
		SET(${VARNAME} "borland" )
	ELSEIF( WATCOM )
		SET(${VARNAME} "watcom" )
	ELSEIF( MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 )
		SET(${VARNAME} "msvc" )
	ELSEIF( CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
	    execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpversion
	        RESULT_VARIABLE RES
	        OUTPUT_VARIABLE VERSION
	        OUTPUT_STRIP_TRAILING_WHITESPACE)
	    if (NOT RES EQUAL 0)
	        SET(VERSION "0.0")
	    endif()
	    SET(${VARNAME} gnu-${VERSION})
	ELSEIF(${CMAKE_C_COMPILER} MATCHES icc 
	    OR ${CMAKE_CXX_COMPILER} MATCHES icpc
	    OR ${CMAKE_Fortran_COMPILER} MATCHES ifort)
	    SET(${VARNAME} "intel")
	ELSEIF( CYGWIN )
		SET(${VARNAME} "cygwin")
	ENDIF()
ENDMACRO()

# This function assembles the architecture path
# We have [ARCH][COMPILER][MT][MPI|no_mpi][STATIC|SHARED]
#
# This function returns two architecture paths, the first for mpi-unaware applications (VARNAME)
# and the second for applications that link against an mpi implementation (VARNAME_MPI)
#
# # If the second argument is "SHORT" (literally), only the variable VARNAME will be set to a path with no mpi and static/shared parts
function(get_architecture_path VARNAME VARNAME_MPI)
    SET(ARCHPATH )
    # If the second argument is "SHORT" (literally) we only return a path with no mpi part 
    if (VARNAME_MPI STREQUAL SHORT)
        set(IS_SHORT YES)
    else()
        set(IS_SHORT NO)
    endif()
    if(OCM_USE_ARCHITECTURE_PATH)
        # Architecture/System
        STRING(TOLOWER ${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_NAME_LOWER)
        SET(ARCHPATH ${CMAKE_SYSTEM_PROCESSOR}_${CMAKE_SYSTEM_NAME_LOWER})
        
        # Bit/Adressing bandwidth
        #if (ABI)
        #    SET(ARCHPATH ${ARCHPATH}/${ABI}bit)
        #endif()
        
        # Compiler
        GET_COMPILER_NAME(COMPILER)
        SET(ARCHPATH ${ARCHPATH}/${COMPILER})
        
        # Profiling
        
        # Multithreading
        if (OCM_USE_MT)
            SET(ARCHPATH ${ARCHPATH}/mt)
        endif()
        
        # Short version is without MPI and static/shared path elements
        if (NOT IS_SHORT)
            # MPI version information
            if (MPI STREQUAL none)
                SET(MPI_PART "no_mpi")
            else()
                # Add the build type of MPI to the architecture path - we obtain different libraries
                # for different mpi build types
                SET(MPI_PART ${MPI}_${MPI_BUILD_TYPE})
            endif()
            SET(ARCHPATH ${ARCHPATH}/${MPI_PART})
            
            # Library type (static/shared)
            if (BUILD_SHARED_LIBS)
                SET(ARCHPATH ${ARCHPATH}/shared)    
            else()
                SET(ARCHPATH ${ARCHPATH}/static)
            endif()
        endif()
        
    else()
        SET(ARCHPATH .)
    endif()
    
    # Append to desired variable
    if (IS_SHORT)
        SET(${VARNAME} ${ARCHPATH} PARENT_SCOPE)
    else()
        SET(${VARNAME_MPI} ${ARCHPATH} PARENT_SCOPE)
        # The full architecture path without mpi is the same but with "no_mpi" at the same level
        string(REPLACE "/${MPI_PART}" "/no_mpi" ARCHPATH_NOMPI ${ARCHPATH})
        SET(${VARNAME} ${ARCHPATH_NOMPI} PARENT_SCOPE)
    endif()
endfunction()

function(get_build_type_extra VARNAME)
    # Build type
    if (CMAKE_BUILD_TYPE)
        STRING(TOLOWER ${CMAKE_BUILD_TYPE} buildtype)
        SET(BUILDTYPEEXTRA ${buildtype})
    elseif (NOT CMAKE_CFG_INTDIR STREQUAL .)
        SET(BUILDTYPEEXTRA ) #${CMAKE_CFG_INTDIR}
    else()
        SET(BUILDTYPEEXTRA noconfig)
    endif()
    SET(${VARNAME} ${BUILDTYPEEXTRA} PARENT_SCOPE)
endfunction()