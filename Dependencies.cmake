# Forward/downstream dependencies (for cmake build ordering and dependency checking)
# Its organized this way as not all backward dependencies might be built by the cmake
# system. here, the actual dependency list is filled "as we go" and actually build
# packages locally, see ADD_DOWNSTREAM_DEPS in BuildMacros.cmake
SET(HYPRE_FWD_DEPS PETSC IRON)
SET(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
        SUPERLU SUPERLU_DIST PARMETIS HYPRE SUNDIALS PASTIX PLAPACK PETSC IRON)
SET(LIBCELLML_FWD_DEPS IRON)
SET(MUMPS_FWD_DEPS PETSC IRON)
SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST PASTIX IRON)
SET(PASTIX_FWD_DEPS PETSC IRON)
SET(PTSCOTCH_FWD_DEPS PASTIX PETSC MUMPS IRON)
SET(SCALAPACK_FWD_DEPS MUMPS PETSC IRON)
SET(SCOTCH_FWD_DEPS PASTIX PETSC MUMPS IRON)
SET(SLEPC_FWD_DEPS IRON)
SET(SOWING_FWD_DEPS PETSC)
SET(SUNDIALS_FWD_DEPS PETSC IRON)
SET(SUPERLU_FWD_DEPS PETSC IRON)
SET(SUITESPARSE_FWD_DEPS PETSC IRON)
SET(SUPERLU_DIST_FWD_DEPS PETSC IRON)
SET(PETSC_FWD_DEPS SLEPC IRON)
SET(ZLIB_FWD_DEPS SCOTCH PTSCOTCH IRON)

# ================================
# Postprocessing
# ================================
#FOREACH(OCM_DEP ${OPENCMISS_COMPONENTS})
    # Make a dependency check and enable other packages if required
    #if (${OCM_DEP}_FWD_DEPS)
    #    foreach(FWD_DEP ${${OCM_DEP}_FWD_DEPS})
    #        if(OCM_USE_${FWD_DEP} AND NOT OCM_USE_${OCM_DEP})
    #            message(STATUS "Package ${FWD_DEP} requires ${OCM_DEP}, setting OCM_USE_${OCM_DEP}=ON")
    #            set(OCM_USE_${OCM_DEP} ON)
    #        endif() 
    #    endforeach()
    #endif()
#ENDFOREACH()

# ================================
# Package creation
# ================================

# Affects the ADD_COMPONENT macro
set(SUBGROUP_PATH dependencies)
set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)

# Note: The following order for all packages has to be in their interdependency order,
# i.e. mumps may need scotch so scotch has to be processed first on order to be added to the 
# external project dependencies list of any following package

# LAPACK (includes BLAS)
if (OCM_USE_BLAS OR OCM_USE_LAPACK)
    if(OCM_BLAS_LOCAL)
        find_package(BLAS ${BLAS_VERSION} QUIET)
    endif()
    if(OCM_LAPACK_LOCAL) 
        find_package(LAPACK ${LAPACK_VERSION} QUIET)
    endif()    
    if(NOT (LAPACK_FOUND AND BLAS_FOUND))
        ADD_COMPONENT(LAPACK)
    endif()
endif()

# zLIB
if(OCM_USE_ZLIB)
    if(OCM_ZLIB_LOCAL)
        FIND_PACKAGE(ZLIB QUIET)
    endif()        
    if(NOT ZLIB_FOUND)
        ADD_COMPONENT(ZLIB)
    endif()
endif()

# Scotch 6.0
if (OCM_USE_PTSCOTCH)
    if (OCM_PTSCOTCH_LOCAL)
        FIND_PACKAGE(PTSCOTCH ${PTSCOTCH_VERSION} QUIET)
    endif()
    if(NOT PTSCOTCH_FOUND)
        ADD_COMPONENT(SCOTCH
            BUILD_PTSCOTCH=YES USE_ZLIB=${SCOTCH_WITH_ZLIB}
            USE_THREADS=${SCOTCH_USE_THREADS})
    endif()
elseif(OCM_USE_SCOTCH)
    if(OCM_SCOTCH_LOCAL)
        FIND_PACKAGE(SCOTCH ${SCOTCH_VERSION} QUIET)
    endif()
    if(NOT SCOTCH_FOUND)
        ADD_COMPONENT(SCOTCH 
            BUILD_PTSCOTCH=NO USE_ZLIB=${SCOTCH_WITH_ZLIB}
            USE_THREADS=${SCOTCH_USE_THREADS})
    endif()
endif()

