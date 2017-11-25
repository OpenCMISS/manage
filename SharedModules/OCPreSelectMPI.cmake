# This module is used to condition the selection of the MPI if OPENCMISS_MPI is set

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

if (OPENCMISS_MPI)
    log("Pre-selecting MPI: ${OPENCMISS_MPI}")
    if (OPENCMISS_MPI IN_LIST _MNEMONICS)
    else ()
        message(FATAL_ERROR "Unknown MPI requested: ${OPENCMISS_MPI}, requested MPI must be one of ${_MNEMONICS}.")
    endif ()
endif ()
