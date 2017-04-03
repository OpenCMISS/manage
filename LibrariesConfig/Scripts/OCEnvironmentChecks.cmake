
# Check for C++11 capability.
if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU")
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -dumpversion OUTPUT_VARIABLE GCC_VERSION)
    if (NOT (GCC_VERSION VERSION_GREATER 4.7 OR GCC_VERSION VERSION_EQUAL 4.7))
        set(OC_CAN_BUILD_LLVM FALSE)
    else ()
        set(OC_CAN_BUILD_LLVM TRUE)
    endif ()
else ()
    set(OC_CAN_BUILD_LLVM TRUE)
endif ()

set(OC_ACTIVE_LANGUAGES)
foreach(_lang C CXX Fortran)
    if (CMAKE_${_lang}_COMPILER)
        list(APPEND OC_ACTIVE_LANGUAGES ${_lang})
    endif ()
endforeach()

if (Fortran IN_LIST OC_ACTIVE_LANGUAGES)
    set(OC_FORTRAN_IS_ENABLED TRUE)
else ()
    set(OC_FORTRAN_IS_ENABLED FALSE)
endif ()
