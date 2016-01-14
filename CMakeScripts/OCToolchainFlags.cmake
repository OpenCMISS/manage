# Macro for adding a compile flag for a certain language (and optionally build type)
# Also performs a check if the current compiler supports the flag
#
# This needs to be included AFTER the MPIConfig as the used MPI mnemonic is used here, too!
macro(addFlag VALUE LANGUAGE)
    getFlagCheckVariableName(${VALUE} ${LANGUAGE} CHK_VAR)
    if (${LANGUAGE} STREQUAL C)
        CHECK_C_COMPILER_FLAG("${VALUE}" ${CHK_VAR})
    elseif(${LANGUAGE} STREQUAL CXX)
        CHECK_CXX_COMPILER_FLAG("${VALUE}" ${CHK_VAR})
    elseif(${LANGUAGE} STREQUAL Fortran)
        CHECK_Fortran_COMPILER_FLAG("${VALUE}" ${CHK_VAR})
    endif()
    # Only add the flag if the check succeeded
    if (${CHK_VAR})
        set(__FLAGS_VARNAME CMAKE_${LANGUAGE}_FLAGS)
        if (NOT "${ARGV2}" STREQUAL "")
            set(__FLAGS_VARNAME ${__FLAGS_VARNAME}_${ARGV2})
        endif()
        set(${__FLAGS_VARNAME} "${${__FLAGS_VARNAME}} ${VALUE}")
    endif()
endmacro()

macro(addFlagAll VALUE)
    foreach(lang C CXX Fortran)
        addFlag(${VALUE} ${lang} ${ARGV1})
    endforeach()
endmacro()

function(getFlagCheckVariableName FLAG LANGUAGE RESULT_VAR)
    if (${FLAG} MATCHES "^-.*")
        string(SUBSTRING ${FLAG} 1 -1 FLAG) 
    endif()
    string(REGEX REPLACE "[^a-zA-Z0-9 ]" "_" RES ${FLAG})
    set(${RESULT_VAR} ${LANGUAGE}_COMPILER_FLAG_${RES} PARENT_SCOPE)
endfunction()

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
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
    
    # These flags are set by CMake by default anyways.
    # addFlagAll("-O3" RELEASE)
    addFlagAll("-O0" DEBUG)
    
    # Release
    
    addFlagAll("-Ofast" RELEASE)
        
    # Debug
    
    if (OC_WARN_ALL)
        addFlagAll("-Wall" DEBUG)
    endif()
    addFlag("-fbacktrace" Fortran DEBUG)
    # Compiler minor >= 8
    if (CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER 4.7)
        addFlag("-Warray-temporaries" Fortran DEBUG)
        addFlag("-Wextra" Fortran DEBUG)
        addFlag("-Wsurprising" Fortran DEBUG)
        addFlag("-Wrealloc-lhs-all" Fortran DEBUG)
    endif()
    if (OC_CHECK_ALL)
        # Compiler version 4.4
        if (CMAKE_Fortran_COMPILER_VERSION VERSION_EQUAL 4.4)
            addFlag("-fbounds-check" Fortran DEBUG)
        endif()
        # Compiler minor >= 8
        if (CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER 4.7)
            addFlag("-finit-real=snan" Fortran DEBUG)
        endif()
        # Newer versions
        addFlag("-fcheck=all" Fortran DEBUG)
    endif()
    
elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel" OR CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
    # ABI Flag -m$(ABI)
    
    # CMake default anyways
    #addFlagAll("-O3" RELEASE)

    # Somehow CMake does not add the appropriate C-standard flags even though
    # the C_STANDARD variable is set. Well do it manually for now.
    #
    # EDIT: Unfortunately, this does not work out for all components. e.g. the gdcm build fails
    # with that switched on. Currently, i've added that flag for the superlu_dist package only. 
    #if (UNIX)
    #	addFlag("-std=c99" C)
    #endif()
    
    # Release
#    addFlagAll("-fast" RELEASE)
    
    # Debug
    addFlagAll("-traceback" DEBUG)
    if (OC_WARN_ALL)
        addFlag("-Wall" C DEBUG)
        addFlag("-Wall" CXX DEBUG)
        addFlag("-warn all" Fortran DEBUG)
    endif()
    if (OC_CHECK_ALL)
        foreach(lang C CXX)
            addFlag("-Wcheck" ${lang} DEBUG)
            addFlag("-fp-trap=common" ${lang} DEBUG)
            addFlag("-ftrapuv" ${lang} DEBUG)
        endforeach()
        addFlag("-check all" Fortran DEBUG)
        addFlag("-fpe-all=0" Fortran DEBUG)
        addFlag("-ftrapuv" Fortran DEBUG)
    endif()

elseif(CMAKE_C_COMPILER_ID STREQUAL "XL" OR CMAKE_CXX_COMPILER_ID STREQUAL "XL") # IBM case
    if (OC_MULTITHREADING)
        # FindOpenMP uses "-qsmp" for multithreading.. will need to see.
        addFlagAll("-qomp" RELEASE)
        addFlagAll("-qomp:noopt" DEBUG)
    endif()
    # ABI Flag -q$(ABI)
    
    # Instruction type - use auto here (pwr4-pwr7 available)
    addFlagAll("-qarch=auto")
    addFlagAll("-qtune=auto")
    
    # Release
    addFlagAll("-qstrict" RELEASE)
    
    # Debug
    if (OC_WARN_ALL)
        # Assuming 64bit builds here. will need to see if that irritates the compiler for 32bit arch
        addFlagAll("-qflag=i:i" DEBUG)
        addFlagAll("-qwarn64" DEBUG)
    endif()
    if (OC_CHECK_ALL)
        addFlagAll("-qcheck" DEBUG)
    endif()
endif()

# Thus far all compilers seem to use the -p flag for profiling
if (OC_PROFILING)
    addFlagAll("-p" )
endif()

#######################
# MPI - dependent flags

# For gnu/intel we need to add the skip flags to avoid SEEK_GET/SEEK_END definition errors
# See https://software.intel.com/en-us/articles/intel-cluster-toolkit-for-linux-error-when-compiling-c-aps-using-intel-mpi-library-compilation-driver-mpiicpc
# or google @#error "SEEK_SET is #defined but must not be for the C++ binding of MPI. Include mpi.h before stdio.h"@ 
if(CMAKE_COMPILER_IS_GNUC AND MPI STREQUAL intel)
    addFlagAll("-DMPICH_IGNORE_CXX_SEEK") # -DMPICH_SKIP_MPICXX
endif()

# Some verbose output for summary
foreach(lang C CXX Fortran)
    if (CMAKE_${lang}_FLAGS)
        message(STATUS "${lang} flags=${CMAKE_${lang}_FLAGS}")
    endif()
    if (CMAKE_${lang}_FLAGS_RELEASE)
        message(STATUS "${lang} flags (RELEASE)=${CMAKE_${lang}_FLAGS_RELEASE}")
    endif()
    if (CMAKE_${lang}_FLAGS_DEBUG)
        message(STATUS "${lang} flags (DEBUG)=${CMAKE_${lang}_FLAGS_DEBUG}")
    endif()
endforeach()
