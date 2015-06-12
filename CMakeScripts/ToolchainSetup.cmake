macro(ADDFLAG VARNAME VALUE)
    SET(${VARNAME} "${${VARNAME}} ${VALUE}")
endmacro()

macro(ADDFLAGALL SUFFIX VALUE)
    foreach(lang C CXX Fortran)        
        SET(CMAKE_${lang}_${SUFFIX} "${CMAKE_${lang}_${SUFFIX}} ${VALUE}")
    endforeach()
endmacro()

# ABI detection - no crosscompiling implemented yet, so will use native
#if (NOT ABI)
#if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
#	SET(ABI 64)
#else()
#	SET(ABI 32)
#endif()
#endif()
#foreach(lang C CXX Fortran)
#    SET(CMAKE_${lang}_FLAGS "-m${ABI} ${CMAKE_${lang}_FLAGS}")
#endforeach()

# In this file the (possibly) set compiler mnemonics are used to specify default compilers.
if (TOOLCHAIN)
    message(STATUS "Trying to use ${TOOLCHAIN} compilers..")
    STRING(TOLOWER "${TOOLCHAIN}" TOOLCHAIN)
    if (TOOLCHAIN STREQUAL "gnu" OR TOOLCHAIN STREQUAL "mingw")
        SET(CMAKE_C_COMPILER gcc)
        SET(CMAKE_CXX_COMPILER g++)
        SET(CMAKE_Fortran_COMPILER gfortran)
        
        # ABI Flag -m$(ABI)
        
        # Release
        ADDFLAGALL(FLAGS_RELEASE "-Ofast")
        
        # Debug
        if (OCM_WARN_ALL)
            ADDFLAGALL(FLAGS_DEBUG "-Wall -O0")
        endif()
        ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG -fbacktrace)
        # Compiler minor >= 8
        #ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-Warray-temporaries -Wextra -Wsurprising -Wrealloc-lhs-all")
        if (OCM_CHECK_ALL)
            # Compiler version 4.4
            #ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-fbounds-check")
            # Compiler minor >= 8
            #ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-finit-real=snan")
            # Newer versions
            ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-fcheck=all")
        endif()
        
    elseif (TOOLCHAIN STREQUAL "intel")
        SET(CMAKE_C_COMPILER icc)
        SET(CMAKE_CXX_COMPILER icpc)
        SET(CMAKE_Fortran_COMPILER ifort)
        
        # ABI Flag -m$(ABI)
        
        # Release
        #ADDFLAGALL(FLAGS_RELEASE "-fast") - commented out in original file
        ADDFLAGALL(FLAGS_RELEASE "-O3")
        
        # Debug
        ADDFLAGALL(FLAGS_DEBUG "-traceback")
        if (OCM_WARN_ALL)
            ADDFLAG(CMAKE_C_FLAGS_DEBUG "-Wall")
            ADDFLAG(CMAKE_CXX_FLAGS_DEBUG "-Wall")
            ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-warn all")
        endif()
        if (OCM_CHECK_ALL)
            ADDFLAG(CMAKE_C_FLAGS_DEBUG "-Wcheck -fp-trap=common -ftrapuv")
            ADDFLAG(CMAKE_CXX_FLAGS_DEBUG "-Wcheck -fp-trap=common -ftrapuv")
            ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-check all -fpe-all=0 -ftrapuv")
        endif()
        
    elseif(TOOLCHAIN STREQUAL "ibm")
        if (OCM_USE_MT)
            SET(CMAKE_C_COMPILER xlc_r)
            SET(CMAKE_CXX_COMPILER xlC_r)
            # F77=xlf77_r
            SET(CMAKE_Fortran_COMPILER xlf95_r)
            
            # FindOpenMP uses "-qsmp" for multithreading.. will need to see.
            ADDFLAGALL(FLAGS_RELEASE "-qomp")
            ADDFLAGALL(FLAGS_DEBUG "-qomp:noopt")
        else()
            SET(CMAKE_C_COMPILER xlc)
            SET(CMAKE_CXX_COMPILER xlC)
            # F77=xlf77
            SET(CMAKE_Fortran_COMPILER xlf95)
        endif()
        # ABI Flag -q$(ABI)
        
        # Instruction type - use auto here (pwr4-pwr7 available)
        ADDFLAGALL(FLAGS "-qarch=auto -qtune=auto")
        
        # Release
        ADDFLAGALL(FLAGS_RELEASE "-qstrict")
        
        # Debug
        if (OCM_WARN_ALL)
            # Assuming 64bit builds here. will need to see if that irritates the compiler for 32bit arch
            ADDFLAGALL(FLAGS_DEBUG "-qflag=i:i -qwarn64")
        endif()
        if (OCM_CHECK_ALL)
            ADDFLAGALL(FLAGS_DEBUG "-qcheck")
        endif()
    else()
        message(WARNING "Unknown toolchain: ${TOOLCHAIN}. Proceeding with CMake defaults.")
    endif()
endif()

# Thus far all compilers seem to use the -p flag for profiling
if (OCM_WITH_PROFILING)
    ADDFLAGALL(FLAGS "-p")
endif()

foreach(lang C CXX Fortran)
    if (CMAKE_${lang}_FLAGS)
        message(STATUS "${lang} FLAGS=${CMAKE_${lang}_FLAGS}")
    endif()
    if (CMAKE_${lang}_FLAGS_RELEASE)
        message(STATUS "${lang} FLAGS (RELEASE)=${CMAKE_${lang}_FLAGS_RELEASE}")
    endif()
    if (CMAKE_${lang}_FLAGS_DEBUG)
        message(STATUS "${lang} FLAGS (DEBUG)=${CMAKE_${lang}_FLAGS_DEBUG}")
    endif()
endforeach()