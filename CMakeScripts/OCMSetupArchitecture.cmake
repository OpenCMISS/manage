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
	    SET(${VARNAME} gcc-${VERSION})
	    #if( CMAKE_COMPILER_IS_GNUCC )
	    #    SET(${VARNAME} gcc-${VERSION})
	    #else()
	    #    SET(${VARNAME} gxx-${VERSION})
	    #endif()
	ELSEIF(${CMAKE_C_COMPILER} MATCHES icc 
	    OR ${CMAKE_CXX_COMPILER} MATCHES icpc
	    OR ${CMAKE_Fortran_COMPILER} MATCHES ifort)
	    SET(${VARNAME} "intel")
	ELSEIF( CYGWIN )
		SET(${VARNAME} "cygwin")
	ENDIF()
ENDMACRO()

# This function assembles the architecture path
# We have [ARCH][MPI][MT][COMPILER] so far
function(get_architecture_path VARNAME)
    SET(ARCHPATH )
    
    if(OCM_USE_ARCHITECTURE_PATH)
        # Architecture/System
        STRING(TOLOWER ${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_NAME_LOWER)
        SET(ARCHPATH ${CMAKE_SYSTEM_PROCESSOR}_${CMAKE_SYSTEM_NAME_LOWER})
        
        # Bit/Adressing bandwidth
        #if (ABI)
        #    SET(ARCHPATH ${ARCHPATH}/${ABI}bit)
        #endif()
        
        # MPI version information
        SET(MPI_PART )
        if (OCM_USE_MPI)
            if (MPI)
                # Take the MPI mnemonic if set
                SET(MPI_PART ${MPI})
            else()
                SET(MNEMONICS mpich mpich2 openmpi intel)
                # Patterns to match the include path
                SET(PATTERNS ".*mpich([/|-].*|$)" ".*mpich2([/|-].*|$)" ".*openmpi([/|-].*|$)" ".*(intel|impi)[/|-].*")
                foreach(IDX RANGE 3)
                    LIST(GET MNEMONICS ${IDX} MNEMONIC)
                    LIST(GET PATTERNS ${IDX} PATTERN)
                    #message(STATUS "Architecture: checking '${MPI_C_INCLUDE_PATH} MATCHES ${PATTERN} OR ${MPI_CXX_INCLUDE_PATH} MATCHES ${PATTERN}'")
                    if ("${MPI_C_INCLUDE_PATH}" MATCHES ${PATTERN} OR "${MPI_CXX_INCLUDE_PATH}" MATCHES ${PATTERN})
                        #message(STATUS "Architecture: match!")
                        SET(MPI_PART ${MNEMONIC})
                        break()
                    endif()
                endforeach()
                if (NOT MPI_PART)
                    get_filename_component(COMP_NAME ${MPI_C_COMPILER} NAME)
                    STRING(TOLOWER MPI_PART "unknown_${COMP_NAME}")
                endif()
            endif()
        else()
            SET(MPI_PART "sequential")
        endif()
        if (MPI_PART)
            SET(ARCHPATH ${ARCHPATH}/${MPI_PART})
        endif()
        
        # Multithreading
        if (OCM_USE_MT)
            SET(ARCHPATH ${ARCHPATH}/mt)
        endif()
        
        # Compiler
        GET_COMPILER_NAME(COMPILER)
        SET(ARCHPATH ${ARCHPATH}/${COMPILER})
        
    else()
        SET(ARCHPATH .)
    endif()
    
    #if (ARGC EQUAL 2 AND ARGV1 STREQUAL FULL)
    #    get_build_type_extra(BUILDTYPEEXTRA)
    #    SET(ARCHPATH ${ARCHPATH}/${BUILDTYPEEXTRA})
    #endif()
    
    # Append to desired variable
    SET(${VARNAME} ${ARCHPATH} PARENT_SCOPE)
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