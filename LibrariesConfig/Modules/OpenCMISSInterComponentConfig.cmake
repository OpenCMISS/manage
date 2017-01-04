##
# Some OpenCMISS components depend on or can use each other. Therefore, the build system
# provides flags of the type :cmake:`A_USE_B` or :cmake:`A_WITH_B` to control component connectivity. 
#
# .. note::
#
#     These flags only apply if the corresponding package is build by the OpenCMISS Dependencies system.
#     The packages themselves will then search for the appropriate consumed packages.
#     No checks are performed on whether the consumed packages
#     will also be build by us or not, as they might be provided externally.
#
# .. caution:: 
#
#    Take care to also enable the appropriate :var:`OC_USE_<COMP>` flags.
#    For example, if you wanted to use MUMPS with SCOTCH, also set :cmake:`OC_USE_SCOTCH=YES` so that
#    the build system ensures that SCOTCH will be available.
#
# The full list of available inter-component connection flags is as follows (defaults added):

##
#    CELLML_WITH_CSIM : NO
#        Load CellML models through CSim
option(CELLML_WITH_CSIM "Enable FieldML HDF5 support" NO)

##
#    FIELDML-API_WITH_HDF5 : NO
#        Enable FieldML HDF5 support
#    FIELDML-API_WITH_JAVA_BINDINGS : NO
#        Build Java bindings for FieldML
#    FIELDML-API_WITH_FORTRAN_BINDINGS : YES
#        Build Fortran bindings for FieldML
option(FIELDML-API_WITH_HDF5 "Enable FieldML HDF5 support" NO)
option(FIELDML-API_WITH_JAVA_BINDINGS "Build Java bindings for FieldML" NO)
option(FIELDML-API_WITH_FORTRAN_BINDINGS "Build Fortran bindings for FieldML" YES)

##
#    HDF5_WITH_MPI : YES
#        Build HDF5 with MPI support
#    HDF5_WITH_SZIP : YES
#        Have HDF5 use szip
#    HDF5_WITH_ZLIB : YES
#        Have HDF5 use zlib
#    HDF5_BUILD_FORTRAN : NO
#        Build Fortran interface for HDF5
option(HDF5_WITH_MPI "Build HDF5 with MPI support" NO)
option(HDF5_WITH_SZIP "Have HDF5 use szip" YES)
option(HDF5_WITH_ZLIB "Have HDF5 use zlib" YES)
option(HDF5_BUILD_FORTRAN "Build Fortran interface for HDF5" NO)

##
#    IRON_WITH_CELLML : YES
#        Have Iron use CellML
#    IRON_WITH_FIELDML : YES
#        Have Iron use FieldML
#    IRON_WITH_HYPRE : YES
#        Have Iron use Hypre
#    IRON_WITH_SUNDIALS : YES
#        Have Iron use Sundials
#    IRON_WITH_MUMPS : YES
#        Have Sundials use LAPACK
#    IRON_WITH_SCALAPACK : YES
#        Have Iron use ScaLAPACK
#    IRON_WITH_PETSC : YES
#        Have Iron use PetSC
#    IRON_WITH_C_BINDINGS : YES
#        Build Iron-C bindings
#    IRON_WITH_Python_BINDINGS : YES if Python bindings prerequisites are given, NO otherwise
#        Build Iron-Python bindings. This setting is automatically enabled if the build system
#        finds local Python(-libraries) and Swig. 
option(IRON_WITH_CELLML "Have Iron use CellML" YES)
option(IRON_WITH_FIELDML "Have Iron use FieldML" YES)
option(IRON_WITH_HYPRE "Have Iron use Hypre" YES)
option(IRON_WITH_SUNDIALS "Have Iron use Sundials" YES)
option(IRON_WITH_MUMPS "Have Iron use MUMPS" YES)
option(IRON_WITH_SCALAPACK "Have Iron use ScaLAPACK" YES)
option(IRON_WITH_PETSC "Have Iron use PetSC" YES)
option(IRON_WITH_C_BINDINGS "Build Iron-C bindings" YES)
option(IRON_WITH_Python_BINDINGS "Build Iron-Python bindings" ${OC_PYTHON_PREREQ_FOUND})

##
#    LIBXML2_WITH_ZLIB : YES
#        Build LibXML2 with zLib compression support
option(LIBXML2_WITH_ZLIB "Build LibXML2 with zLib compression support"  YES)

