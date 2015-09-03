# This function assembles the architecture path
# We have [ARCH][COMPILER][MT][MPI|no_mpi][STATIC|SHARED]
#
# This function returns two architecture paths, the first for mpi-unaware applications (VARNAME)
# and the second for applications that link against an mpi implementation (VARNAME_MPI)
#
# Requires the extra (=non-cmake default) variables:
# MPI
#
# See also: getShortArchitecturePath
function(getArchitecturePath VARNAME VARNAME_MPI)
    
    # Get short version to start with
    getShortArchitecturePath(ARCHPATH)
    
    # MPI version information
    if (MPI STREQUAL none)
        SET(MPI_PART "no_mpi")
    else()
        # Add the build type of MPI to the architecture path - we obtain different libraries
        # for different mpi build types
        SET(MPI_PART ${MPI}_${MPI_BUILD_TYPE})
    endif()
    SET(ARCHPATH ${ARCHPATH}/${MPI_PART})
    
    # Append to desired variable
    SET(${VARNAME_MPI} ${ARCHPATH} PARENT_SCOPE)
    # The full architecture path without mpi is the same but with "no_mpi" at the same level
    string(REPLACE "/${MPI_PART}" "/no_mpi" ARCHPATH_NOMPI ${ARCHPATH})
    SET(${VARNAME} ${ARCHPATH_NOMPI} PARENT_SCOPE)
endfunction()

# This function assembles a short version (the beginning) of the architecture path
# We have [ARCH][COMPILER][MT]
#
function(getShortArchitecturePath VARNAME)
    
    # Architecture/System
    STRING(TOLOWER ${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_NAME_LOWER)
    SET(ARCHPATH ${CMAKE_SYSTEM_PROCESSOR}_${CMAKE_SYSTEM_NAME_LOWER})
    
    # Bit/Adressing bandwidth
    #if (ABI)
    #    SET(ARCHPATH ${ARCHPATH}/${ABI}bit)
    #endif()
    
    # Compiler
    getCompilerPathElem(COMPILER)
    SET(ARCHPATH ${ARCHPATH}/${COMPILER})
    
    # Profiling
    
    # Multithreading
    if (OCM_USE_MT)
        SET(ARCHPATH ${ARCHPATH}/mt)
    endif()
    
    # Append to desired variable
    SET(${VARNAME} ${ARCHPATH} PARENT_SCOPE)
endfunction()

function(getCompilerPathElem VARNAME)
	# Get the compiler name
	if(MINGW)
		set(_COMP "mingw" )
	elseif(MSYS )
		set(_COMP "msys" )
	elseif(BORLAND )
		set(_COMP "borland" )
	elseif(WATCOM )
		set(_COMP "watcom" )
	elseif(MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 )
		set(_COMP "msvc" )
	elseif(CMAKE_COMPILER_IS_GNUCC)
	    set(_COMP "gnu")
	elseif(CMAKE_C_COMPILER_ID MATCHES Clang)
	    set(_COMP "clang")
	elseif(CMAKE_C_COMPILER_ID MATCHES Intel 
	    OR CMAKE_CXX_COMPILER_ID MATCHES Intel
	    OR CMAKE_Fortran_COMPILER_ID MATCHES Intel)
	    set(_COMP "intel")
	elseif( CYGWIN )
		set(_COMP "cygwin")
	endif()
	set(${VARNAME} "${_COMP}-${CMAKE_C_COMPILER_VERSION}" PARENT_SCOPE)
endfunction()

function(getBuildTypePathElem VARNAME)
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