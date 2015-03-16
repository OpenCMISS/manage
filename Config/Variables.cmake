# List of all OpenCMISS components (used in default config)
SET(OPENCMISS_COMPONENTS BLAS LAPACK PLAPACK SCALAPACK PARMETIS
    SUITESPARSE MUMPS SUPERLU SUPERLU_DIST
    SUNDIALS SCOTCH SOWING PTSCOTCH PASTIX HYPRE PETSC
<<<<<<< HEAD
    LIBCELLML CELLML SLEPC ZLIB BZIP2 FIELDML LIBXML2 IRON MPI)
=======
    LIBCELLML CELLML SLEPC ZLIB IRON)
>>>>>>> 4f92ac1021e70705a6433c43b54a19662bd38c27

# Components using (any) MPI
# Used to determine when MPI compilers etc should be passed down to packages
SET(OPENCMISS_COMPONENTS_WITHMPI MUMPS PARMETIS PASTIX PETSC
    PLAPACK SCALAPACK SCOTCH SUITESPARSE
    SUNDIALS SUPERLU_DIST SLEPC HYPRE IRON)

# Components using OPENMP local threading
# Used to determine which dependencies get the WITH_OPENMP flag
SET(OPENCMISS_COMPONENTS_WITH_OPENMP HYPRE PARMETIS PASTIX
    PETSC PLAPACK SUITESPARSE SUPERLU_DIST)

# This file sets all the targets any (external/3rd party) component provides
SET(PACKAGES_WITH_TARGETS BLAS HYPRE LAPACK METIS
    MUMPS PARMETIS PASTIX PETSC PLAPACK PTSCOTCH SCALAPACK
    SCOTCH SOWING SUITESPARSE SUNDIALS SUPERLU SUPERLU_DIST ZLIB BZIP2 LIBXML2 FIELDML)

# The opencmiss components that are looked for on the local system instead of building it
<<<<<<< HEAD
SET(OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT BLAS LAPACK MPI)

=======
SET(OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT BLAS LAPACK)
    
>>>>>>> 4f92ac1021e70705a6433c43b54a19662bd38c27
SET(BLAS_TARGETS blas)
SET(HYPRE_TARGETS hypre)
SET(LAPACK_TARGETS lapack)
SET(METIS_TARGETS metis)
SET(MUMPS_TARGETS smumps dmumps cmumps zmumps mumps_common pord)
SET(PARMETIS_TARGETS parmetis metis)
SET(PASTIX_TARGETS pastix smatrix_driver dmatrix_driver zmatrix_driver cmatrix_driver)
SET(PETSC_TARGETS petsc)
SET(PLAPACK_TARGETS plapack)
SET(PTSCOTCH_TARGETS ptscotch scotch ptesmumps esmumps)
SET(SCALAPACK_TARGETS scalapack)
SET(SCOTCH_TARGETS scotch esmumps)
SET(SOWING_TARGETS sowing bfort)
SET(SUITESPARSE_TARGETS suitesparseconfig amd btf camd cholmod colamd ccolamd klu umfpack)
SET(SUNDIALS_TARGETS sundials_cvode sundials_fcvode sundials_cvodes
    sundials_ida sundials_fida sundials_idas
    sundials_kinsol sundials_fkinsol
    sundials_nvecparallel sundials_nvecserial
    )
SET(SUPERLU_TARGETS superlu)
SET(SUPERLU_DIST_TARGETS superlu_dist)
SET(SLEPC_TARGETS slepc)
SET(ZLIB_TARGETS z)
SET(BZIP2_TARGETS bzip2)
SET(LIBXML2_TARGETS xml2)
SET(FIELDML_TARGETS fieldml-api)


