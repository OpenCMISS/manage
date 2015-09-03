# Main components config
# This script sets up all the different components by either looking them up on the system or adding an external project
# to build them ourselves.
#
# The main sections are Utils, Dependencies and Iron.
#
# The main macro is addAndConfigureLocalComponent defined in OCComponentSetupMacros.cmake.
# Its behaviour is controlled (despite the direct argument) by
# SUBGROUP_PATH: Determines a grouping folder to sort components into.
# GITHUB_ORGANIZATION: For the default source locations, we use the OpenCMISS github organizations to group the components sources.
#                      Those are used to both clone the git repo in development mode or generate the path to the zipped source file on github. 

# ================================================================
# Utils 
#  -as long as we dont have more utilities i wont change everything to have that in the "Utilities.cmake" script
#   we probably also dont need the release/debug versions here. we'll see what logic we need to extract from the build macros script
# ================================================================ 

# gTest
if (OCM_USE_GTEST AND BUILD_TESTS)
    SET(GTEST_FWD_DEPS LLVM CSIM)
    set(SUBGROUP_PATH utilities)
    set(GITHUB_ORGANIZATION OpenCMISS-Utilities)
    addAndConfigureLocalComponent(GTEST)
endif()

# ================================================================
# Dependencies
# ================================================================
# Forward/downstream dependencies (for cmake build ordering and dependency checking)
# Its organized this way as not all backward dependencies might be built by the cmake
# system. here, the actual dependency list is filled "as we go" and actually build
# packages locally, see ADD_DOWNSTREAM_DEPS in BuildMacros.cmake

# Affects the addAndConfigureLocalComponent macro
set(SUBGROUP_PATH dependencies)
set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)

# Note: The following order for all packages has to be in their interdependency order,
# i.e. mumps may need scotch so scotch has to be processed first on order to be added to the
# external project dependencies list of any following package

# LAPACK (includes BLAS)
if (OCM_USE_BLAS OR OCM_USE_LAPACK)
    find_package(BLAS ${BLAS_VERSION} QUIET)
    find_package(LAPACK ${LAPACK_VERSION} QUIET)
    if(NOT (LAPACK_FOUND AND BLAS_FOUND))
        SET(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
            SUPERLU SUPERLU_DIST PARMETIS HYPRE SUNDIALS PASTIX PLAPACK PETSC IRON)
        addAndConfigureLocalComponent(LAPACK)
    endif()
endif()

# zLIB
if(OCM_USE_ZLIB)
    find_package(ZLIB ${ZLIB_VERSION} QUIET)
    if(NOT ZLIB_FOUND)
        SET(ZLIB_FWD_DEPS 
            SCOTCH PTSCOTCH 
            MUMPS LIBXML2 HDF5 FIELDML-API
            IRON CSIM LLVM CELLML LIBPNG
            TIFF GDCM)
        addAndConfigureLocalComponent(ZLIB)
    endif()
endif()

# bzip2
if(OCM_USE_BZIP2)
    find_package(BZIP2 ${BZIP2_VERSION} QUIET)
    if(NOT BZIP2_FOUND)
        SET(BZIP2_FWD_DEPS SCOTCH PTSCOTCH GDCM)
        addAndConfigureLocalComponent(BZIP2)
    endif()
endif()

