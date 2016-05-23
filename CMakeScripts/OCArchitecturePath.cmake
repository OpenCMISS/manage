##
# In order to allow simultaneous installation of builds for various configuration and choices,
# OpenCMISS uses an *architecture path* to store produced files, libraries and headers into separate
# directories.
#
# The architecture path is composed of the following elements (in that order)
#
#    :architecture: The system architecture, e.g. :literal:`x86_64_linux` 
#    :toolchain: The toolchain info for the build.
#        This path is composed following the pattern :path:`/<mnemonic>-C<c_version>-<mnemonic>-F<fortran_version>`,
#        where *mnemonic* stands for one of the items below, *c_version* the version of the C compiler and
#        *fortran_version* the version of the Fortran compiler.
# 
#        All the short mnemonics are:
#        
#            :absoft: The Absoft Fortran compiler
#            :borland: The Borland compilers
#            :ccur: The Concurrent Fortran compiler
#            :clang: The CLang toolchain (commonly Mac OS)
#            :cygwin: The CygWin toolchain for Windows environments
#            :gnu: The GNU toolchain
#            :g95: The G95 Fortran compiler
#            :intel: The Intel toolchain
#            :mingw: The MinGW toolchain for Windows environments
#            :msvc: MS Visual Studio compilers
#            :pgi: The Portland Group compilers
#            :watcom: The Watcom toolchain
#            :unknown: Unknown compiler
#    
#    :multithreading: If :var:`OC_USE_MULTITHREADING` is enabled, this segment is :path:`/mt`.
#        Otherwise, the path element is skipped.
#    :mpi: Denotes the used MPI implementation along with the mpi build type.
#        The path element is composed as :path:`/<mnemonic>_<mpi-build-type>`, where *mnemonic*/*mpi-build-type* contains the 
#        lower-case value of the :var:`MPI`/:var:`MPI_BUILD_TYPE` variable, respectively.
#
#        Moreover, a path element :path:`no_mpi` is used for any component that does not use MPI at all.  
#    :buildtype: Path element for the current overall build type determined by :var:`CMAKE_BUILD_TYPE`.
#        This is for single-configuration platforms only - multiconfiguration environments like Visual Studio have their
#        own way of dealing with build types. 
#
# For example, a typical architecture path looks like::
#
#     x86_64_linux/gnu-C4.6-gnu-F4.6/openmpi_release/release
#
# See also: :var:`OC_USE_ARCHITECTURE_PATH`

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
        string(TOLOWER "${MPI_BUILD_TYPE}" MPI_BUILD_TYPE_LOWER)
        set(MPI_PART ${MPI}_${MPI_BUILD_TYPE_LOWER})
    endif()
    set(ARCHPATH ${ARCHPATH}/${MPI_PART})
    
    # Append to desired variable
    set(${VARNAME_MPI} ${ARCHPATH} PARENT_SCOPE)
    # The full architecture path without mpi is the same but with "no_mpi" at the same level
    string(REPLACE "/${MPI_PART}" "/no_mpi" ARCHPATH_NOMPI ${ARCHPATH})
    set(${VARNAME} ${ARCHPATH_NOMPI} PARENT_SCOPE)
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
    if (OC_MULTITHREADING)
        SET(ARCHPATH ${ARCHPATH}/mt)
    endif()
    
    # Append to desired variable
    SET(${VARNAME} ${ARCHPATH} PARENT_SCOPE)
endfunction()

function(getCompilerPathElem VARNAME)
    # Form the C compiler part
    # Get the C compiler name
    if(MINGW)
	set(_C_COMP "mingw" )
    elseif(MSYS )
	set(_C_COMP "msys" )
    elseif(BORLAND )
	set(_C_COMP "borland" )
    elseif(WATCOM )
	set(_C_COMP "watcom" )
    elseif(MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 )
	set(_C_COMP "msvc" )
    elseif(CMAKE_COMPILER_IS_GNUCC)
	set(_C_COMP "gnu")
    elseif(CMAKE_C_COMPILER_ID MATCHES Clang)
	set(_C_COMP "clang")
    elseif(CMAKE_C_COMPILER_ID MATCHES Intel 
	   OR CMAKE_CXX_COMPILER_ID MATCHES Intel)
	set(_C_COMP "intel")
    elseif(CMAKE_C_COMPILER_ID MATCHES PGI)
	set(_C_COMP "pgi")
    elseif( CYGWIN )
	set(_C_COMP "cygwin")
    else()
        set(_C_COMP "unknown")       
    endif()
	
    # Get compiler major + minor versions
    set(_COMPILER_VERSION_REGEX "^[0-9]+\.[0-9]+")
    string(REGEX MATCH ${_COMPILER_VERSION_REGEX}
       _C_COMPILER_VERSION_MM "${CMAKE_C_COMPILER_VERSION}")
    # Form C part
    set(_C_PART "${_C_COMP}-C${_C_COMPILER_VERSION_MM}")
 
    # Also for the fortran compiler (if exists)
    set(_FORTRAN_PART "")
    if (CMAKE_Fortran_COMPILER)
       # Get the Fortran compiler name
       if(CMAKE_Fortran_COMPILER_ID MATCHES Absoft)
	   set(_Fortran_COMP "absoft")
       elseif(CMAKE_Fortran_COMPILER_ID MATCHES Ccur)
	   set(_Fortran_COMP "ccur")
       elseif(CMAKE_Fortran_COMPILER_ID MATCHES GNU)
	   set(_Fortran_COMP "gnu")
       elseif(CMAKE_Fortran_COMPILER_ID MATCHES G95)
           set(_Fortran_COMP "g95")
       elseif(CMAKE_Fortran_COMPILER_ID MATCHES Intel)
           set(_Fortran_COMP "intel")
       elseif(CMAKE_Fortran_COMPILER_ID MATCHES PGI)
           set(_Fortran_COMP "pgi")
       else()
           set(_Fortran_COMP "unknown")       
       endif()
       string(REGEX MATCH ${_COMPILER_VERSION_REGEX}
           _Fortran_COMPILER_VERSION_MM "${CMAKE_Fortran_COMPILER_VERSION}")
       set(_FORTRAN_PART "-${_Fortran_COMP}-F${_Fortran_COMPILER_VERSION_MM}")
    endif()
    
    # Combine C and Fortran part into e.g. gnu-C4.8-intel-F4.5
    set(${VARNAME} "${_C_PART}${_FORTRAN_PART}" PARENT_SCOPE)
endfunction()

# Returns the build type arch path element.
# useful only for single-configuration builds, '.' otherwise.
function(getBuildTypePathElem VARNAME)
    # Build type
    if (NOT CMAKE_HAVE_MULTICONFIG_ENV)
        STRING(TOLOWER ${CMAKE_BUILD_TYPE} buildtype)
        SET(BUILDTYPEEXTRA ${buildtype})
    else()
        SET(BUILDTYPEEXTRA .)
    endif()
    SET(${VARNAME} ${BUILDTYPEEXTRA} PARENT_SCOPE)
endfunction()
