##
# .. _`comp_version`:
# 
# <COMP>_VERSION
# --------------
#
# These variables are the essential part of the build systems package version management.
# 
# For each OpenCMISS component, this variable contains the current required (minimum) version for that component - 
# OpenCMISS uses Git in conjunction with version-number named branches to maintain 
# consistency and interoperability throughout all components.
# The Git repository default branches are constructed by a "v" prefix to the version: :code:`v${<COMP>_VERSION}`
#
# Those quantities are not intended to be changed by api-users, but might be subject to changes for development tests.
# Assuming the existence of the respective branches on GitHub, all that needs to be done to 
# change a package version is to set the version number accordingly.
# The setup will then checkout the specified version and attempt to build and link with it.
#
# .. caution::
#
#     Having a consistent set of interoperable packages (especially dependencies) is a nontrivial
#     task considering the amount of components, so be aware that hasty changes will most likely break the build!
#
# Moreover, those variables are also defined for all MPI implementations that can be built by the OpenCMISS build environment.
#
# See also: :ref:`component_branches`
set(BLAS_VERSION 3.5.0)
set(HYPRE_VERSION 2.10.0) # Alternatives: 2.9.0
set(LAPACK_VERSION 3.5.0)
set(LIBCELLML_VERSION 1.0)
set(METIS_VERSION 5.1)
set(MUMPS_VERSION 5.0.0) # Alternatives: 4.10.0
set(PASTIX_VERSION 5.2.2.16)
set(PARMETIS_VERSION 4.0.3)
set(PETSC_VERSION 3.6.1) # Alternatives: 3.5
set(PLAPACK_VERSION 3.0)
set(SCALAPACK_VERSION 2.8)
set(SCOTCH_VERSION 6.0.3)
set(SLEPC_VERSION 3.6.1) # Alternatives: 3.5, only if PETSC_VERSION matches
set(SOWING_VERSION 1.1.16)
set(SUITESPARSE_VERSION 4.4.0)
set(SUNDIALS_VERSION 2.5)
set(SUPERLU_VERSION 4.3)
set(SUPERLU_DIST_VERSION 4.1) # Alternatives: 3.3
set(ZLIB_VERSION 1.2.3)
set(BZIP2_VERSION 1.0.6) # Alternatives: 1.0.5
set(FIELDML-API_VERSION 0.5.0)
set(LIBXML2_VERSION 2.7.6) # Alternatives: 2.9.2
set(LLVM_VERSION 3.7.1)
set(CLANG_VERSION 3.7.1)
set(GTEST_VERSION 1.7.0)
set(SZIP_VERSION 2.1)
set(HDF5_VERSION 1.8.14)
set(JPEG_VERSION 6.0.0)
set(NETGEN_VERSION 4.9.11)
set(FREETYPE_VERSION 2.4.10)
set(FTGL_VERSION 2.1.3)
set(GLEW_VERSION 1.5.5)
set(OPTPP_VERSION 681)
set(PNG_VERSION 1.5.2)
set(TIFF_VERSION 4.0.5)# Alternatives: 3.8.2
set(GDCM-ABI_VERSION 2.0.12)
set(IMAGEMAGICK_VERSION 6.7.0.8)
set(ITK_VERSION 3.20.0)

# MPI
set(OPENMPI_VERSION 1.8.4) #1.8.4, 1.10.0 (unstable, does fail on e.g. ASES/Stuttgart)
set(MPICH_VERSION 3.1.3)
set(MVAPICH2_VERSION 2.1)

# Own components
set(CELLML_VERSION 1.0) # any will do, not used
set(CSIM_VERSION 1.0)
set(IRON_VERSION 0.6.0)
set(ZINC_VERSION 3.1)

# Examples
set(_BASE_EXAMPLE_VERSION 1.3)
set(classicalfield_laplace_simple_VERSION ${_BASE_EXAMPLE_VERSION})