# libxml2
if(OCM_USE_LIBXML2)
    find_package(LibXml2 ${LIBXML2_VERSION} QUIET)
    if(NOT LIBXML2_FOUND)
        SET(LIBXML2_FWD_DEPS CSIM LLVM FIELDML-API CELLML LIBCELLML)
        addAndConfigureLocalComponent(LIBXML2
            WITH_ZLIB=${LIBXML2_WITH_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
        )
    endif()
endif()

# jpeg
if(OCM_USE_JPEG)
    find_package(JPEG ${JPEG_VERSION} QUIET)
    if(NOT JPEG_FOUND)
        set(JPEG_FWD_DEPS ZINC TIFF GDCM)
        addAndConfigureLocalComponent(JPEG
            JPEG_BUILD_CJPEG=OFF
            JPEG_BUILD_DJPEG=OFF
            JPEG_BUILD_JPEGTRAN=OFF
            JPEG_BUILD_RDJPGCOM=OFF
            JPEG_BUILD_WRJPGCOM=OFF
        )
    endif()
endif()

# szip
if(OCM_USE_SZIP)
    find_package(SZIP ${SZIP_VERSION} QUIET)
    if(NOT SZIP_FOUND)
        SET(SZIP_FWD_DEPS HDF5)
        addAndConfigureLocalComponent(SZIP)
    endif()
endif()

# hdf5
if(OCM_USE_HDF5)
    find_package(HDF5 ${HDF5_VERSION} QUIET)
    if(NOT HDF5_FOUND)
        SET(HDF5_FWD_DEPS FIELDML-API)
        addAndConfigureLocalComponent(HDF5
            HDF5_VERSION=${HDF5_VERSION}
            HDF5_WITH_MPI=${HDF5_WITH_MPI}
            WITH_SZIP=${HDF5_WITH_SZIP}
            SZIP_VERSION=${SZIP_VERSION}
            WITH_ZLIB=${HDF5_WITH_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
        )
    endif()
endif()

# fieldml
if(OCM_USE_FIELDML-API)
    find_package(FIELDML-API ${FIELDML-API_VERSION} QUIET)
    if(NOT FIELDML-API_FOUND)
        SET(FIELDML-API_FWD_DEPS ZINC IRON)
        addAndConfigureLocalComponent(FIELDML-API
            LIBXML2_VERSION=${LIBXML2_VERSION}
            USE_HDF5=${FIELDML-API_WITH_HDF5}
            HDF5_VERSION=${HDF5_VERSION}
            HDF5_WITH_MPI=${HDF5_WITH_MPI}
            JAVA_BINDINGS=${FIELDML-API_WITH_JAVA_BINDINGS}
            FORTRAN_BINDINGS=${FIELDML-API_WITH_FORTRAN_BINDINGS}
        )
    endif()
endif()

# Scotch 6.0
if (OCM_USE_PTSCOTCH)
    find_package(PTSCOTCH ${PTSCOTCH_VERSION} QUIET)
    if(NOT PTSCOTCH_FOUND)
        SET(SCOTCH_FWD_DEPS PASTIX PETSC MUMPS IRON)
        addAndConfigureLocalComponent(SCOTCH
            BUILD_PTSCOTCH=YES
            USE_ZLIB=${SCOTCH_WITH_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
            USE_BZ2=${SCOTCH_WITH_BZIP2}
            BZIP2_VERSION=${BZIP2_VERSION}
            USE_THREADS=${SCOTCH_USE_THREADS})
    endif()
elseif(OCM_USE_SCOTCH)
    find_package(SCOTCH ${SCOTCH_VERSION} QUIET)
    if(NOT SCOTCH_FOUND)
        SET(PTSCOTCH_FWD_DEPS PASTIX PETSC MUMPS IRON)
        addAndConfigureLocalComponent(SCOTCH
            BUILD_PTSCOTCH=NO
            USE_ZLIB=${SCOTCH_WITH_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
            USE_BZ2=${SCOTCH_WITH_BZIP2}
            BZIP2_VERSION=${BZIP2_VERSION}
            USE_THREADS=${SCOTCH_USE_THREADS})
    endif()
endif()

# PLAPACK
if(OCM_USE_PLAPACK)
    find_package(PLAPACK ${PLAPACK_VERSION} QUIET)
    if(NOT PLAPACK_FOUND)
        SET(PLAPACK_FWD_DEPS IRON)
        addAndConfigureLocalComponent(PLAPACK
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# ScaLAPACK
if(OCM_USE_SCALAPACK)
    find_package(SCALAPACK ${SCALAPACK_VERSION} QUIET)
    if(NOT SCALAPACK_FOUND)
        SET(SCALAPACK_FWD_DEPS MUMPS PETSC IRON)
        addAndConfigureLocalComponent(SCALAPACK
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# parMETIS 4 (+METIS 5)
if(OCM_USE_PARMETIS)
    find_package(PARMETIS ${PARMETIS_VERSION} QUIET)
    if(NOT PARMETIS_FOUND)
        SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST PASTIX IRON)
        addAndConfigureLocalComponent(PARMETIS)
    endif()
endif()

# MUMPS
if (OCM_USE_MUMPS)
    find_package(MUMPS ${MUMPS_VERSION} QUIET)
    if(NOT MUMPS_FOUND)
        SET(MUMPS_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(MUMPS
            USE_SCOTCH=${MUMPS_WITH_SCOTCH}
            USE_PTSCOTCH=${MUMPS_WITH_PTSCOTCH}
            USE_PARMETIS=${MUMPS_WITH_PARMETIS}
            USE_METIS=${MUMPS_WITH_METIS}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            METIS_VERSION=${METIS_VERSION}
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
        )
    endif()
endif()

# SUITESPARSE [CHOLMOD / UMFPACK]
if (OCM_USE_SUITESPARSE)
    find_package(SUITESPARSE ${SUITESPARSE_VERSION} QUIET)
    if(NOT SUITESPARSE_FOUND)
        SET(SUITESPARSE_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(SUITESPARSE
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION}
            METIS_VERSION=${METIS_VERSION})
    endif()
endif()

# SuperLU 4.3
if (OCM_USE_SUPERLU)
    find_package(SUPERLU ${SUPERLU_VERSION} QUIET)
    if(NOT SUPERLU_FOUND)
        SET(SUPERLU_FWD_DEPS PETSC IRON HYPRE)
        addAndConfigureLocalComponent(SUPERLU
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# Hypre 2.9.0b
if (OCM_USE_HYPRE)
    find_package(HYPRE ${HYPRE_VERSION} QUIET)
    if(NOT HYPRE_FOUND)
        SET(HYPRE_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(HYPRE
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# SuperLU-DIST 4.0
if (OCM_USE_SUPERLU_DIST)
    find_package(SUPERLU_DIST ${SUPERLU_DIST_VERSION} QUIET)
    if(NOT SUPERLU_DIST_FOUND)
        SET(SUPERLU_DIST_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(SUPERLU_DIST
            BLAS_VERSION=${BLAS_VERSION}
            USE_PARMETIS=${SUPERLU_DIST_WITH_PARMETIS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            USE_METIS=${SUPERLU_DIST_WITH_METIS}
            METIS_VERSION=${METIS_VERSION}
        )
    endif()
endif()

# Sundials 2.5
if (OCM_USE_SUNDIALS)
    find_package(SUNDIALS ${SUNDIALS_VERSION} QUIET)
    if(NOT SUNDIALS_FOUND)
        SET(SUNDIALS_FWD_DEPS CSIM PETSC IRON)
        addAndConfigureLocalComponent(SUNDIALS
            USE_LAPACK=${SUNDIALS_WITH_LAPACK}
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# Pastix 5.2.2.16
if (OCM_USE_PASTIX)
    find_package(PASTIX ${PASTIX_VERSION} QUIET)
    if(NOT PASTIX_FOUND)
        SET(PASTIX_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(PASTIX
            BLAS_VERSION=${BLAS_VERSION}
            USE_THREADS=${PASTIX_USE_THREADS}
            USE_METIS=${PASTIX_USE_METIS}
            USE_PTSCOTCH=${PASTIX_USE_PTSCOTCH}
        )
    endif()
endif()

# Sowing (only for PETSC ftn-auto generation)
if (OCM_USE_SOWING)
    find_package(SOWING ${SOWING_VERSION} QUIET)
    if(NOT SOWING_FOUND)
        SET(SOWING_FWD_DEPS PETSC)
        addAndConfigureLocalComponent(SOWING)
    endif()
endif()

# PETSc 3.5
if (OCM_USE_PETSC)
    find_package(PETSC ${PETSC_VERSION} QUIET)
    if(NOT PETSC_FOUND)
        SET(PETSC_FWD_DEPS SLEPC IRON)
        addAndConfigureLocalComponent(PETSC
            HYPRE_VERSION=${HYPRE_VERSION}
            MUMPS_VERSION=${MUMPS_VERSION}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            PASTIX_VERSION=${PASTIX_VERSION}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION}
        )
    endif()
endif()

# SLEPc 3.5
if (OCM_USE_SLEPC)
    find_package(SLEPC ${SLEPC_VERSION} QUIET)
    if(NOT SLEPC_FOUND)
        SET(SLEPC_FWD_DEPS IRON)
        addAndConfigureLocalComponent(SLEPC
            HYPRE_VERSION=${HYPRE_VERSION}
            MUMPS_VERSION=${MUMPS_VERSION}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            PASTIX_VERSION=${PASTIX_VERSION}
            PETSC_VERSION=${PETSC_VERSION}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION})
    endif()
endif()

# CellML
if (OCM_USE_LIBCELLML)
    find_package(LIBCELLML ${LIBCELLML_VERSION} QUIET)
    if (NOT LIBCELLML_FOUND)
        SET(LIBCELLML_FWD_DEPS CSIM CELLML IRON)
        addAndConfigureLocalComponent(LIBCELLML)
    endif()
endif()

if (OCM_USE_CELLML)
    find_package(CELLML ${CELLML_VERSION} QUIET)
    if (NOT CELLML_FOUND)
        # For now cellml is in OpenCMISS organization on GitHub
        set(GITHUB_ORGANIZATION OpenCMISS)
        SET(CELLML_FWD_DEPS IRON)
        addAndConfigureLocalComponent(CELLML
            LIBXML2_VERSION=${LIBXML2_VERSION})
        # Set back
        set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)
    endif()
endif()

if (OCM_USE_LLVM)
    find_package(LLVM ${LLVM_VERSION} QUIET)
    if (NOT LLVM_FOUND)
        SET(LLVM_FWD_DEPS CSIM)
        addAndConfigureLocalComponent(LLVM)
    endif()
endif()
if (OCM_USE_CSIM)
    find_package(CSIM ${CSIM_VERSION} QUIET)
    if (NOT CSIM_FOUND)
        SET(CSIM_FWD_DEPS IRON)
        addAndConfigureLocalComponent(CSIM)
    endif()
endif()

# ================================================================
# Iron
# ================================================================
if (OCM_USE_IRON)
    set(SUBGROUP_PATH .)
    set(GITHUB_ORGANIZATION OpenCMISS)
    addAndConfigureLocalComponent(IRON
        WITH_CELLML=${IRON_WITH_CELLML}
        CELLML_VERSION=${CELLML_VERSION}
        WITH_FIELDML=${IRON_WITH_FIELDML}
        FIELDML-API_VERSION=${FIELDML-API_VERSION} 
        WITH_HYPRE=${IRON_WITH_HYPRE}
        HYPRE_VERSION=${HYPRE_VERSION}
        WITH_SUNDIALS=${IRON_WITH_SUNDIALS}
        SUNDIALS_VERSION=${SUNDIALS_VERSION}
        WITH_MUMPS=${IRON_WITH_MUMPS}
        MUMPS_VERSION=${MUMPS_VERSION}
        WITH_SCALAPACK=${IRON_WITH_SCALAPACK}
        SCALAPACK_VERSION=${SCALAPACK_VERSION}
        WITH_PETSC=${IRON_WITH_PETSC}
        PETSC_VERSION=${PETSC_VERSION}
        WITH_PROFILING=${OCM_WITH_PROFILING}
    )
endif()

if (OCM_USE_ZINC)
set(SUBGROUP_PATH dependencies)
set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)

# netgen
find_package(NETGEN ${NETGEN_VERSION} QUIET)
if (NOT NETGEN_FOUND)
set(NETGEN_FWD_DEPS ZINC)
addAndConfigureLocalComponent(NETGEN
NETGEN_BUILD_TYPE=${CMAKE_BUILD_TYPE}
NETGEN_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
)
endif()

# Freetype
find_package(Freetype ${FREETYPE_VERSION} QUIET)
if (NOT FREETYPE_FOUND)
set(FREETYPE_FWD_DEPS FTGL)
addAndConfigureLocalComponent(FREETYPE
)
endif()

# FTGL
find_package(FTGL ${FTGL_VERSION} QUIET)
if (NOT FTGL_FOUND)
set(FTGL_FWD_DEPS ZINC)
addAndConfigureLocalComponent(FTGL
FTGL_BUILD_TYPE=${CMAKE_BUILD_TYPE}
FTGL_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
)
endif()

# GLEW
find_package(GLEW ${GLEW_VERSION} QUIET)
if (NOT GLEW_FOUND)
set(GLEW_FWD_DEPS ZINC)
addAndConfigureLocalComponent(GLEW
GLEW_BUILD_TYPE=${CMAKE_BUILD_TYPE}
GLEW_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
)
endif()

# opt++
find_package(OPTPP ${OPTPP_VERSION} QUIET)
if (NOT OPTPP_FOUND)
addAndConfigureLocalComponent(OPTPP
)
endif()

# libpng
find_package(LIBPNG ${LIBPNG_VERSION} QUIET)
if (NOT LIBPNG_FOUND)
set(LIBPNG_FWD_DEPS ZINC ITK IMAGEMAGICK)
addAndConfigureLocalComponent(LIBPNG
PNG_NO_CONSOLE_IO=OFF
PNG_NO_STDIO=OFF
)
endif()

# tiff
find_package(TIFF ${TIFF_VERSION} QUIET)
if (NOT TIFF_FOUND)
set(TIFF_FWD_DEPS ZINC ITK IMAGEMAGICK)
addAndConfigureLocalComponent(TIFF
TIFF_BUILD_TOOLS=OFF
)
endif()

# gdcm
find_package(GDCM ${GDCM_VERSION} QUIET)
if (NOT GDCM_FOUND)
set(GDCM_FWD_DEPS ZINC ITK IMAGEMAGICK)
# Check why the -D part of the argument is 
# not required for GDCM.
# Make EXPAT and UUID platform dependent?
addAndConfigureLocalComponent(GDCM
GDCM_USE_SYSTEM_ZLIB=ON
GDCM_USE_SYSTEM_EXPAT=ON
GDCM_USE_SYSTEM_UUID=ON
)
endif()

    string(REPLACE ";" ${OCM_LIST_SEPARATOR} CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")
    set(SUBGROUP_PATH .)
    set(GITHUB_ORGANIZATION OpenCMISS)
    addAndConfigureLocalComponent(ZINC
    ZINC_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
    ZINC_DEPENDENCIES_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    )
endif()
# Notes:
# lapack: not sure if LAPACKE is build/required
# plapack: have only MACHINE_TYPE=500 and MANUFACTURE=50 (linux)
# plapack: some tests are not compiling
# parmetis/metis: test programs not available (but for gklib, and they are also rudimental), linking executables instead to have a 50% "its working" test
# mumps - not setup for libseq / sequential version
# mumps - only have double precision arithmetics
# mumps - no PORD is compiled (will have parmetis/scotch available)
# mumps - hardcoded Add_ compiler flag for c/fortran interfacing.. dunno if that is the best idea
# metis: have fixed IDXTYPEWIDTH 32
# cholmod: could go with CUDA BLAS version (indicated by makefile)
# umfpack: building only "int" version right now (Suitesparse_long impl for AMD,CAMD etc but not umfpack)


# TODO
# cholmod - use CUDA stuff
