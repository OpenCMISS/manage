
SET(OC_INSTRUMENTATION none)
if (OC_INSTRUMENTATION)
    STRING(TOLOWER "${OC_INSTRUMENTATION}" OC_INSTRUMENTATION)
    if (OC_INSTRUMENTATION STREQUAL "scorep")
	# Reset compiler names to their scorep wrapper compiler name
	if(DEFINED CMAKE_C_COMPILER)
	  string(CONCAT CMAKE_C_COMPILER "scorep-" "${CMAKE_C_COMPILER}")
	endif()
	if(DEFINED CMAKE_CXX_COMPILER)
	  string(CONCAT CMAKE_CXX_COMPILER "scorep-" "${CMAKE_CXX_COMPILER}")
	endif()
	if(DEFINED CMAKE_Fortran_COMPILER)
	  string(CONCAT CMAKE_Fortran_COMPILER "scorep-" "${CMAKE_Fortran_COMPILER}")
	endif()
    elseif (OC_INSTRUMENTATION STREQUAL "vtune")
#        if(TOOLCHAIN STREQUAL "intel")
          SET(OC_INSTRUMENTATION vtune)
#	else()
#          message(WARNING "Can only use vtune instrumentation with an Intel toolchain. Proceeding with no instrumentation.")
#        endif()
    elseif (INSTRUMENTATION STREQUAL "none")
        # Do nothing

    else()
        message(WARNING "Unknown instrumentation: ${OC_INSTRUMENTATION}. Proceeding with no instrumentation.")
    endif()
endif()

#message(STATUS "DEBUG: OC_INSTRUMENTATION     = ${OC_INSTRUMENTATION}")
#message(STATUS "DEBUG: CMAKE_C_COMPILER       = ${CMAKE_C_COMPILER}")
#message(STATUS "DEBUG: CMAKE_CXX_COMPILER     = ${CMAKE_CXX_COMPILER}")
#message(STATUS "DEBUG: CMAKE_Fortran_COMPILER = ${CMAKE_Fortran_COMPILER}")

