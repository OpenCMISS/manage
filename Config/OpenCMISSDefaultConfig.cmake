# ==============================
# Build configuration
# ==============================
SET(OCM_USE_IRON YES)
SET(IRON_BRANCH master)
SET(IRON_REPO https://github.com/OpenCMISS/cm.git)

SET(OCM_USE_ZINC NO)

# Use architecture information paths
SET(OCM_USE_ARCHITECTURE_PATH YES)

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

# ==============================
# Compiler
# ==============================

# ==============================
# Multithreading
# This controls openmp/OpenAcc
# ==============================
option(OCM_USE_MT "Use multithreading in OpenCMISS (where applicable)" NO)

# ==============================
# MPI
# ==============================
# Global MPI flag
option(OCM_USE_MPI "Use MPI in OpenCMISS (not cared about eveywhere yet)!" YES)
# @@@ linux @@@
# mpich: gnu
# mpich2: gnu
# openmpi: gnu
# intel: needs I_MPI_ROOT
#  - also needs to know if GNU or INTEL compiler
# mvapich2: works only with MPI_INSTALL_DIR defined
# poe: not implemented
# cray: have special path
# @@@ aix @@@
# poe: 
# @@@ windows @@@
# mpich, mpich2: fixed directory
#SET(MPI mpich)
#SET(MPI mpich2)
#SET(MPI openmpi)
#SET(MPI intel)

# Enter a custom mpi root directory here for a different mpi implementation.
# Leave as-is to use default system mpi.
#SET(MPI_HOME ~/software/openmpi-1.8.3_install)

# Further, you can specify an explicit name of the compiler
# executable (no path, just the name).
# This will be used independently of (but possibly with) the MPI_HOME setting.
#SET(MPI_C_COMPILER mpicc)
#SET(MPI_CXX_COMPILER mpic++)
#SET(MPI_Fortran_COMPILER mpif77)

# To enforce use of the shipped package, set OCM_FORCE_<PACKAGE>=YES e.g.
#  SET(OCM_FORCE_BLAS YES)
# for BLAS libraries.

# Default: Build all dependencies
# This is changeable in the OpenCMISSLocalConfig file
FOREACH(OCM_DEP ${OPENCMISS_COMPONENTS})
    SET(OCM_USE_${OCM_DEP} YES)
ENDFOREACH()

# Look for local BLAS/LAPACK packages by default; the rest is built
SET(OCM_BLAS_LOCAL YES)
SET(OCM_LAPACK_LOCAL YES)

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