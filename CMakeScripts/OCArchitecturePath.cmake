##
# In order to allow simultaneous installation of builds for various configuration and choices,
# OpenCMISS uses an *architecture path* to store produced files, libraries and headers into separate
# directories.
#
# The architecture path is composed of the following elements (in that order)
#
#    :architecture: The system architecture, e.g. :literal:`x86_64_linux` 
#    :toolchain: The toolchain info for the build.
#        This path is composed following the pattern :path:`/<mnemonic>-<version>-F<fortran_version>`,
#        where *mnemonic* stands for one of the items below, *version* the version of the C compiler and
#        *fortran_version* the version of the Fortran compiler.
# 
#        All the short mnemonics are:
#        
#            :borland: The Borland compilers
#            :clang: The CLang toolchain (commonly Mac OS)
#            :cygwin: The CygWin toolchain for Windows environments
#            :gnu: The GNU toolchain
#            :intel: The Intel toolchain
#            :mingw: The MinGW toolchain for Windows environments
#            :msvc: MS Visual Studio compilers
#            :watcom: The Watcom toolchain
#    
#    :multithreading: If :var:`OC_USE_MULTITHREADING` is enabled, this segment is :path:`/mt`.
#        Otherwise, the path element is skipped.
#    :mpi: Denotes the used MPI implementation along with the mpi build type.
#        The path element is composed as :path:`/<mnemonic>_<mpi-build-type>`, where *mnemonic*/*mpi-build-type* contains the 
#        lower-case value of the :var:`MPI`/:var:`MPI_BUILD_TYPE` variable, respectively.
#
#        Moreover, a path element :path:`no_mpi` is used for any component that does not use MPI at all.  
#    :buildtype: Path element for the current overall build type determined by :var:`CMAKE_BUILD_TYPE`.
#
# For example, a typical architecture path looks like::
#
#     x86_64_linux/gnu-4.6-F4.6/openmpi_release/release
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
	
	# Get compiler major + minor versions
	set(_COMPILER_VERSION_REGEX "^[0-9]+\.[0-9]+")
	string(REGEX MATCH ${_COMPILER_VERSION_REGEX}
       _C_COMPILER_VERSION_MM "${CMAKE_C_COMPILER_VERSION}")
    # Also for the fortran compiler (if exists)
    set(_FORTRAN_PART "")
    if (CMAKE_Fortran_COMPILER)
        string(REGEX MATCH ${_COMPILER_VERSION_REGEX}
           _Fortran_COMPILER_VERSION_MM "${CMAKE_Fortran_COMPILER_VERSION}")
        set(_FORTRAN_PART "-F${_Fortran_COMPILER_VERSION_MM}")
    endif()
    
    # Combine into e.g. gnu-4.8-F4.5
	set(${VARNAME} "${_COMP}-${_C_COMPILER_VERSION_MM}${_FORTRAN_PART}" PARENT_SCOPE)
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