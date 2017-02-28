# This is the main configuration file for OpenCMISS developers.
#
# See http://www.opencmiss.org/documentation/cmake/docs/config/developer for more details
# or see the subsequent comments.

##
# .. _`component_branches`:
#
# <COMP>_BRANCH
# -------------
#
# Manually set the target branch to checkout for the specified component. Applies to own builds only.
# If this variable is not set, the build system automatically derives the branch name
# from the :var:`<COMP>_VERSION` variable (pattern :cmake:`v<COMP>_VERSION`).
#
# See also: `<COMP>_REPO`_ :ref:`comp_version`

#set(IRON_BRANCH myironbranch)

##
# <COMP>_DEVEL
# ------------
#
# At first, a flag :var:`<COMPNAME>_DEVEL` must be set in order to notify the setup that
# this component (Iron, Zinc, any dependency) should be under development.
#
# See also: `OPENCMISS_DEVEL_ALL`_.
#
# .. default:: NO

#set(IRON_DEVEL YES)

##
# <COMP>_REPO
# ---------------
#
# Set this variable for any component to have the build system checkout the sources from that repository. Applies to own builds only.
#
# If this variable is not specified, the build system setup chooses the default
# public locations at the respective GitHub organizations (OpenCMISS, OpenCMISS-Dependencies etc).
# 
# .. caution::
# 
#    Those adoptions *must* currently be made before the first build is started - once a repository is
#    created there is no logic on changing the repository location (has at least not been tested).
#
# Use in conjunction with `<COMP>_BRANCH`_ if necessary.

#set(IRON_REPO git@github.com:mygithub/iron)

##
# GITHUB_USERNAME
# ---------------
#
# If you set a github username, cmake will automatically try and locate all the
# components as repositories under that github account.
# Currently applies to **all** repositories.
#
# .. default:: <empty>
set(GITHUB_USERNAME )

##
# OC_CLEAN_REBUILDS_COMPONENTS
# ----------------------------
#
# If you issue "make clean" from the manage build folder, normally the external projects (i.e. dependencies) wont completely re-build.
# Set this to true to have the build system remove the CMakeCache.txt of each dependency, which triggers a complete re-build.
# 
# .. default:: YES 
set(OC_CLEAN_REBUILDS_COMPONENTS YES)

##
# OC_DEFAULT_MPI
# --------------
#
# When installing OpenCMISS, the opencmiss-config file defines a default MPI version.
#
# If unspecified, this will always be set to the version used for the latest build.
#
# .. default:: mpich
set(OC_DEFAULT_MPI mpich)

##
# OC_DEFAULT_MPI_BUILD_TYPE
# -------------------------
#
# When installing OpenCMISS, the opencmiss-config file defines a default MPI build type.
#
# If unspecified, this will always be set to the build type used for the latest build.
#
# .. default:: <empty>
set(OC_DEFAULT_MPI_BUILD_TYPE )

##
# OPENCMISS_USE_ARCHITECTURE_PATH
# -------------------------------
#
# Use architecture path to enable multiple configs in the same installation.
#
# .. default:: YES
option(OPENCMISS_USE_ARCHITECTURE_PATH "Use architecture path to enable multiple configs in the same installation." YES)

##
# OPENCMISS_DEVEL_ALL
# ------------
#
# Override any local variable and have CMake download/checkout the "devel" branch of any components repository
#
# See also: `<COMP>_DEVEL`_
#
# .. default:: NO
option(OPENCMISS_DEVEL_ALL "Download/checkout development branches of all components of the OpenCMISS build." NO)

##
# OPENCMISS_INSTALLATION_SUPPORT_EMAIL
# ------------------------------------
# 
# Please set this to your email address, especially if you plan to provide several architecture installations and
# expect people to use your installation
#
# .. default:: OPENCMISS_BUILD_SUPPORT_EMAIL
set(OPENCMISS_INSTALLATION_SUPPORT_EMAIL ${OPENCMISS_BUILD_SUPPORT_EMAIL} CACHE STRING "Please set this to your email address, especially if you plan to provide several architecture installations and expect people to use your installation")

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
# Moreover, those variables are also defined for all MPI implementations that can be build by the OpenCMISS build environment.
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
set(PTSCOTCH_VERSION 6.0.3)
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
set(OPENMPI_BRANCH v${OPENMPI_VERSION}) # No devel branch at this time
set(MPICH_VERSION 3.1.3)
set(MPICH_BRANCH v${MPICH_VERSION}) # No devel branch at this time
set(MVAPICH2_VERSION 2.1)
set(MVAPICH2_BRANCH v${MVAPICH2_VERSION}) # No devel branch at this time

# Own components
set(CELLML_VERSION 1.0) # any will do, not used
set(CSIM_VERSION 1.0)
set(IRON_VERSION 0.6.0)
set(ZINC_VERSION 3.1)

# DISABLE_GIT
# -----------
#
# Disable use of Git to obtain sources.
# The build systems automatically looks for Git and uses that to clone the respective source repositories
# If Git is not found, a the build system falls back to download :code:`.zip` files of the source.
# To enforce that behaviour (e.g. for nightly tests), set this to :cmake:`YES`.
#
# .. caution::
#
#     If you want to switch from not using Git back to using Git, the update/download targets wont work
#     since the source folders are not empty and are also no Git repositories - the "git clone" command
#     is senseful enough not to simply overwrite possibly existing files. In this case, simply delete the
#     source directory :path:`<OPENCMISS_ROOT>/src` before switching. The next build will automatically
#     clone the Git repositories then.
#
# .. default:: NO
option(DISABLE_GIT "Do not use Git to obtain and manage sources" NO)

