############################################################
# MPI implementation detection
############################################################
set(_MNEMONICS
    mpich
    mpich2
    openmpi
    intel
    mvapich2
    msmpi
)
# Patterns to match the include and library paths - must be in same order as _MNEMONICS
set(_PATTERNS
    ".*mpich([/|-].*|$)"
    ".*mpich(2)?([/|-].*|$)"
    ".*open(-)?mpi([/|-].*|$)"
    ".*(intel|impi)[/|-].*"
    ".*mvapich(2)?([/|-].*|$)"
    ".*microsoft(.*|$)"
)

function(reset_mpi_version_search_variables)
    unset(I_MPI_VERSION_FOUND CACHE)
    unset(MPICH_VERSION_FOUND CACHE)
    unset(OMPI_MAJOR_VERSION_FOUND CACHE)
endfunction()

function(check_mpi_type lang)
    # Case insensitive match not possible with cmake regex :-(
    string(TOLOWER "${MPI_${lang}_INCLUDE_DIRS}" INC_PATH)
    string(TOLOWER "${MPI_${lang}_LIBRARIES}" LIB_PATH)
    if (MPI_HOME)
        string(TOLOWER "${MPI_HOME}" MPI_HOME_LOWER)
        string(FIND "${INC_PATH}" "${MPI_HOME_LOWER}" MPI_HOME_POS)
        if (MPI_HOME_POS EQUAL -1)
            unset_mpi(${lang})
            set(MPI_${lang}_FOUND FALSE PARENT_SCOPE)
            message(STATUS "Info: The current MPI-${lang} include path '${MPI_${lang}_INCLUDE_PATH}' does not contain the given MPI_HOME '${MPI_HOME}'. Previous MPI Cache entries have been removed. Please configure again.")
            return()
        endif()
    endif()
    foreach(IDX RANGE 5)
        list(GET _MNEMONICS ${IDX} MNEMONIC)
        list(GET _PATTERNS ${IDX} PATTERN)
        messaged("Checking '${INC_PATH} MATCHES ${PATTERN} OR ${LIB_PATH} MATCHES ${PATTERN}'")
        if (INC_PATH MATCHES ${PATTERN} OR LIB_PATH MATCHES ${PATTERN})
            # Pattern matches
            messaged("Detected MPI-${lang} implementation: ${MNEMONIC}")
            list(APPEND MPI_DETECTED_MNEMONICS ${MNEMONIC})
            break()
        else()
            messaged("Attempting to decide if MPI is '${MNEMONIC}'")
            # Getting desperate last resort is to scan mpi.h header file for (probable) symbols.
            include(CheckSymbolExists)
            if (MNEMONIC STREQUAL "mpich")
                set(CMAKE_REQUIRED_INCLUDES ${MPI_${lang}_INCLUDE_DIRS})
                check_symbol_exists(MPICH_VERSION "mpi.h" MPICH_VERSION_FOUND)
                check_symbol_exists(I_MPI_VERSION "mpi.h" I_MPI_VERSION_FOUND)
                unset(CMAKE_REQUIRED_INCLUDES)
                if (MPICH_VERSION_FOUND AND NOT I_MPI_VERSION_FOUND)
                    messaged("Detected MPI-${lang} implementation: ${MNEMONIC} by way of symbol check.")
                    list(APPEND MPI_DETECTED_MNEMONICS ${MNEMONIC})
                    break()
                endif ()
            elseif (MNEMONIC STREQUAL "openmpi")
                set(CMAKE_REQUIRED_INCLUDES ${MPI_${lang}_INCLUDE_DIRS})
                check_symbol_exists(OMPI_MAJOR_VERSION "mpi.h" OMPI_MAJOR_VERSION_FOUND)
                unset(CMAKE_REQUIRED_INCLUDES)
                if (OMPI_MAJOR_VERSION_FOUND)
                    messaged("Detected MPI-${lang} implementation: ${MNEMONIC} by way of symbol check.")
                    list(APPEND MPI_DETECTED_MNEMONICS ${MNEMONIC})
                    break()
                endif ()
            elseif (MNEMONIC STREQUAL "intel")
                set(CMAKE_REQUIRED_INCLUDES ${MPI_${lang}_INCLUDE_DIRS})
                check_symbol_exists(I_MPI_VERSION "mpi.h" I_MPI_VERSION_FOUND)
                unset(CMAKE_REQUIRED_INCLUDES)
                if (I_MPI_VERSION_FOUND)
                    messaged("Detected MPI-${lang} implementation: ${MNEMONIC} by way of symbol check.")
                    list(APPEND MPI_DETECTED_MNEMONICS ${MNEMONIC})
                    break()
                endif ()
            endif ()
        endif ()
    endforeach()
    set(MPI_DETECTED_MNEMONICS "${MPI_DETECTED_MNEMONICS}" PARENT_SCOPE)
endfunction()

function(determine_mpi_mnemonic _mnemonic_var)
    unset(MPI_DETECTED_MNEMONICS)

    reset_mpi_version_search_variables()
    foreach(_lang C CXX Fortran)
        if (CMAKE_${_lang}_COMPILER_LOADED)
            check_mpi_type(${_lang})
        endif ()
    endforeach()
    messaged("MPI_DETECTED_MNEMONICS: ${MPI_DETECTED_MNEMONICS}")

    list(GET MPI_DETECTED_MNEMONICS 0 MPI_DETECTED)
    foreach(_MNEMONIC ${MPI_DETECTED_MNEMONICS})
        if (NOT MPI_DETECTED STREQUAL _MNEMONIC)
            # Well, this shouldn't happen at all.
            message(FATAL_ERROR "Help! Not all the detected MPI types for each language are matching! This shouldn't happen! (MPI_DETECTED_MNEMONICS=${MPI_DETECTED_MNEMONICS})")
        endif()
    endforeach()

    set(${_mnemonic_var} ${MPI_DETECTED} PARENT_SCOPE)
