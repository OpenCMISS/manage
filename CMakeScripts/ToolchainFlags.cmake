macro(ADDFLAG VARNAME VALUE)
    SET(${VARNAME} "${${VARNAME}} ${VALUE}")
endmacro()

macro(ADDFLAGALL SUFFIX VALUE)
    foreach(lang C CXX Fortran)        
        SET(CMAKE_${lang}_${SUFFIX} "${CMAKE_${lang}_${SUFFIX}} ${VALUE}")
    endforeach()
endmacro()

include(CheckCCompilerFlag)
include(CheckFortranCompilerFlag)

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

if (CMAKE_COMPILER_IS_GNUC OR CMAKE_C_COMPILER_ID STREQUAL "GNU" OR MINGW)
    # ABI Flag -m$(ABI)
    
    # Release
    CHECK_C_COMPILER_FLAG("-Ofast" HAVE_OFAST_SUPPORT)
    if (HAVE_OFAST_SUPPORT)
        ADDFLAGALL(FLAGS_RELEASE "-Ofast")
    else()
        ADDFLAGALL(FLAGS_RELEASE "-O3")
    endif()
    
    # Debug
    ADDFLAGALL(FLAGS_DEBUG "-O0")
    if (OCM_WARN_ALL)
        ADDFLAGALL(FLAGS_DEBUG "-Wall")
    endif()
    ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG -fbacktrace)
    # Compiler minor >= 8
    if (CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER 4.7)
        ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-Warray-temporaries -Wextra -Wsurprising -Wrealloc-lhs-all")
    endif()
    if (OCM_CHECK_ALL)
        # Compiler version 4.4
        if (CMAKE_Fortran_COMPILER_VERSION VERSION_EQUAL 4.4)
            ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-fbounds-check")
        endif()
        # Compiler minor >= 8
        if (CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER 4.7)
            ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-finit-real=snan")
        endif()
        # Newer versions
        ADDFLAG(CMAKE_Fortran_FLAGS_DEBUG "-fcheck=all")
    endif()
    
elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel" OR CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
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
    
elseif(CMAKE_C_COMPILER_ID STREQUAL "XL" OR CMAKE_CXX_COMPILER_ID STREQUAL "XL") # IBM case
    if (OCM_USE_MT)
        # FindOpenMP uses "-qsmp" for multithreading.. will need to see.
        ADDFLAGALL(FLAGS_RELEASE "-qomp")
        ADDFLAGALL(FLAGS_DEBUG "-qomp:noopt")
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
endif()

# Thus far all compilers seem to use the -p flag for profiling
if (OCM_WITH_PROFILING)
    ADDFLAGALL(FLAGS "-p")
endif()

# Some verbose output for summary
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