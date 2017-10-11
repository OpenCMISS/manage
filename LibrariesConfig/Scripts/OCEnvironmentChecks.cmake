
include(OCDetermineCXX11)

set(OC_ACTIVE_LANGUAGES)
foreach(_lang C CXX Fortran)
    # As we have already set the CMAKE_${_lang}_COMPILER in our mnemonics test we look
    # at the CMAKE_${_lang}_COMPILER_WORKS variable to see if the compiler is properly defined.
    # Note: We could also check that the compiler is an actual executable as an alternative.
    if (CMAKE_${_lang}_COMPILER_WORKS)
        list(APPEND OC_ACTIVE_LANGUAGES ${_lang})
    endif ()
endforeach()

if (Fortran IN_LIST OC_ACTIVE_LANGUAGES)
    set(OC_FORTRAN_IS_ENABLED TRUE)
else ()
    set(OC_FORTRAN_IS_ENABLED FALSE)
endif ()