endfunction()

function(GET_MPIEXEC_MNEMONIC MPIEXEC_EXECUTABLE mnemonic_var)
    execute_process(
        COMMAND ${MPIEXEC_EXECUTABLE} -version
        OUTPUT_VARIABLE  cmdline OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE   cmdline ERROR_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE  success
    )
    if (NOT success EQUAL 0)
       message(FATAL_ERROR "Check for mpiexec implementation failed.")
    endif ()
    messaged("OUTPUT_: ${cmdline}")
    if (cmdline MATCHES "mpich")
        set(mnemonic mpich)
    elseif (cmdline MATCHES "Intel Corporation")
        set(mnemonic intel)
    else ()
        message(STATUS "cmdline: ${cmdline}")
    endif ()

    set(${mnemonic_var} "${mnemonic}" PARENT_SCOPE)
endfunction()

macro(CLEAR_FIND_MPI_VARIABLES)
    unset(MPIEXEC_EXECUTABLE CACHE)
    unset(MPIEXEC_MAX_NUMPROCS CACHE)
    unset(MPIEXEC_NUMPROC_FLAG CACHE)
    unset(MPIEXEC_POSTFLAGS CACHE)
    unset(MPIEXEC_PREFLAGS CACHE)

    set(_LIB_NAMES)
    foreach (_lang C CXX Fortran)
        if (MPI_${_lang}_LIB_NAMES)
            list(APPEND _LIB_NAMES ${MPI_${_lang}_LIB_NAMES})
        endif ()
        unset(MPI_${_lang}_ADDITIONAL_INCLUDE_DIRS CACHE)
        unset(MPI_${_lang}_COMPILER CACHE)
        unset(MPI_${_lang}_COMPILE_DEFINITIONS CACHE)
        unset(MPI_${_lang}_COMPILE_OPTIONS CACHE)
        unset(MPI_${_lang}_HEADER_DIR CACHE)
        unset(MPI_${_lang}_LIB_NAMES CACHE)
        unset(MPI_${_lang}_LINK_FLAGS CACHE)
        unset(MPI_${_lang}_SKIP_MPICXX CACHE)
        unset(MPI_${_lang}_INCLUDE_DIRS)
        unset(MPI_${_lang}_WORKS)
        unset(MPI_${_lang}_INCLUDE_PATH)
        unset(MPI_${_lang}_VERSION)
        unset(MPI_${_lang}_LIBRARY)
        unset(MPI_${_lang}_LIBRARIES)
    endforeach()
    if (_LIB_NAMES)
        list(REMOVE_DUPLICATES _LIB_NAMES)
    endif ()
    foreach(_lib_name ${_LIB_NAMES})
        unset(MPI_${_lib_name}_LIBRARY CACHE)
    endforeach()

    unset(_MPI_MIN_VERSION)
    unset(MPI_VERSION)
    unset(MPI_VERSION_MAJOR)
    unset(MPI_VERSION_MINOR)

    unset(MPI_EXECUTABLE_SUFFIX)
    unset(MPI_C_HEADER_DIR CACHE)
    unset(MPI_CXX_HEADER_DIR CACHE)
    unset(MPI_Fortran_F77_HEADER_DIR CACHE)
    unset(MPI_Fortran_MODULE_DIR CACHE)
    unset(MPI_mpifptr_INCLUDE_DIR)
    unset(MPI_INCLUDE_DIRS_WORK)
    unset(MPI_FOUND)
    unset(MPI_COMPILER)
    unset(MPI_EXTRA_LIBRARY)
    unset(MPI_INCLUDE_PATH)
    unset(MPI_INCLUDE_DIRS)
    unset(MPI_LIBRARIES)
    unset(MPI_LIBRARY)
    unset(MPI_LIBRARY_WORK)
    unset(MPI_LINK_FLAGS)
endmacro()

macro(find_mpi_implementation)
    log("Looking for an MPI ...")
    if (OPENCMISS_TOOLCHAIN STREQUAL "intel" AND NOT CMAKE_C_COMPILER_ID STREQUAL "Intel")
        foreach(_lang C CXX Fortran)
            if (CMAKE_${_lang}_COMPILER_LOADED)
                set(STORED_CMAKE_${_lang}_COMPILER_ID ${CMAKE_${_lang}_COMPILER_ID})
                set(CMAKE_${_lang}_COMPILER_ID Intel)
                set(_restore_compiler_ids TRUE)
            endif ()
        endforeach()
    endif ()

    find_package(MPI QUIET)

    if (_restor_compiler_ids)
        foreach(_lang C CXX Fortran)
            if (CMAKE_${_lang}_COMPILER_LOADED)
                set(CMAKE_${_lang}_COMPILER_ID ${STORED_CMAKE_${_lang}_COMPILER_ID})
            endif ()
        endforeach()
    endif ()
    if (MPI_FOUND)
        determine_mpi_mnemonic(MPI_MNEMONIC)
        log("Looking for an MPI ... found ${MPI_MNEMONIC}")
    else ()
        log("Looking for an MPI ... not found")
    endif ()
endmacro()