# PLAPACK
if(OCM_USE_PLAPACK)
    if(OCM_PLAPACK_LOCAL)
        FIND_PACKAGE(PLAPACK QUIET)
    endif()        
    if(NOT PLAPACK_FOUND)
        ADD_COMPONENT(PLAPACK
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# ScaLAPACK
if(OCM_USE_SCALAPACK)
    if(OCM_SCALAPACK_LOCAL)
        FIND_PACKAGE(SCALAPACK ${SCALAPACK_VERSION} QUIET)
    endif()
    if(NOT SCALAPACK_FOUND)
        ADD_COMPONENT(SCALAPACK
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# parMETIS 4 (+METIS 5)
if(OCM_USE_PARMETIS)
    if(OCM_PARMETIS_LOCAL)
        FIND_PACKAGE(PARMETIS ${PARMETIS_VERSION} QUIET)
    endif()
    if(NOT PARMETIS_FOUND)
        ADD_COMPONENT(PARMETIS)
    endif()
endif()

# MUMPS
if (OCM_USE_MUMPS)
    if(OCM_MUMPS_LOCAL)
        FIND_PACKAGE(MUMPS ${MUMPS_VERSION} QUIET)
    endif()
    if(NOT MUMPS_FOUND)
        ADD_COMPONENT(MUMPS 
            USE_SCOTCH=${MUMPS_WITH_SCOTCH}
            USE_PTSCOTCH=${MUMPS_WITH_PTSCOTCH}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCOTCH_VERSION=${SCOTCH_VERSION}
            USE_PARMETIS=${MUMPS_WITH_PARMETIS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
        )
    endif()
endif()

# SUITESPARSE [CHOLMOD / UMFPACK]
if (OCM_USE_SUITESPARSE)
    if(OCM_SUITESPARSE_LOCAL)
        FIND_PACKAGE(SUITESPARSE ${SUITESPARSE_VERSION} QUIET)
    endif()
    if(NOT SUITESPARSE_FOUND)
        ADD_COMPONENT(SUITESPARSE
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION}
            METIS_VERSION=${METIS_VERSION})
    endif()
endif()

# Hypre 2.9.0b
if (OCM_USE_HYPRE)
    if(OCM_HYPRE_LOCAL)
        FIND_PACKAGE(HYPRE ${HYPRE_VERSION} QUIET)
    endif()
    if(NOT HYPRE_FOUND)
        ADD_COMPONENT(HYPRE
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# SuperLU 4.3
if (OCM_USE_SUPERLU)
    if(OCM_SUPERLU_LOCAL)
        FIND_PACKAGE(SUPERLU ${SUPERLU_VERSION} QUIET)
    endif()        
    if(NOT SUPERLU_FOUND)
        ADD_COMPONENT(SUPERLU
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# SuperLU-DIST 4.0
if (OCM_USE_SUPERLU_DIST)
    if(OCM_SUPERLU_DIST_LOCAL)
        FIND_PACKAGE(SUPERLU_DIST ${SUPERLU_DIST_VERSION} QUIET)
    endif()        
    if(NOT SUPERLU_DIST_FOUND)
        ADD_COMPONENT(SUPERLU_DIST
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
    if(OCM_SUNDIALS_LOCAL)
        FIND_PACKAGE(SUNDIALS ${SUNDIALS_VERSION} QUIET)
    endif()
    if(NOT SUNDIALS_FOUND)
        ADD_COMPONENT(SUNDIALS
            USE_LAPACK=${SUNDIALS_WITH_LAPACK}
            BLAS_VERSION=${BLAS_VERSION}
            LAPACK_VERSION=${LAPACK_VERSION})
    endif()
endif()

# Pastix 5.2.2.16
if (OCM_USE_PASTIX)
    if(OCM_PASTIX_LOCAL)
        FIND_PACKAGE(PASTIX ${PASTIX_VERSION} QUIET)
    endif()
    if(NOT PASTIX_FOUND)
        ADD_COMPONENT(PASTIX
            USE_THREADS=${PASTIX_USE_THREADS}
            USE_METIS=${PASTIX_USE_METIS}
            USE_PTSCOTCH=${PASTIX_USE_PTSCOTCH})
    endif()
endif()

# Sowing (only for PETSC ftn-auto generation)
if (OCM_USE_SOWING)
    if(OCM_SOWING_LOCAL)
        FIND_PACKAGE(SOWING ${SOWING_VERSION} QUIET)
    endif()
    if(NOT SOWING_FOUND)
        ADD_COMPONENT(SOWING)
    endif()
endif()

# PETSc 3.5
if (OCM_USE_PETSC)
    if(OCM_PETSC_LOCAL)
        FIND_PACKAGE(PETSC ${PETSC_VERSION} QUIET)
    endif()
    if(NOT PETSC_FOUND)
        ADD_COMPONENT(PETSC
            HYPRE_VERSION=${HYPRE_VERSION}
            MUMPS_VERSION=${MUMPS_VERSION}
            OCM_MUMPS=${OCM_MUMPS}
            PARMETIS_VERSION=${PARMETIS_VERSION}
            PASTIX_VERSION=${PASTIX_VERSION}
            PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            SCALAPACK_VERSION=${SCALAPACK_VERSION}
            SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
            SUNDIALS_VERSION=${SUNDIALS_VERSION}
            SUPERLU_VERSION=${SUPERLU_VERSION}
            SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION})
    endif()
endif()

# SLEPc 3.5
if (OCM_USE_SLEPC)
    if(OCM_SLEPC_LOCAL)
        FIND_PACKAGE(SLEPC ${SLEPC_VERSION} QUIET)
    endif()
    if(NOT SLEPC_FOUND)
        ADD_COMPONENT(SLEPC
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
    ADD_COMPONENT(LIBCELLML)
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