# SET(OCM_DEVELOPER_MODE ON)

#SET(BUILD_IRON "Build OpenCMISS-Iron" NO)
#SET(BUILD_ZINC "Build OpenCMISS-Zinc" NO)
#SET(OCM_USE_ARCHITECTURE_PATH NO)
#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)
#SET(BUILD_SHARED_LIBS YES)

# ==============================
# MPI
# ==============================
# Global MPI flag
#SET(OCM_USE_MPI NO)
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

# Force to use all OpenCMISS dependencies - long compilation, but will work
#SET(FORCE_OCM_ALLDEPS NO)

#SET(OCM_USE_BLAS NO)
#SET(OCM_USE_LAPACK NO)
#SET(OCM_USE_SCALAPACK NO)
#SET(OCM_USE_MUMPS NO)
#SET(OCM_USE_METIS NO)
#SET(OCM_USE_PLAPACK NO)
#SET(OCM_USE_PTSCOTCH NO)
#SET(OCM_USE_SCOTCH NO)
#SET(OCM_USE_SUITESPARSE NO)
#SET(OCM_USE_SUNDIALS NO)
#SET(OCM_USE_SUPERLU NO)
#SET(OCM_USE_SUPERLU_DIST NO)
#SET(OCM_USE_PARMETIS NO)
#SET(OCM_USE_PASTIX NO)
#SET(OCM_USE_HYPRE NO)
#SET(OCM_USE_PETSC NO)
#SET(OCM_USE_SLEPC NO)
#SET(OCM_USE_LIBCELLML NO)

# To enforce use of the shipped package, set OCM_FORCE_<PACKAGE>=YES e.g.
#  SET(OCM_FORCE_BLAS YES)
# for BLAS libraries.