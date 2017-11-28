
if (OPENCMISS_MPI AND NOT MPI_FOUND)
    message(FATAL_ERROR "Requested MPI: ${OPENCMISS_MPI} was not found.")
endif ()

determine_mpi_mnemonic(MPI_DETECTED)

if (OPENCMISS_MPI AND NOT OPENCMISS_MPI STREQUAL MPI_DETECTED)
    message(FATAL_ERROR "The MPI requested '${OPENCMISS_MPI}' and the MPI detected '${MPI_DETECTED}' do not match.")
endif ()

set(OPENCMISS_MPI_IMPLEMENTATION ${MPI_DETECTED})