##
#    MUMPS_WITH_SCOTCH : NO
#        Have MUMPS use Scotch.
#    MUMPS_WITH_PTSCOTCH : YES
#        Have MUMPS use PT-Scotch.
#    MUMPS_WITH_METIS : NO
#        Have MUMPS use Metis.
#    MUMPS_WITH_PARMETIS
#        Have MUMPS use Parmetis.
option(MUMPS_WITH_SCOTCH "Have MUMPS use Scotch" NO)
option(MUMPS_WITH_PTSCOTCH "Have MUMPS use PT-Scotch" YES)
option(MUMPS_WITH_METIS "Have MUMPS use Metis" NO)
option(MUMPS_WITH_PARMETIS "Have MUMPS use Parmetis" YES)

##
#    OPTPP_WITH_BLAS : NO
#        Have Opt++ use external BLAS routines. Use only when system BLAS is available or you have a Fortran compiler and build your own BLAS/LAPACK.
option(OPTPP_WITH_BLAS "Have Opt++ use external BLAS routines" NO)

##
#    PASTIX_USE_THREADS : YES
#        Have Sundials use LAPACK
#    PASTIX_WITH_METIS : YES
#        Have PASTIX use Metis
#    PASTIX_WITH_PTSCOTCH : YES
#        Have PASTIX use PT-Scotch
option(PASTIX_USE_THREADS "Enable use of threading for PASTIX" YES)
option(PASTIX_WITH_METIS "Have PASTIX use Metis" YES)
option(PASTIX_WITH_PTSCOTCH "Have PASTIX use PT-Scotch" YES)

##
#    PETSC_WITH_HYPRE : YES
#        Have PetSC use HYPRE
#    PETSC_WITH_MUMPS : YES
#        Have PetSC use MUMPS
#    PETSC_WITH_PARMETIS : YES
#        Have PetSC use PARMETIS
#    PETSC_WITH_PASTIX : YES
#        Have PetSC use PASTIX. Defaults to NO for Visual Studio.
#    PETSC_WITH_PTSCOTCH : YES
#        Have PetSC use PTSCOTCH
#    PETSC_WITH_SCALAPACK : YES
#        Have PetSC use SCALAPACK
#    PETSC_WITH_SUITESPARSE : YES
#        Have PetSC use SUITESPARSE
#    PETSC_WITH_SUNDIALS : YES
#        Have PetSC use SUNDIALS
#    PETSC_WITH_SUPERLU : YES
#        Have PetSC use SUPERLU
#    PETSC_WITH_SUPERLU_DIST : YES
#        Have PetSC use SUPERLU_DIST
set(_VAL YES)
if (MSVC)
    set(_VAL NO)
endif()
option(PETSC_WITH_PASTIX "Have PetSC use PASTIX" ${_VAL})
option(PETSC_WITH_MUMPS "Have PetSC use MUMPS" YES)
option(PETSC_WITH_SUITESPARSE "Have PetSC use SUITESPARSE" YES)
option(PETSC_WITH_SCALAPACK "Have PetSC use SCALAPACK" YES)
option(PETSC_WITH_PTSCOTCH "Have PetSC use PTSCOTCH" YES)
option(PETSC_WITH_SUPERLU "Have PetSC use SUPERLU" YES)
option(PETSC_WITH_SUNDIALS "Have PetSC use SUNDIALS" YES)
option(PETSC_WITH_HYPRE "Have PetSC use HYPRE" YES)
option(PETSC_WITH_SUPERLU_DIST "Have PetSC use SUPERLU_DIST" YES)
option(PETSC_WITH_PARMETIS "Have PetSC use PARMETIS" YES)

##
#    SCOTCH_USE_THREADS : YES
#        Enable use of threading for Scotch/PT-Scotch
#    SCOTCH_WITH_ZLIB : YES
#        Have Scotch/PT-Scotch use zlib
#    SCOTCH_WITH_BZIP2 : YES
#        Have Scotch/PT-Scotch use bzip2
option(SCOTCH_USE_THREADS "Enable use of threading for Scotch/PT-Scotch" YES)
option(SCOTCH_WITH_ZLIB "Have Scotch/PT-Scotch use zlib" YES)
option(SCOTCH_WITH_BZIP2 "Have Scotch/PT-Scotch use bzip2" YES)

##
#    SUNDIALS_WITH_LAPACK : YES
#        Have Sundials use LAPACK
option(SUNDIALS_WITH_LAPACK "Have Sundials use LAPACK" YES)

##
#    SUPERLU_DIST_WITH_PARMETIS : YES
#        Enable Parmetis support for SuperLU-Dist
option(SUPERLU_DIST_WITH_PARMETIS "Enable Parmetis support for SuperLU-Dist" YES)

##
#    ZINC_WITH_Python_BINDINGS : YES if Python bindings prerequisites are given, NO otherwise
#        Build Python bindings for ZINC. This setting is automatically enabled if the build system
#        finds local Python(-libraries) and Swig
option(ZINC_WITH_Python_BINDINGS "Build Python bindings for ZINC" ${OC_PYTHON_PREREQ_FOUND})
