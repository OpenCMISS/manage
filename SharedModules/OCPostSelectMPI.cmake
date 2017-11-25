
if (OPENCMISS_MPI AND NOT MPI_FOUND)
    message(FATAL_ERROR "Requested MPI: ${OPENCMISS_MPI} was not found.")
endif ()

# Determine MPI_IMPLEMENTATION
set(MPI_IMPLEMENTATION bob)

message(STATUS "Pass these variables onto dependencies that use MPI.")
message(STATUS "MPIEXEC_EXECUTABLE: ${MPIEXEC_EXECUTABLE}")
message(STATUS "MPI_VERSION: ${MPI_VERSION}")
foreach(_lang C CXX Fortran)
    message(STATUS "MPI_${_lang}_FOUND: ${MPI_${_lang}_FOUND}")
    message(STATUS "MPI_${_lang}_COMPILER: ${MPI_${_lang}_COMPILER}")
endforeach()
