# Main components config
# This script sets up all the different components by either looking them up on the system or adding an external project
# to build them ourselves.
#
# The main sections are Utils, Dependencies and Iron.
#
# The main macro is addAndConfigureLocalComponent defined in OCComponentSetupMacros.cmake.
# Its behaviour is controlled (despite the direct argument) by
# SUBGROUP_PATH: Determines a grouping folder to sort components into.

# ================================================================
# Utils 
#  -as long as we dont have more utilities I wont change everything to have that in the "Utilities.cmake" script
#   we probably also dont need the release/debug versions here. we'll see what logic we need to extract from the build macros script
# ================================================================ 

# BLAS vendor
# If set, propagate it to any component so that the correct libraries are used.
if (BLA_VENDOR)
    set(BLA_VENDOR_CONFIG BLA_VENDOR=${BLA_VENDOR})
endif()

# gTest
# if (OC_USE_GTEST AND (BUILD_TESTS OR OC_BUILD_ZINC_TESTS))
if (GTEST IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT GTEST_FOUND)
        set(GTEST_FWD_DEPS LLVM CSIM ZINC)
        set(SUBGROUP_PATH utilities)
        addAndConfigureLocalComponent(GTEST
            BUILD_TESTS=OFF
            gtest_force_shared_crt=YES
        )
    endif ()
endif ()

# ================================================================
# Dependencies
# ================================================================
# Forward/downstream dependencies (for cmake build ordering and dependency checking)
# Its organized this way as not all backward dependencies might be built by the cmake
# system. here, the actual dependency list is filled "as we go" and actually build
# packages locally, see ADD_DOWNSTREAM_DEPS in BuildMacros.cmake

# Affects the addAndConfigureLocalComponent macro
set(SUBGROUP_PATH dependencies)

# Note: The following order for all packages has to be in their interdependency order,
# i.e. mumps may need scotch so scotch has to be processed first on order to be added to the
# external project dependencies list of any following package

# zLIB
# if (OC_USE_ZLIB OR OC_USE_ZINC OR OPENCMISS_DEPENDENCIES_ONLY)
if (ZLIB IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT ZLIB_FOUND)
        set(ZLIB_FWD_DEPS 
            SCOTCH LIBXML2 HDF5
            IRON CSIM LLVM PNG IMAGEMAGICK ITK
            TIFF GDCM-ABI FREETYPE ZINC)
        addAndConfigureLocalComponent(ZLIB)
    endif ()
endif ()

