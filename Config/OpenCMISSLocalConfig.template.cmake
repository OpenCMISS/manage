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

# Choose your MPI type (beta status)
#SET(MPI mpich)
#SET(MPI mpich2)
#SET(MPI openmpi)
#SET(MPI intel)

# If you want to use only the shipped version of MPI and not the (default) local version, uncomment the following line.
#SET(OCM_MPI_LOCAL NO)

# Enter a custom mpi root directory here for a different mpi implementation.
# Leave as-is to use default system mpi.
#SET(MPI_HOME ~/software/openmpi-1.8.3_install)

# Further, you can specify an explicit name of the compiler
# executable (no path, just the name).
# This will be used independently of (but possibly with) the MPI_HOME setting.
#SET(MPI_C_COMPILER mpicc)
#SET(MPI_CXX_COMPILER mpic++)
#SET(MPI_Fortran_COMPILER mpif77)



###########################################################################
# Component configuration
###########################################################################

# Allow all components to be looked for locally at first
# In default config, this holds only for BLAS/LAPACK
#SET(OCM_ALL_LOCAL YES)

# To enable local lookup of single components, set
# OCM_<COMPONENT_NAME>_LOCAL to YES
${OCM_LOCAL_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}