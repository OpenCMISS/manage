# ==============================
# Build configuration
# ==============================
# See your OpenCMISSLocalConfig file for details on the possible options and values.
set(OPENCMISS_INSTALL_ROOT "${OPENCMISS_ROOT}/install")
set(BUILD_PRECISION sd CACHE STRING "Build precisions for OpenCMISS components. Choose any of [sdcz]")
set(INT_TYPE int32 CACHE STRING "OpenCMISS integer type (only used by PASTIX yet)")
set(CMAKE_DEBUG_POSTFIX d CACHE STRING "Debug postfix for library names of DEBUG-builds") # Debug postfix

option(BUILD_TESTS "Build OpenCMISS(-components) tests" ON)
option(PARALLEL_BUILDS "Use multithreading (-jN etc) for builds" ON)
option(BUILD_SHARED_LIBS "Build shared libraries within/for every component" NO)
option(OC_CREATE_LOGS "Create logfiles instead of direct output to screen" YES)
option(OC_WARN_ALL "Compiler flags choices - all warnings on" YES)
option(OC_CHECK_ALL "Compiler flags choices - all checks on" YES)
option(OC_MULTITHREADING "Use multithreading in OpenCMISS (where applicable)" NO)
option(CMAKE_VERBOSE_MAKEFILE "Generate verbose makefiles/projects for builds" NO)
option(OC_USE_ARCHITECTURE_PATH "Use an architecture path for build and install trees" YES)
option(GITHUB_USE_SSL "Use SSL connection to (default) GitHub repositories" NO)
option(OC_DEPENDENCIES_ONLY "Build dependencies only (no Iron or Zinc)" NO)
option(OC_CONFIG_LOG_TO_SCREEN "Also print the created log file entries to console output" NO)

# Those "options" have non-boolean values and its not clear yet what is better to use.. just leave it as that
# for the time being
set(OC_COMPONENTS_SYSTEM DEFAULT)
set(OC_EP_PREFIX "OC_") # The prefix for opencmiss dependencies external projects
# The default implementation to use in all last-resort/unimplemented cases
set(OPENCMISS_MPI_DEFAULT mpich)
set(OC_CONFIG_LOG_LEVELS SCREEN WARNING ERROR) #VERBOSE DEBUG

foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    set(_VALUE ON)
    if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT)
        set(_VALUE OFF)
    endif()
    # Use everything but the components in OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT
    option(OC_USE_${COMPONENT} "Enable use/build of ${COMPONENT}" ${_VALUE})
    
    # Look for some components on the system first before building
    set(_VALUE OFF)
    if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT)
        set(_VALUE ON)
    endif()
    option(OC_SYSTEM_${COMPONENT} "Allow ${COMPONENT} to be used from local environment/system" ${_VALUE})
    # Initialize the default: static build for all components
    option(${COMPONENT}_SHARED "Build all libraries of ${COMPONENT} as shared" NO)
endforeach()

# Component versions
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
set(LLVM_VERSION 3.4)
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
set(GDCM_VERSION 2.0.12)
set(IMAGEMAGICK_VERSION 6.7.0.8)
set(ITK_VERSION 3.20.0)

# MPI
set(OPENMPI_VERSION 1.8.4) #1.8.4, 1.10.0 (unstable, does fail on e.g. ASES/Stuttgart)
set(MPICH_VERSION 3.1.3)
set(MVAPICH2_VERSION 2.1)
# Cellml
set(CELLML_VERSION 1.0) # any will do, not used
set(CSIM_VERSION 1.0)

set(IRON_VERSION 0.5.0)
set(IRON_SHARED YES)

set(ZINC_VERSION 3.0.2)
set(ZINC_SHARED YES)

set(EXAMPLES_VERSION 1.0)

# ==========================================================================================
# Single module configuration
#
# These flags only apply if the corresponding package is build
# by the OpenCMISS Dependencies system. The packages themselves will then search for the
# appropriate consumed packages. No checks are performed on whether the consumed packages
# will also be build by us or not, as they might be provided externally.
#
# To be safe: E.g. if you wanted to use MUMPS with SCOTCH, also set OC_USE_SCOTCH=YES so that
# the build system ensures that SCOTCH will be available.
# ==========================================================================================
option(MUMPS_WITH_SCOTCH "Have MUMPS use Scotch" NO)
option(MUMPS_WITH_PTSCOTCH "Have MUMPS use PT-Scotch" YES)
option(MUMPS_WITH_METIS "Have MUMPS use Metis" NO)
option(MUMPS_WITH_PARMETIS "Have MUMPS use Parmetis" YES)

option(SUNDIALS_WITH_LAPACK "Have Sundials use LAPACK" YES)

option(SCOTCH_USE_THREADS "Enable use of threading for Scotch/PT-Scotch" YES)
option(SCOTCH_WITH_ZLIB "Have Scotch/PT-Scotch use zlib" YES)
option(SCOTCH_WITH_BZIP2 "Have Scotch/PT-Scotch use bzip2" YES)

option(SUPERLU_DIST_WITH_PARMETIS "Enable Parmetis support for SuperLU-Dist" YES)

option(PASTIX_USE_THREADS "Enable use of threading for PASTIX" YES)
option(PASTIX_USE_METIS "Have PASTIX use Metis" YES)
option(PASTIX_USE_PTSCOTCH "Have PASTIX use PT-Scotch" YES)

option(HDF5_WITH_MPI "Build HDF5 with MPI support" NO)
option(HDF5_WITH_SZIP "Have HDF5 use szip" YES)
option(HDF5_WITH_ZLIB "Have HDF5 use zlib" YES)

option(FIELDML-API_WITH_HDF5 "Enable FieldML HDF5 support" NO)
option(FIELDML-API_WITH_JAVA_BINDINGS "Build Java bindings for FieldML" NO)
option(FIELDML-API_WITH_FORTRAN_BINDINGS "Build Fortran bindings for FieldML" YES)

option(IRON_WITH_CELLML "Have Iron use CellML" YES)
option(IRON_WITH_FIELDML "Have Iron use FieldML" YES)
option(IRON_WITH_HYPRE "Have Iron use Hypre" YES)
option(IRON_WITH_SUNDIALS "Have Iron use Sundials" YES)
option(IRON_WITH_MUMPS "Have Iron use MUMPS" YES)
option(IRON_WITH_SCALAPACK "Have Iron use ScaLAPACK" YES)
option(IRON_WITH_PETSC "Have Iron use PetSC" YES)
option(IRON_WITH_C_BINDINGS "Build Iron-C bindings" YES)
# IRON_WITH_Python_BINDINGS is automatically set if python is found

option(LIBXML2_WITH_ZLIB "Have Iron use CellML"  YES)