# libxml2
if (LIBXML2 IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT LIBXML2_FOUND)
        set(LIBXML2_FWD_DEPS CSIM LLVM FIELDML-API CELLML LIBCELLML ITK)
        foreach(dependency ZLIB)
            if (LIBXML2_WITH_${dependency} AND OC_USE_${dependency})
                set(LIBXML2_USE_${dependency} ON)
            else ()
                set(LIBXML2_USE_${dependency} OFF)
            endif ()
        endforeach()
        addAndConfigureLocalComponent(LIBXML2
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            WITH_ZLIB=${LIBXML2_USE_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
        )
    endif ()
endif ()

# LAPACK (includes BLAS)
# Thus far only Iron really makes heavy use of BLAS/LAPACK, opt++ from zinc
# dependencies is the only other dependency that can make use of (external) BLAS/LAPACK.
# if ((OC_USE_BLAS OR OC_USE_LAPACK) AND (OPENCMISS_DEPENDENCIES_ONLY OR OC_USE_IRON OR (OC_USE_OPTPP AND OPTPP_WITH_BLAS)))
if (LAPACK IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT (LAPACK_FOUND AND BLAS_FOUND))
        set(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
            SUPERLU SUPERLU_DIST PARMETIS HYPRE SUNDIALS PASTIX PLAPACK PETSC IRON)
        addAndConfigureLocalComponent(LAPACK)
    endif ()
endif ()

# bzip2
if (BZIP2 IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT BZIP2_FOUND)
        set(BZIP2_FWD_DEPS SCOTCH GDCM-ABI IMAGEMAGICK FREETYPE ZINC)
        addAndConfigureLocalComponent(BZIP2)
    endif ()
endif ()

# hdf5
if (HDF5 IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    # szip
    if (SZIP IN_LIST OC_BUILD_LOCAL_COMPONENTS)
        if (NOT SZIP_FOUND)
            set(SZIP_FWD_DEPS HDF5)
            addAndConfigureLocalComponent(SZIP)
        endif ()
    endif ()

    if (NOT HDF5_FOUND)
        set(HDF5_FWD_DEPS FIELDML-API ITK)
        foreach(dependency MPI;SZIP;ZLIB)
            if (HDF5_WITH_${dependency} AND OC_USE_${dependency})
                set(HDF5_USE_${dependency} ON)
            else ()
                set(HDF5_USE_${dependency} OFF)
            endif ()
        endforeach()

        addAndConfigureLocalComponent(HDF5
            BUILD_TESTS=OFF
            HDF5_WITH_MPI=${HDF5_USE_MPI}
            WITH_SZIP=${HDF5_USE_SZIP}
            SZIP_FIND_SYSTEM=${SZIP_FIND_SYSTEM}
            SZIP_VERSION=${SZIP_VERSION}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            WITH_ZLIB=${HDF5_USE_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
            HDF5_BUILD_FORTRAN=${HDF5_BUILD_FORTRAN}
            HDF5_BUILD_EXAMPLES=OFF
        )
    endif ()
endif ()
if (HDF5_WITH_MPI AND OC_USE_MPI)
    set(HDF5_USE_MPI ON)
else ()
    set(HDF5_USE_MPI OFF)
endif ()

# Fieldml
if (FIELDML-API IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT FIELDML-API_FOUND)
        set(FIELDML-API_FWD_DEPS ZINC IRON)
        if (FIELDML-API_WITH_HDF5 AND OC_USE_HDF5)
            set(FIELDML-API_USE_HDF5 ON)
        else ()
            set(FIELDML-API_USE_HDF5 OFF)
        endif ()
        addAndConfigureLocalComponent(FIELDML-API
            BUILD_TESTS=${BUILD_TESTS}
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
            USE_HDF5=${FIELDML-API_USE_HDF5}
            HDF5_FIND_SYSTEM=${HDF5_FIND_SYSTEM}
            HDF5_VERSION=${HDF5_VERSION}
            HDF5_WITH_MPI=${HDF5_USE_MPI}
            JAVA_BINDINGS=${FIELDML-API_WITH_JAVA_BINDINGS}
            FORTRAN_BINDINGS=${FIELDML-API_WITH_FORTRAN_BINDINGS}
        )
    endif ()
endif ()

if (SCOTCH IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SCOTCH_FOUND)
        set(SCOTCH_FWD_DEPS PASTIX PETSC MUMPS IRON)
        foreach(dependency BZIP2;ZLIB)
            if (SCOTCH_WITH_${dependency} AND OC_USE_${dependency})
                set(SCOTCH_USE_${dependency} ON)
            else ()
                set(SCOTCH_USE_${dependency} OFF)
            endif ()
        endforeach()

        if (MUMPS_WITH_PTSCOTCH OR PASTIX_WITH_PTSCOTCH OR PETSC_WITH_PTSCOTCH)
            set(BUILD_PTSCOTCH YES)
        else ()
            set(BUILD_PTSCOTCH NO)
        endif ()

        addAndConfigureLocalComponent(SCOTCH
            BUILD_TESTS=${BUILD_TESTS}
            BUILD_PTSCOTCH=${BUILD_PTSCOTCH}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            USE_ZLIB=${SCOTCH_USE_ZLIB}
            ZLIB_VERSION=${ZLIB_VERSION}
            USE_BZ2=${SCOTCH_USE_BZIP2}
            BZIP2_FIND_SYSTEM=${BZIP2_FIND_SYSTEM}
            BZIP2_VERSION=${BZIP2_VERSION}
            USE_THREADS=${SCOTCH_USE_THREADS}
        )
    endif ()
endif ()

# PLAPACK
if (PLAPACK IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT PLAPACK_FOUND)
        set(PLAPACK_FWD_DEPS IRON)
        addAndConfigureLocalComponent(PLAPACK
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
        )
    endif ()
endif ()

# ScaLAPACK
if (SCALAPACK IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SCALAPACK_FOUND)
        set(SCALAPACK_FWD_DEPS MUMPS PETSC IRON)
        addAndConfigureLocalComponent(SCALAPACK
            BUILD_TESTS=${BUILD_TESTS}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
            BUILD_PRECISION=${BUILD_PRECISIONS}
        )
    endif ()
endif ()

# parMETIS 4 (+METIS 5)
if (PARMETIS IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT PARMETIS_FOUND)
        SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST PASTIX IRON)
        addAndConfigureLocalComponent(PARMETIS
            BUILD_TESTS=${BUILD_TESTS}
        )
    endif ()
endif ()

# MUMPS
if (MUMPS IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT MUMPS_FOUND)
        set(MUMPS_FWD_DEPS PETSC IRON)
        foreach(dependency METIS;PARMETIS;SCOTCH)
            if (MUMPS_WITH_${dependency} AND OC_USE_${dependency})
                set(MUMPS_USE_${dependency} ON)
            else ()
                set(MUMPS_USE_${dependency} OFF)
            endif ()
        endforeach()
        if (BUILD_PTSCOTCH) # Is this enough do we need to check if PTSCOTCH is available some other way?
            set(MUMPS_USE_PTSCOTCH ${MUMPS_USE_SCOTCH})
        endif ()

        addAndConfigureLocalComponent(MUMPS
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            USE_SCOTCH=${MUMPS_USE_SCOTCH}
            USE_PTSCOTCH=${MUMPS_USE_PTSCOTCH}
            SCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            USE_PARMETIS=${MUMPS_USE_PARMETIS}
            USE_METIS=${MUMPS_USE_METIS}
            PARMETIS_FIND_SYSTEM=${PARMETIS_FIND_SYSTEM}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            METIS_FIND_SYSTEM=${METIS_FIND_SYSTEM}
            METIS_VERSION=${METIS_VERSION}
            BUILD_PRECISION=${BUILD_PRECISIONS}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
            SCALAPACK_FIND_SYSTEM=${SCALAPACK_FIND_SYSTEM}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
        )
    endif ()
endif ()

# SUITESPARSE [CHOLMOD / UMFPACK]
if (SUITESPARSE IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SUITESPARSE_FOUND)
        set(SUITESPARSE_FWD_DEPS PETSC IRON)
        addAndConfigureLocalComponent(SUITESPARSE
            BUILD_PRECISION=${BUILD_PRECISIONS}
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
            METIS_FIND_SYSTEM=${METIS_FIND_SYSTEM}
            METIS_VERSION=${METIS_VERSION}
        )
    endif ()
endif ()

# SuperLU 4.3
if (SUPERLU IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SUPERLU_FOUND)
        SET(SUPERLU_FWD_DEPS PETSC IRON HYPRE)
        addAndConfigureLocalComponent(SUPERLU
            BUILD_PRECISION=${BUILD_PRECISIONS}
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
        )
    endif ()
endif ()

# Hypre 2.9.0b
if (HYPRE IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT HYPRE_FOUND)
        set(HYPRE_FWD_DEPS PETSC IRON)
        if (HYPRE_WITH_SUPERLU AND OC_USE_SUPERLU)
            set(HYPRE_USE_SUPERLU ON)
        else ()
            set(HYPRE_USE_SUPERLU OFF)
        endif ()
        addAndConfigureLocalComponent(HYPRE
            BUILD_TESTS=${BUILD_TESTS}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
            USE_SUPERLU=${HYPRE_USE_SUPERLU}
            SUPERLU_FIND_SYSTEM=${SUPERLU_FIND_SYSTEM}
            SUPERLU_VERSION=${SUPERLU_VERSION}
        )
    endif ()
endif ()

# SuperLU-DIST 4.0
if (SUPERLU_DIST IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SUPERLU_DIST_FOUND)
        set(SUPERLU_DIST_FWD_DEPS PETSC IRON)
        foreach(dependency METIS;PARMETIS)
            if (SUPERLU_DIST_WITH_${dependency} AND OC_USE_${dependency})
                set(SUPERLU_DIST_USE_${dependency} ON)
            else ()
                set(SUPERLU_DIST_USE_${dependency} OFF)
            endif ()
        endforeach()

        addAndConfigureLocalComponent(SUPERLU_DIST
            BUILD_PRECISION=${BUILD_PRECISIONS}
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            USE_PARMETIS=${SUPERLU_DIST_USE_PARMETIS}
            PARMETIS_FIND_SYSTEM=${PARMETIS_FIND_SYSTEM}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            USE_METIS=${SUPERLU_DIST_USE_METIS}
            METIS_FIND_SYSTEM=${METIS_FIND_SYSTEM}
            METIS_VERSION=${METIS_VERSION}
        )
    endif ()
endif ()

# Sundials 2.5
if (SUNDIALS IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SUNDIALS_FOUND)
        set(SUNDIALS_FWD_DEPS CSIM PETSC IRON)
        foreach(dependency LAPACK)
            if (SUNDIALS_WITH_${dependency} AND OC_USE_${dependency})
                set(SUNDIALS_USE_${dependency} ON)
            else ()
                set(SUNDIALS_USE_${dependency} OFF)
            endif ()
        endforeach()

        addAndConfigureLocalComponent(SUNDIALS
            BUILD_PRECISION=${BUILD_PRECISIONS}
            BUILD_TESTS=${BUILD_TESTS}
            ${BLA_VENDOR_CONFIG}
            USE_MPI=${OC_USE_MPI}
            USE_LAPACK=${SUNDIALS_USE_LAPACK}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
        )
    endif ()
endif ()

# Pastix 5.2.2.16
if (PASTIX IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT PASTIX_FOUND)
        set(PASTIX_FWD_DEPS PETSC IRON)
        foreach(dependency PARMETIS)
            message(STATUS "PASTIX_WITH_${dependency}: ${PASTIX_WITH_${dependency}}, OC_USE_${dependency}: ${OC_USE_${dependency}}")
            if (PASTIX_WITH_${dependency} AND OC_USE_${dependency})
                set(PASTIX_USE_${dependency} ON)
            else ()
                set(PASTIX_USE_${dependency} OFF)
            endif ()
        endforeach()
        if (PASTIX_WITH_PTSCOTCH AND OC_USE_SCOTCH) # Is this enough do we need to check if PTSCOTCH is available some other way?
            set(PASTIX_USE_PTSCOTCH ON)
        else ()
            set(PASTIX_USE_PTSCOTCH OFF)
        endif ()

        addAndConfigureLocalComponent(PASTIX
            BUILD_PRECISION=${BUILD_PRECISIONS}
            BUILD_TESTS=${BUILD_TESTS}
            INT_TYPE=${INT_TYPE}
            USE_THREADS=${PASTIX_USE_THREADS}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            USE_PARMETIS=${PASTIX_USE_PARMETIS}
            METIS_FIND_SYSTEM=${METIS_FIND_SYSTEM}
            METIS_VERSION=${METIS_VERSION}
            USE_PTSCOTCH=${PASTIX_USE_PTSCOTCH}
            PTSCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_VERSION=${SCOTCH_VERSION}
        )
    endif ()
endif ()

# Sowing (only for PETSC ftn-auto generation)
if (SOWING IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SOWING_FOUND)
        SET(SOWING_FWD_DEPS PETSC)
        addAndConfigureLocalComponent(SOWING)
    endif ()
endif ()

# PETSc 3.5
if (PETSC IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT PETSC_FOUND)
        set(PETSC_FWD_DEPS SLEPC IRON)
        foreach(dependency HYPRE;MUMPS;PARMETIS;PASTIX;SCOTCH;SCALAPACK;SUITESPARSE;SUPERLU;SUPERLU_DIST;SUNDIALS)
            if(PETSC_WITH_${dependency} AND OC_USE_${dependency})
                set(PETSC_USE_${dependency} ON)
            else()
                set(PETSC_USE_${dependency} OFF)
            endif()
        endforeach()
        set(PETSC_USE_PTSCOTCH ${PETSC_WITH_PTSCOTCH})

        addAndConfigureLocalComponent(PETSC
            BUILD_TESTS=${BUILD_TESTS}
            FORTRAN_MANGLING=${FORTRAN_MANGLING}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            USE_PASTIX=${PETSC_USE_PASTIX}
            PASTIX_FIND_SYSTEM=${PASTIX_FIND_SYSTEM}
            PASTIX_VERSION=${PASTIX_VERSION}
            USE_MUMPS=${PETSC_USE_MUMPS}
            MUMPS_FIND_SYSTEM=${MUMPS_FIND_SYSTEM}
            MUMPS_VERSION=${MUMPS_VERSION}
            USE_SUITESPARSE=${PETSC_USE_SUITESPARSE}
            SUITESPARSE_FIND_SYSTEM=${SUITESPARSE_FIND_SYSTEM}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            USE_SCALAPACK=${PETSC_USE_SCALAPACK}
            SCALAPACK_FIND_SYSTEM=${SCALAPACK_FIND_SYSTEM}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            USE_PTSCOTCH=${PETSC_USE_PTSCOTCH}
            PTSCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            USE_SUPERLU=${PETSC_USE_SUPERLU}
            SUPERLU_FIND_SYSTEM=${SUPERLU_FIND_SYSTEM}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            USE_SUNDIALS=${PETSC_USE_SUNDIALS}
            SUNDIALS_FIND_SYSTEM=${SUNDIALS_FIND_SYSTEM}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            USE_HYPRE=${PETSC_USE_HYPRE}
            HYPRE_FIND_SYSTEM=${HYPRE_FIND_SYSTEM}
            HYPRE_VERSION=${HYPRE_VERSION}
            USE_SUPERLU_DIST=${PETSC_USE_SUPERLU_DIST}
            SUPERLU_DIST_FIND_SYSTEM=${SUPERLU_DIST_FIND_SYSTEM}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION}
            USE_PARMETIS=${PETSC_USE_PARMETIS}
            PARMETIS_FIND_SYSTEM=${PARMETIS_FIND_SYSTEM}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
        )
    endif ()
endif ()

# SLEPc 3.5
if (SLEPC IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT SLEPC_FOUND)
        set(SLEPC_FWD_DEPS IRON)
        foreach(dependency HYPRE;MUMPS;PARMETIS;PASTIX;SCOTCH;SCALAPACK;SUITESPARSE;SUPERLU;SUPERLU_DIST;SUNDIALS)
            if(PETSC_WITH_${dependency} AND OC_USE_${dependency})
                set(PETSC_USE_${dependency} ON)
            else()
                set(PETSC_USE_${dependency} OFF)
            endif()
        endforeach()
        set(PETSC_USE_PTSCOTCH ${PETSC_WITH_PTSCOTCH})

        addAndConfigureLocalComponent(SLEPC
            BUILD_TESTS=${BUILD_TESTS}
            USE_PASTIX=${PETSC_USE_PASTIX}
            PASTIX_FIND_SYSTEM=${PASTIX_FIND_SYSTEM}
            PASTIX_VERSION=${PASTIX_VERSION}
            USE_MUMPS=${PETSC_USE_MUMPS}
            MUMPS_FIND_SYSTEM=${MUMPS_FIND_SYSTEM}
            MUMPS_VERSION=${MUMPS_VERSION}
            USE_SUITESPARSE=${PETSC_USE_SUITESPARSE}
            SUITESPARSE_FIND_SYSTEM=${SUITESPARSE_FIND_SYSTEM}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            USE_SCALAPACK=${PETSC_USE_SCALAPACK}
            SCALAPACK_FIND_SYSTEM=${SCALAPACK_FIND_SYSTEM}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            USE_PTSCOTCH=${PETSC_USE_PTSCOTCH}
            SCOTCH_FIND_SYSTEM=${SCOTCH_FIND_SYSTEM}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            USE_SUPERLU=${PETSC_USE_SUPERLU}
            SUPERLU_FIND_SYSTEM=${SUPERLU_FIND_SYSTEM}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            USE_SUNDIALS=${PETSC_USE_SUNDIALS}
            SUNDIALS_FIND_SYSTEM=${SUNDIALS_FIND_SYSTEM}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            USE_HYPRE=${PETSC_USE_HYPRE}
            HYPRE_FIND_SYSTEM=${HYPRE_FIND_SYSTEM}
            HYPRE_VERSION=${HYPRE_VERSION}
            USE_SUPERLU_DIST=${PETSC_USE_SUPERLU_DIST}
            SUPERLU_DIST_FIND_SYSTEM=${SUPERLU_DIST_FIND_SYSTEM}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION}
            USE_PARMETIS=${PETSC_USE_PARMETIS}
            PARMETIS_FIND_SYSTEM=${PARMETIS_FIND_SYSTEM}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
            PETSC_FIND_SYSTEM=${PETSC_FIND_SYSTEM}
        )
    endif ()
