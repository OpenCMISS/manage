# ==============================
# Build configuration
# ==============================
SET(OCM_USE_IRON YES)
# will be "master" finally
SET(IRON_BRANCH iron)
# Needs to be here until the repo's name is "iron", then it's compiled automatically (see Iron.cmake/BuildMacros)
SET(IRON_REPO https://github.com/OpenCMISS/cm)

SET(OCM_USE_ZINC NO)

# Precision to build (if applicable)
# Valid choices are s,d,c,z and any combinations.
# s: Single / float precision
# d: Double precision
# c: Complex / float precision
# z: Complex / double precision
SET(BUILD_PRECISION sd)

# The integer types that can be used (if applicable)
# Used only by PASTIX yet
SET(INT_TYPE int32)

# Also build tests?
SET(BUILD_TESTS ON)

# Type of libraries to build
option(BUILD_SHARED_LIBS "Build shared libraries" NO)
option(OCM_POSITION_INDEPENDENT_CODE "Always generate position independent code (-fPIC flag)" NO)

# ==============================
# Compilers
# ==============================
# Flag for DEBUG configuration builds only! 
SET(OCM_WARN_ALL YES)
SET(OCM_CHECK_ALL YES)

# ==============================
# Multithreading
# This controls openmp/OpenAcc
# ==============================
option(OCM_USE_MT "Use multithreading in OpenCMISS (where applicable)" NO)

# ==============================
# MPI
# ==============================
# Global MPI flag
option(OCM_USE_MPI "Use MPI in OpenCMISS (not cared about everywhere yet)!" YES)

# Unless MPI is already specified (e.g. on command line), try to suggest 
if (NOT DEFINED MPI)
    # Detect the current operating system and set "our" default MPI versions.
    if (UNIX)
        if (NOT DEFINED LINUX_DISTRIBUTION)
            SET(LINUX_DISTRIBUTION FALSE CACHE STRING "Distribution information")
            find_program(LSB lsb_release 
                DOC "Distribution information tool")
            if (LSB)
                execute_process(COMMAND ${LSB} -i
                    RESULT_VARIABLE RETFLAG 
                    OUTPUT_VARIABLE DISTINFO
                    ERROR_VARIABLE ERRDISTINFO
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                )
                if (NOT RETFLAG)
                    STRING(SUBSTRING ${DISTINFO} 16 -1 LINUX_DISTRIBUTION)
                endif()
            endif() 
        endif()
        if (LINUX_DISTRIBUTION STREQUAL "Ubuntu" OR LINUX_DISTRIBUTION STREQUAL "Scientific")
            SET(MPI openmpi CACHE STRING "MPI implementation type")
        elseif(LINUX_DISTRIBUTION STREQUAL "Fedora" OR LINUX_DISTRIBUTION STREQUAL "RedHat")
            SET(MPI mpich CACHE STRING "MPI implementation type")
        else()
            SET(MPI "" CACHE STRING "MPI implementation type")
        endif()
        if (MPI)
            message(STATUS "Using suggested MPI '${MPI}' on Linux/${LINUX_DISTRIBUTION}")
        else()
            message(WARNING "Unknown distribution '${LINUX_DISTRIBUTION}': No default MPI recommendation")
        endif()
    endif()
endif()

# Prefer system MPI versions over shipped one (try to find the version set by MPI mnemonic!)
SET(OCM_SYSTEM_MPI YES)

# Versions to use if we build a local version ourselves
SET(OPENMPI_VERSION 1.8.4)
SET(MPICH2_VERSION 3.1.3)

# Enter a custom mpi root directory here for a different mpi implementation.
# Leave as-is to use default system mpi.
#SET(MPI_HOME ~/software/openmpi-1.8.3_install)

# Further, you can specify an explicit name of the compiler
# executable (no path, just the name).
# This will be used independently of (but possibly with) the MPI_HOME setting.
#SET(MPI_C_COMPILER mpicc)
#SET(MPI_CXX_COMPILER mpic++)
#SET(MPI_Fortran_COMPILER mpif77)

# Default: Build all dependencies
# This is changeable in the OpenCMISSLocalConfig file
FOREACH(OCM_DEP ${OPENCMISS_COMPONENTS})
    SET(OCM_USE_${OCM_DEP} YES)
    SET(OCM_SYSTEM_${OCM_DEP} NO)
ENDFOREACH()

# Look for local BLAS/LAPACK packages by default; the rest is built
SET(OCM_SYSTEM_BLAS YES)
SET(OCM_SYSTEM_LAPACK YES)

# Dependencies
SET(BLAS_VERSION 3.5.0)
SET(HYPRE_VERSION 2.9.0)
SET(LAPACK_VERSION 3.5.0)
SET(LIBCELLML_VERSION 1.0)
SET(METIS_VERSION 5.1)
SET(MUMPS_VERSION 4.10.0)
SET(PASTIX_VERSION 5.2.2.16)
SET(PARMETIS_VERSION 4.0.3)
SET(PETSC_VERSION 3.5)
SET(PLAPACK_VERSION 3.0)
SET(PTSCOTCH_VERSION 6.0.3)
SET(SCALAPACK_VERSION 2.8)
SET(SCOTCH_VERSION 6.0.3)
SET(SLEPC_VERSION 3.5)
SET(SOWING_VERSION 1.1.16)
SET(SUITESPARSE_VERSION 4.4.0)
SET(SUNDIALS_VERSION 2.5)
SET(SUPERLU_VERSION 4.3)
SET(SUPERLU_DIST_VERSION 3.3)
SET(ZLIB_VERSION 1.2.3)

# ==========================================================================================
# Single module configuration
#
# These flags only apply if the corresponding package is build
# by the OpenCMISS Dependencies system. The packages themselves will then search for the
# appropriate consumed packages. No checks are performed on whether the consumed packages
# will also be build by us or not, as they might be provided externally.
#
# To be safe: E.g. if you wanted to use MUMPS with SCOTCH, also set OCM_USE_SCOTCH=YES so that
# the build system ensures that SCOTCH will be available.
# ==========================================================================================
SET(MUMPS_WITH_SCOTCH NO)
SET(MUMPS_WITH_PTSCOTCH YES)
#SET(MUMPS_WITH_METIS YES)
#SET(MUMPS_WITH_PARMETIS NO)

SET(SUNDIALS_WITH_LAPACK YES)

SET(SCOTCH_USE_THREADS YES)
SET(SCOTCH_WITH_ZLIB YES)

SET(SUPERLU_DIST_WITH_PARMETIS YES)

SET(PASTIX_USE_THREADS YES)
SET(PASTIX_USE_METIS YES)
SET(PASTIX_USE_PTSCOTCH YES)

SET(IRON_WITH_CELLML YES)