endif ()

# CellML
if (LIBCELLML IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT LIBCELLML_FOUND)
        SET(LIBCELLML_FWD_DEPS CSIM CELLML IRON)
        addAndConfigureLocalComponent(LIBCELLML
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
        )
    endif ()
endif ()

if (CSIM IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (LLVM IN_LIST OC_BUILD_LOCAL_COMPONENTS)
        if (NOT LLVM_FOUND)
            SET(LLVM_FWD_DEPS CSIM CLANG)
            addAndConfigureLocalComponent(LLVM
                ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
                ZLIB_VERSION=${ZLIB_VERSION}
                GTEST_FIND_SYSTEM=${GTEST_FIND_SYSTEM}
                GTEST_VERSION=${GTEST_VERSION}
            )
        endif ()
    endif ()
    
    if (CLANG IN_LIST OC_BUILD_LOCAL_COMPONENTS)
        if (NOT CLANG_FOUND)
            SET(CLANG_FWD_DEPS CSIM)
            addAndConfigureLocalComponent(CLANG
                GTEST_FIND_SYSTEM=${GTEST_FIND_SYSTEM}
                GTEST_VERSION=${GTEST_VERSION}
                LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
                LIBXML2_VERSION=${LIBXML2_VERSION}
            )
        endif ()
    endif ()
    
    if (NOT CSIM_FOUND)
        SET(CSIM_FWD_DEPS IRON CELLML)
        addAndConfigureLocalComponent(CSIM
            LLVM_FIND_SYSTEM=${LLVM_FIND_SYSTEM}
            LLVM_VERSION=${LLVM_VERSION}
            CLANG_FIND_SYSTEM=${CLANG_FIND_SYSTEM}
            CLANG_VERSION=${CLANG_VERSION}
            GTEST_FIND_SYSTEM=${GTEST_FIND_SYSTEM}
            GTEST_VERSION=${GTEST_VERSION}
            LIBCELLML_FIND_SYSTEM=${LIBCELLML_FIND_SYSTEM}
            LIBCELLML_VERSION=${LIBCELLML_VERSION}
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
        )
    endif ()
endif ()

if (CELLML IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT CELLML_FOUND)
        set(CELLML_FWD_DEPS IRON)
        foreach(dependency CSIM)
            if(CELLML_WITH_${dependency} AND OC_USE_${dependency})
                set(CELLML_USE_${dependency} ON)
            else()
                set(CELLML_USE_${dependency} OFF)
            endif()
        endforeach()

        addAndConfigureLocalComponent(CELLML
            BUILD_TESTS=${BUILD_TESTS}
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
            CSIM_FIND_SYSTEM=${CSIM_FIND_SYSTEM}
            CSIM_VERSION=${CSIM_VERSION}
            LIBCELLML_FIND_SYSTEM=${LIBCELLML_FIND_SYSTEM}
            LIBCELLML_VERSION=${LIBCELLML_VERSION}
            CELLML_USE_CSIM=${CELLML_WITH_CSIM}
        )
    endif ()
endif ()

if (IRON IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    set(SUBGROUP_PATH .)
    foreach(dependency CELLML;FIELDML-API;HYPRE;MUMPS;PETSC;SCALAPACK;SUNDIALS)
        if(IRON_WITH_${dependency} AND OC_USE_${dependency})
            set(IRON_USE_${dependency} ON)
        else()
            set(IRON_USE_${dependency} OFF)
        endif()
    endforeach()
    if (OPENCMISS_IRON_INSTALL_PREFIX)
        set(_VIRTUALENV_INSTALL_PREFIX ${OPENCMISS_IRON_INSTALL_PREFIX}/virtual_environments)
    else ()
        set(_VIRTUALENV_INSTALL_PREFIX ${OCL_VIRTUALENV_INSTALL_PREFIX})
    endif ()
    if (EXISTS "${OPENCMISS_PYTHON_EXECUTABLE}")
        set(_IRON_PYTHON_EXECUTABLE_CONFIG_PARAMETER "Python_EXECUTABLE=${OPENCMISS_PYTHON_EXECUTABLE}")
    endif ()

    addAndConfigureLocalComponent(IRON
        BUILD_TESTS=${BUILD_TESTS}
        WITH_CELLML=${IRON_USE_CELLML}
        LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
        LIBXML2_VERSION=${LIBXML2_VERSION}
        CELLML_FIND_SYSTEM=${CELLML_FIND_SYSTEM}
        CELLML_VERSION=${CELLML_VERSION}
        LIBCELLML_FIND_SYSTEM=${LIBCELLML_FIND_SYSTEM}
        LIBCELLML_VERSION=${LIBCELLML_VERSION}
        WITH_FIELDML=${IRON_USE_FIELDML-API}
        FIELDML-API_FIND_SYSTEM=${FIELDML-API_FIND_SYSTEM}
        FIELDML-API_VERSION=${FIELDML-API_VERSION} 
        WITH_HYPRE=${IRON_USE_HYPRE}
        HYPRE_FIND_SYSTEM=${HYPRE_FIND_SYSTEM}
        HYPRE_VERSION=${HYPRE_VERSION}
        WITH_SUNDIALS=${IRON_USE_SUNDIALS}
        SUNDIALS_FIND_SYSTEM=${SUNDIALS_FIND_SYSTEM}
        SUNDIALS_VERSION=${SUNDIALS_VERSION}
        WITH_MUMPS=${IRON_USE_MUMPS}
        MUMPS_FIND_SYSTEM=${MUMPS_FIND_SYSTEM}
        MUMPS_VERSION=${MUMPS_VERSION}
        WITH_SCALAPACK=${IRON_USE_SCALAPACK}
        SCALAPACK_FIND_SYSTEM=${SCALAPACK_FIND_SYSTEM}
        SCALAPACK_VERSION=${SCALAPACK_VERSION}
        BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
        BLAS_VERSION=${LAPACK_VERSION}
        LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
        LAPACK_VERSION=${LAPACK_VERSION}
        WITH_PETSC=${IRON_USE_PETSC}
        PETSC_FIND_SYSTEM=${PETSC_FIND_SYSTEM}
        PETSC_VERSION=${PETSC_VERSION}
        WITH_PROFILING=${OC_PROFILING}
        WITH_C_BINDINGS=${IRON_WITH_C_BINDINGS}
        WITH_Python_BINDINGS=${IRON_WITH_Python_BINDINGS}
        ${_IRON_PYTHON_EXECUTABLE_CONFIG_PARAMETER}
        FE_VIRTUALENV_INSTALL_PREFIX=${_VIRTUALENV_INSTALL_PREFIX}
        FE_USE_VIRTUALENV=${OC_PYTHON_BINDINGS_USE_VIRTUALENV}
    )
endif ()

set(SUBGROUP_PATH dependencies)

# jpeg
if (JPEG IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT JPEG_FOUND)
        set(JPEG_FWD_DEPS ZINC TIFF GDCM-ABI IMAGEMAGICK ITK)
        addAndConfigureLocalComponent(JPEG
            JPEG_BUILD_CJPEG=OFF
            JPEG_BUILD_DJPEG=OFF
            JPEG_BUILD_JPEGTRAN=OFF
            JPEG_BUILD_RDJPGCOM=OFF
            JPEG_BUILD_WRJPGCOM=OFF
        )
    endif ()
endif ()

# netgen
if (NETGEN IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT NETGEN_FOUND)
        set(NETGEN_FWD_DEPS ZINC)
        addAndConfigureLocalComponent(NETGEN
            NETGEN_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            NETGEN_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        )
    endif ()
endif ()

# Freetype
if (FREETYPE IN_LIST OC_BUILD_LOCAL_COMPONENTS)
        if (NOT FREETYPE_FOUND)
        set(FREETYPE_FWD_DEPS FTGL)
            addAndConfigureLocalComponent(FREETYPE
                FREETYPE_USE_ZLIB=YES
                FREETYPE_USE_BZIP2=YES
                ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
                ZLIB_VERSION=${ZLIB_VERSION}
                BZIP2_FIND_SYSTEM=${BZIP2_FIND_SYSTEM}
                BZIP2_VERSION=${BZIP2_VERSION}
            )
    endif ()
endif ()

# FTGL
if (FTGL IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT FTGL_FOUND)
        set(FTGL_FWD_DEPS ZINC)
        addAndConfigureLocalComponent(FTGL
            FREETYPE_FIND_SYSTEM=${FREETYPE_FIND_SYSTEM}
            FREETYPE_VERSION=${FREETYPE_VERSION}
        )
    endif ()
endif ()

# GLEW
if (GLEW IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT GLEW_FOUND)
        set(GLEW_FWD_DEPS ZINC)
        addAndConfigureLocalComponent(GLEW)
    endif ()
endif ()

# opt++
if (OPTPP IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT OPTPP_FOUND)
        set(OPTPP_FWD_DEPS ZINC)
        foreach(dependency BLAS)
            if(OPTPP_WITH_${dependency} AND OC_USE_${dependency})
                set(OPTPP_USE_${dependency} ON)
            else()
                set(OPTPP_USE_${dependency} OFF)
            endif()
        endforeach()

        addAndConfigureLocalComponent(OPTPP
            USE_EXTERNAL_BLAS=${OPTPP_USE_BLAS}
            ${BLA_VENDOR_CONFIG}
            BLAS_FIND_SYSTEM=${BLAS_FIND_SYSTEM}
            BLAS_VERSION=${LAPACK_VERSION}
            LAPACK_FIND_SYSTEM=${LAPACK_FIND_SYSTEM}
            LAPACK_VERSION=${LAPACK_VERSION}
        )
    endif ()
endif ()

# png
if (PNG IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT PNG_FOUND)
        set(PNG_FWD_DEPS ZINC ITK IMAGEMAGICK)
        addAndConfigureLocalComponent(PNG
            PNG_NO_CONSOLE_IO=OFF
            PNG_NO_STDIO=OFF
            PNG_SHARED=OFF
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
        )
    endif ()
endif ()

# tiff
if (TIFF IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT TIFF_FOUND)
        set(TIFF_FWD_DEPS ZINC ITK IMAGEMAGICK)
        addAndConfigureLocalComponent(TIFF
            TIFF_BUILD_TOOLS=OFF
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
            PNG_FIND_SYSTEM=${PNG_FIND_SYSTEM}
            PNG_VERSION=${PNG_VERSION}
            JPEG_FIND_SYSTEM=${JPEG_FIND_SYSTEM}
            JPEG_VERSION=${JPEG_VERSION}
        )
    endif ()
endif ()

# gdcm
if (GDCM-ABI IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT GDCM-ABI_FOUND)
        set(GDCM-ABI_FWD_DEPS ZINC ITK IMAGEMAGICK)
        # Make EXPAT and UUID platform dependent?
        if (MSVC)
            set(GDCM_USE_SYSTEM_EXPAT OFF)
        else ()
            set(GDCM_USE_SYSTEM_EXPAT OFF)
        endif ()
        addAndConfigureLocalComponent(GDCM-ABI
            GDCM_INSTALL_PACKAGE_DIR=${COMMON_PACKAGE_CONFIG_DIR}
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
            GDCM_USE_SYSTEM_ZLIB=ON
            GDCM_USE_SYSTEM_EXPAT=${GDCM_USE_SYSTEM_EXPAT}
        )
    endif ()
endif ()

if (IMAGEMAGICK IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT IMAGEMAGICK_FOUND)
        set(IMAGEMAGICK_FWD_DEPS ZINC)
        addAndConfigureLocalComponent(IMAGEMAGICK
            IMAGEMAGICK_WITH_MAGICKPP=OFF
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
            BZIP2_FIND_SYSTEM=${BZIP2_FIND_SYSTEM}
            BZIP2_VERSION=${BZIP2_VERSION}
            GDCM-ABI_FIND_SYSTEM=${GDCM-ABI_FIND_SYSTEM}
            GDCM-ABI_VERSION=${GDCM-ABI_VERSION}
            TIFF_FIND_SYSTEM=${TIFF_FIND_SYSTEM}
            TIFF_VERSION=${TIFF_VERSION}
            JPEG_FIND_SYSTEM=${JPEG_FIND_SYSTEM}
            JPEG_VERSION=${JPEG_VERSION}
            PNG_FIND_SYSTEM=${PNG_FIND_SYSTEM}
            PNG_VERSION=${PNG_VERSION}
        )
    endif ()
endif ()

if (ITK IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    if (NOT ITK_FOUND)
        if (MSVC)
            set(HDF5_SETTINGS ITK_USE_SYSTEM_HDF5=ON HDF5_VERSION=${HDF5_VERSION} HDF5_ENABLE_PARALLEL=${HDF5_USE_MPI})
        endif ()
        set(ITK_FWD_DEPS ZINC)
        addAndConfigureLocalComponent(ITK
            ITK_BUILD_TESTING=OFF
            ITK_BUILD_EXAMPLES=OFF
            ITK_INSTALL_PACKAGE_DIR=${COMMON_PACKAGE_CONFIG_DIR}
            ${HDF5_SETTINGS}
            ITK_USE_SYSTEM_PNG=ON
            ITK_USE_SYSTEM_TIFF=OFF # ITK now uses bigtiff, which is different from tiff
            ITK_USE_SYSTEM_JPEG=ON
            ITK_USE_SYSTEM_LIBXML2=ON
            ITK_USE_SYSTEM_ZLIB=ON
            ITK_USE_SYSTEM_GDCM=ON
            ITK_USE_KWSTYLE=OFF
            ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
            ZLIB_VERSION=${ZLIB_VERSION}
            PNG_FIND_SYSTEM=${PNG_FIND_SYSTEM}
            PNG_VERSION=${PNG_VERSION}
            JPEG_FIND_SYSTEM=${JPEG_FIND_SYSTEM}
            JPEG_VERSION=${JPEG_VERSION}
            # TIFF_VERSION=${TIFF_VERSION}
            LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
            LIBXML2_VERSION=${LIBXML2_VERSION}
            GDCM-ABI_FIND_SYSTEM=${GDCM-ABI_FIND_SYSTEM}
            GDCM-ABI_VERSION=${GDCM-ABI_VERSION}
        )
    endif ()
endif ()

if (ZINC IN_LIST OC_BUILD_LOCAL_COMPONENTS)
    string(REPLACE ";" ${OC_LIST_SEPARATOR} CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")
    set(ZINC_BUILD_TESTS FALSE)
    if (OC_BUILD_ZINC_TESTS OR BUILD_TESTS)
        set(ZINC_BUILD_TESTS TRUE)
    endif ()
    if (OPENCMISS_LIBRARIES_ONLY)
        set(_DEPENDENCIES_INSTALL_PREFIX ${OPENCMISS_DEPENDENCIES_INSTALL_PREFIX})
        if (OPENCMISS_ZINC_INSTALL_PREFIX)
            set(_VIRTUALENV_INSTALL_PREFIX ${OPENCMISS_ZINC_INSTALL_PREFIX}/virtual_environments)
        else ()
            set(_VIRTUALENV_INSTALL_PREFIX ${OCL_VIRTUALENV_INSTALL_PREFIX})
        endif ()
    else ()
        set(_VIRTUALENV_INSTALL_PREFIX ${OCL_VIRTUALENV_INSTALL_PREFIX})
        set(_DEPENDENCIES_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
    endif ()
    if (EXISTS "${OPENCMISS_PYTHON_EXECUTABLE}")
        set(_ZINC_PYTHON_EXECUTABLE_CONFIG_PARAMETER "Python_EXECUTABLE=${OPENCMISS_PYTHON_EXECUTABLE}")
    endif ()
    set(SUBGROUP_PATH .)
    addAndConfigureLocalComponent(ZINC
        ZLIB_FIND_SYSTEM=${ZLIB_FIND_SYSTEM}
        ZLIB_VERSION=${ZLIB_VERSION}
        LIBXML2_FIND_SYSTEM=${LIBXML2_FIND_SYSTEM}
        LIBXML2_VERSION=${LIBXML2_VERSION}
        BZIP2_FIND_SYSTEM=${BZIP2_FIND_SYSTEM}
        BZIP2_VERSION=${BZIP2_VERSION}
        FIELDML-API_FIND_SYSTEM=${FIELDML-API_FIND_SYSTEM}
        FIELDML-API_VERSION=${FIELDML-API_VERSION}
        FREETYPE_FIND_SYSTEM=${FREETYPE_FIND_SYSTEM}
        FREETYPE_VERSION=${FREETYPE_VERSION}
        FTGL_FIND_SYSTEM=${FTGL_FIND_SYSTEM}
        FTGL_VERSION=${FTGL_VERSION}
        OPTPP_FIND_SYSTEM=${OPTPP_FIND_SYSTEM}
        OPTPP_VERSION=${OPTPP_VERSION}
        GLEW_FIND_SYSTEM=${GLEW_FIND_SYSTEM}
        GLEW_VERSION=${GLEW_VERSION}
        NETGEN_FIND_SYSTEM=${NETGEN_FIND_SYSTEM}
        NETGEN_VERSION=${NETGEN_VERSION}
        PNG_FIND_SYSTEM=${PNG_FIND_SYSTEM}
        PNG_VERSION=${PNG_VERSION}
        JPEG_FIND_SYSTEM=${JPEG_FIND_SYSTEM}
        JPEG_VERSION=${JPEG_VERSION}
        GTEST_FIND_SYSTEM=${GTEST_FIND_SYSTEM}
        GTEST_VERSION=${GTEST_VERSION}
        ITK_FIND_SYSTEM=${ITK_FIND_SYSTEM}
        ITK_VERSION=${ITK_VERSION}
        IMAGEMAGICK_FIND_SYSTEM=${IMAGEMAGICK_FIND_SYSTEM}
        IMAGEMAGICK_VERSION=${IMAGEMAGICK_VERSION}
        ZINC_USE_IMAGEMAGICK=${OC_USE_IMAGEMAGICK}
        ZINC_USE_ITK=${OC_USE_ITK}
        ZINC_BUILD_TESTS=${ZINC_BUILD_TESTS}}
        ZINC_BUILD_BINDINGS=${SWIG_FOUND}
        ZINC_BUILD_PYTHON_BINDINGS=${ZINC_WITH_Python_BINDINGS}
        ZINC_PACKAGE_CONFIG_DIR=${COMMON_PACKAGE_CONFIG_DIR}
        ZINC_DEPENDENCIES_INSTALL_PREFIX=${_DEPENDENCIES_INSTALL_PREFIX}
        ZINC_VIRTUALENV_INSTALL_PREFIX=${_VIRTUALENV_INSTALL_PREFIX}
        ZINC_USE_VIRTUALENV=${OC_PYTHON_BINDINGS_USE_VIRTUALENV}
        ${_ZINC_PYTHON_EXECUTABLE_CONFIG_PARAMETER}
    )
    #if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
    #    add_dependencies(${OC_EP_PREFIX}ZINC virtualenv_install)
    #endif ()
endif ()

# Notes:
# lapack: not sure if LAPACKE is build/required
# plapack: have only MACHINE_TYPE=500 and MANUFACTURE=50 (linux)
# plapack: some tests are not compiling
# parmetis/metis: test programs not available (but for gklib, and they are also rudimental), linking executables instead to have a 50% "its working" test
# mumps - not setup for libseq / sequential version
# metis: have fixed IDXTYPEWIDTH 32
# cholmod: could go with CUDA BLAS version (indicated by makefile)
# umfpack: building only "int" version right now (Suitesparse_long impl for AMD,CAMD etc but not umfpack)

# TODO
# cholmod - use CUDA stuff
