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
if (OC_USE_GTEST AND (BUILD_TESTS OR OC_BUILD_ZINC_TESTS))
    find_package(GTEST ${GTEST_VERSION} QUIET)
    if(NOT GTEST_FOUND)
        set(GTEST_FWD_DEPS LLVM CSIM ZINC)
        set(SUBGROUP_PATH utilities)
        set(GITHUB_ORGANIZATION OpenCMISS-Utilities)
        addAndConfigureLocalComponent(GTEST
            gtest_force_shared_crt=YES
        )
    endif()
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


# zLIB
if(OC_USE_ZLIB OR OC_USE_ZINC OR OC_DEPENDENCIES_ONLY)
    find_package(ZLIB ${ZLIB_VERSION} QUIET)
    if(NOT ZLIB_FOUND)
        SET(ZLIB_FWD_DEPS 
            SCOTCH PTSCOTCH 
            MUMPS LIBXML2 HDF5 FIELDML-API
            IRON CSIM LLVM CELLML PNG
            TIFF GDCM-ABI)
        addAndConfigureLocalComponent(ZLIB)
    endif()
endif()


# libxml2
find_package(LibXml2 ${LIBXML2_VERSION} QUIET)
if(NOT LIBXML2_FOUND)
    SET(LIBXML2_FWD_DEPS CSIM LLVM FIELDML-API CELLML LIBCELLML ITK)
    addAndConfigureLocalComponent(LIBXML2
        WITH_ZLIB=${LIBXML2_WITH_ZLIB}
        ZLIB_VERSION=${ZLIB_VERSION}
    )
endif()

# LAPACK (includes BLAS)
# Thus far only Iron really makes heavy use of BLAS/LAPACK, opt++ from zinc
# dependencies is the only other dependency that can make use of (external) BLAS/LAPACK.
if ((OC_USE_BLAS OR OC_USE_LAPACK) AND (OC_USE_IRON OR (OC_USE_OPTPP AND OPTPP_WITH_BLAS)))
    find_package(BLAS ${BLAS_VERSION} QUIET)
    find_package(LAPACK ${LAPACK_VERSION} QUIET)
    if(NOT (LAPACK_FOUND AND BLAS_FOUND))
        SET(LAPACK_FWD_DEPS SCALAPACK SUITESPARSE MUMPS
            SUPERLU SUPERLU_DIST PARMETIS HYPRE SUNDIALS PASTIX PLAPACK PETSC IRON)
        addAndConfigureLocalComponent(LAPACK)
    endif()
endif()

# bzip2
if(OC_USE_BZIP2 OR OC_USE_ZINC OR OC_DEPENDENCIES_ONLY)
    find_package(BZIP2 ${BZIP2_VERSION} QUIET)
    if(NOT BZIP2_FOUND)
        SET(BZIP2_FWD_DEPS SCOTCH PTSCOTCH GDCM-ABI IMAGEMAGICK)
        addAndConfigureLocalComponent(BZIP2)
    endif()
endif()

# hdf5
if(OC_USE_HDF5)

    # szip
    if(OC_USE_SZIP)
        find_package(SZIP ${SZIP_VERSION} QUIET)
        if(NOT SZIP_FOUND)
            SET(SZIP_FWD_DEPS HDF5)
            addAndConfigureLocalComponent(SZIP)
        endif()
    endif()

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
            HDF5_BUILD_FORTRAN=${HDF5_BUILD_FORTRAN}
        )
    endif()
endif()

# Fieldml
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

# ================================================================
# Iron
# ================================================================
if (OC_USE_IRON OR OC_DEPENDENCIES_ONLY)
    
    # Scotch 6.0
    if (OC_USE_PTSCOTCH)
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
    elseif(OC_USE_SCOTCH)
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
    if(OC_USE_PLAPACK)
        find_package(PLAPACK ${PLAPACK_VERSION} QUIET)
        if(NOT PLAPACK_FOUND)
            SET(PLAPACK_FWD_DEPS IRON)
            addAndConfigureLocalComponent(PLAPACK
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION})
        endif()
    endif()
    
    # ScaLAPACK
    if(OC_USE_SCALAPACK)
        find_package(SCALAPACK ${SCALAPACK_VERSION} QUIET)
        if(NOT SCALAPACK_FOUND)
            SET(SCALAPACK_FWD_DEPS MUMPS PETSC IRON)
            addAndConfigureLocalComponent(SCALAPACK
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION})
        endif()
    endif()
    
    # parMETIS 4 (+METIS 5)
    if(OC_USE_PARMETIS)
        find_package(PARMETIS ${PARMETIS_VERSION} QUIET)
        if(NOT PARMETIS_FOUND)
            SET(PARMETIS_FWD_DEPS MUMPS SUITESPARSE SUPERLU_DIST PASTIX IRON)
            addAndConfigureLocalComponent(PARMETIS)
        endif()
    endif()
    
    # MUMPS
    if (OC_USE_MUMPS)
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
    if (OC_USE_SUITESPARSE)
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
    if (OC_USE_SUPERLU)
        find_package(SUPERLU ${SUPERLU_VERSION} QUIET)
        if(NOT SUPERLU_FOUND)
            SET(SUPERLU_FWD_DEPS PETSC IRON HYPRE)
            addAndConfigureLocalComponent(SUPERLU
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION})
        endif()
    endif()
    
    # Hypre 2.9.0b
    if (OC_USE_HYPRE)
        find_package(HYPRE ${HYPRE_VERSION} QUIET)
        if(NOT HYPRE_FOUND)
            SET(HYPRE_FWD_DEPS PETSC IRON)
            addAndConfigureLocalComponent(HYPRE
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION})
        endif()
    endif()
    
    # SuperLU-DIST 4.0
    if (OC_USE_SUPERLU_DIST)
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
    if (OC_USE_SUNDIALS)
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
    if (OC_USE_PASTIX)
        find_package(PASTIX ${PASTIX_VERSION} QUIET)
        if(NOT PASTIX_FOUND)
            SET(PASTIX_FWD_DEPS PETSC IRON)
            addAndConfigureLocalComponent(PASTIX
                BLAS_VERSION=${BLAS_VERSION}
                USE_THREADS=${PASTIX_USE_THREADS}
                USE_METIS=${PASTIX_USE_METIS}
                USE_PTSCOTCH=${PASTIX_USE_PTSCOTCH}
                METIS_VERSION=${METIS_VERSION}
                PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
            )
        endif()
    endif()
    
    # Sowing (only for PETSC ftn-auto generation)
    if (OC_USE_SOWING)
        find_package(SOWING ${SOWING_VERSION} QUIET)
        if(NOT SOWING_FOUND)
            SET(SOWING_FWD_DEPS PETSC)
            addAndConfigureLocalComponent(SOWING)
        endif()
    endif()
    
    # PETSc 3.5
    if (OC_USE_PETSC)
        find_package(PETSC ${PETSC_VERSION} QUIET)
        if(NOT PETSC_FOUND)
            SET(PETSC_FWD_DEPS SLEPC IRON)
            addAndConfigureLocalComponent(PETSC
                USE_PASTIX=${PETSC_WITH_PASTIX}
                PASTIX_VERSION=${PASTIX_VERSION}
                USE_MUMPS=${PETSC_WITH_MUMPS}
                MUMPS_VERSION=${MUMPS_VERSION}
                USE_SUITESPARSE=${PETSC_WITH_SUITESPARSE}
                SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
                USE_SCALAPACK=${PETSC_WITH_SCALAPACK}
                SCALAPACK_VERSION=${SCALAPACK_VERSION}
                USE_PTSCOTCH=${PETSC_WITH_PTSCOTCH}
                PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
                USE_SUPERLU=${PETSC_WITH_SUPERLU}
                SUPERLU_VERSION=${SUPERLU_VERSION}
                USE_SUNDIALS=${PETSC_WITH_SUNDIALS}
                SUNDIALS_VERSION=${SUNDIALS_VERSION}
                USE_HYPRE=${PETSC_WITH_HYPRE}
                HYPRE_VERSION=${HYPRE_VERSION}
                USE_SUPERLU_DIST=${PETSC_WITH_SUPERLU_DIST}
                SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION}
                USE_PARMETIS=${PETSC_WITH_PARMETIS}
                PARMETIS_VERSION=${PARMETIS_VERSION}
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION}
            )
        endif()
    endif()
    
    # SLEPc 3.5
    if (OC_USE_SLEPC)
        find_package(SLEPC ${SLEPC_VERSION} QUIET)
        if(NOT SLEPC_FOUND)
            SET(SLEPC_FWD_DEPS IRON)
            addAndConfigureLocalComponent(SLEPC
                USE_PASTIX=${PETSC_WITH_PASTIX}
                PASTIX_VERSION=${PASTIX_VERSION}
                USE_MUMPS=${PETSC_WITH_MUMPS}
                MUMPS_VERSION=${MUMPS_VERSION}
                USE_SUITESPARSE=${PETSC_WITH_SUITESPARSE}
                SUITESPARSE_VERSION=${SUITESPARSE_VERSION}
                USE_SCALAPACK=${PETSC_WITH_SCALAPACK}
                SCALAPACK_VERSION=${SCALAPACK_VERSION}
                USE_PTSCOTCH=${PETSC_WITH_PTSCOTCH}
                PTSCOTCH_VERSION=${PTSCOTCH_VERSION}
                USE_SUPERLU=${PETSC_WITH_SUPERLU}
                SUPERLU_VERSION=${SUPERLU_VERSION}
                USE_SUNDIALS=${PETSC_WITH_SUNDIALS}
                SUNDIALS_VERSION=${SUNDIALS_VERSION}
                USE_HYPRE=${PETSC_WITH_HYPRE}
                HYPRE_VERSION=${HYPRE_VERSION}
                USE_SUPERLU_DIST=${PETSC_WITH_SUPERLU_DIST}
                SUPERLU_DIST_VERSION=${SUPERLU_DIST_VERSION}
                USE_PARMETIS=${PETSC_WITH_PARMETIS}
                PARMETIS_VERSION=${PARMETIS_VERSION}
            )
        endif()
    endif()
    
    # CellML
    if (OC_USE_LIBCELLML)
        find_package(LIBCELLML ${LIBCELLML_VERSION} QUIET)
        if (NOT LIBCELLML_FOUND)
            SET(LIBCELLML_FWD_DEPS CSIM CELLML IRON)
            addAndConfigureLocalComponent(LIBCELLML)
        endif()
    endif()
    
    if (OC_USE_CELLML)
        find_package(CELLML ${CELLML_VERSION} QUIET)
        if (NOT CELLML_FOUND)
            SET(CELLML_FWD_DEPS IRON)
            addAndConfigureLocalComponent(CELLML
                LIBXML2_VERSION=${LIBXML2_VERSION})
        endif()
    endif()

    if (OC_USE_LLVM)
        find_package(LLVM ${LLVM_VERSION} QUIET)
        if (NOT LLVM_FOUND)
            SET(LLVM_FWD_DEPS CSIM)
            addAndConfigureLocalComponent(LLVM
                GTEST_VERSION=${GTEST_VERSION})
        endif()
    endif()
    if (OC_USE_CSIM)
        find_package(CSIM ${CSIM_VERSION} QUIET)
        if (NOT CSIM_FOUND)
            SET(CSIM_FWD_DEPS IRON)
            addAndConfigureLocalComponent(CSIM
                GTEST_VERSION=${GTEST_VERSION})
        endif()
    endif()

    if(NOT OC_DEPENDENCIES_ONLY)
        set(SUBGROUP_PATH .)
        set(GITHUB_ORGANIZATION OpenCMISS)
        addAndConfigureLocalComponent(IRON
            WITH_CELLML=${IRON_WITH_CELLML}
            CELLML_VERSION=${CELLML_VERSION}
            LIBCELLML_VERSION=${LIBCELLML_VERSION}
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
            WITH_PROFILING=${OC_PROFILING}
            WITH_C_BINDINGS=${IRON_WITH_C_BINDINGS}
            WITH_Python_BINDINGS=${IRON_WITH_Python_BINDINGS}
            PYTHON_BINDINGS_INSTALL_DIR=${PYTHON_BINDINGS_INSTALL_DIR}
            PYTHON_BINDINGS_INSTALL_DIR_IS_VIRTUALENV=${OC_PYTHON_BINDINGS_USE_VIRTUALENV}
        )
        if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
            add_dependencies(${OC_EP_PREFIX}IRON virtualenv_install)
        endif()
    endif()
endif()

if (OC_USE_ZINC OR (OPENGL_FOUND AND OC_DEPENDENCIES_ONLY))
    set(SUBGROUP_PATH dependencies)
    set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)
    
    # jpeg
    if(OC_USE_JPEG)
        find_package(JPEG ${JPEG_VERSION} QUIET)
        if(NOT JPEG_FOUND)
            set(JPEG_FWD_DEPS ZINC TIFF GDCM-ABI IMAGEMAGICK)
            addAndConfigureLocalComponent(JPEG
                JPEG_BUILD_CJPEG=OFF
                JPEG_BUILD_DJPEG=OFF
                JPEG_BUILD_JPEGTRAN=OFF
                JPEG_BUILD_RDJPGCOM=OFF
                JPEG_BUILD_WRJPGCOM=OFF
            )
        endif()
    endif()
    
    # netgen
    if (OC_USE_NETGEN)
        find_package(NETGEN ${NETGEN_VERSION} QUIET)
        if (NOT NETGEN_FOUND)
            set(NETGEN_FWD_DEPS ZINC)
            addAndConfigureLocalComponent(NETGEN
                NETGEN_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                NETGEN_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            )
        endif()
    endif()
    
    # Freetype
    if (OC_USE_FREETYPE)
        find_package(Freetype ${FREETYPE_VERSION} QUIET)
            if (NOT FREETYPE_FOUND)
            set(FREETYPE_FWD_DEPS FTGL)
                addAndConfigureLocalComponent(FREETYPE
                    FREETYPE_USE_ZLIB=YES
                    FREETYPE_USE_BZIP2=YES
                    ZLIB_VERSION=${ZLIB_VERSION}
                    BZIP2_VERSION=${BZIP2_VERSION})
        endif()
    endif()
    
    # FTGL
    if (OC_USE_FTGL)
        find_package(FTGL ${FTGL_VERSION} QUIET)
        if (NOT FTGL_FOUND)
            set(FTGL_FWD_DEPS ZINC)
            addAndConfigureLocalComponent(FTGL
                FREETYPE_VERSION=${FREETYPE_VERSION})
        endif()
    endif()
    
    # GLEW
    if (OC_USE_GLEW)
        find_package(GLEW ${GLEW_VERSION} QUIET)
        if (NOT GLEW_FOUND)
            set(GLEW_FWD_DEPS ZINC)
            addAndConfigureLocalComponent(GLEW)
        endif()
    endif()
    
    # opt++
    if (OC_USE_OPTPP)
        find_package(OPTPP ${OPTPP_VERSION} QUIET)
        if (NOT OPTPP_FOUND)
            addAndConfigureLocalComponent(OPTPP
                USE_EXTERNAL_BLAS=${OPTPP_WITH_BLAS}
                BLAS_VERSION=${BLAS_VERSION}
                LAPACK_VERSION=${LAPACK_VERSION})
        endif()
    endif()
    
    # png
    if (OC_USE_PNG)
        find_package(PNG ${LIBPNG_VERSION} QUIET)
        if (NOT PNG_FOUND)
            set(PNG_FWD_DEPS ZINC ITK IMAGEMAGICK PNG)
            addAndConfigureLocalComponent(PNG
                PNG_NO_CONSOLE_IO=OFF
                PNG_NO_STDIO=OFF
                ZLIB_VERSION=${ZLIB_VERSION}
            )
        endif()
    endif()
    
    # tiff
    if (OC_USE_TIFF)
        find_package(TIFF ${TIFF_VERSION} QUIET)
        if (NOT TIFF_FOUND)
            set(TIFF_FWD_DEPS ZINC ITK IMAGEMAGICK)
            addAndConfigureLocalComponent(TIFF
                TIFF_BUILD_TOOLS=OFF
                ZLIB_VERSION=${ZLIB_VERSION}
                PNG_VERSION=${PNG_VERSION}
                JPEG_VERSION=${JPEG_VERSION}
            )
        endif()
    endif()
    
    # gdcm
    if (OC_USE_GDCM-ABI)
        find_package(GDCM-ABI ${GDCM-ABI_VERSION} QUIET)
        if (NOT GDCM-ABI_FOUND)
            set(GDCM-ABI_FWD_DEPS ZINC ITK IMAGEMAGICK)
            # Make EXPAT and UUID platform dependent?
            addAndConfigureLocalComponent(GDCM-ABI
                GDCM-ABI_USE_SYSTEM_ZLIB=ON
                GDCM-ABI_USE_SYSTEM_EXPAT=ON
            )
        endif()
    endif()
    
    if (OC_USE_IMAGEMAGICK)
        find_package(IMAGEMAGICK ${IMAGEMAGICK_VERSION} QUIET)
        if (NOT IMAGEMAGICK_FOUND)
            set(IMAGEMAGICK_FWD_DEPS ZINC)
            addAndConfigureLocalComponent(IMAGEMAGICK
                ZLIB_VERSION=${ZLIB_VERSION}
                LIBXML2_VERSION=${LIBXML2_VERSION}
                BZIP2_VERSION=${BZIP2_VERSION}
                GDCM-ABI_VERSION=${GDCM-ABI_VERSION}
                TIFF_VERSION=${TIFF_VERSION}
                JPEG_VERSION=${JPEG_VERSION}
            )
        endif()
    endif()
    
    if (OC_USE_ITK)
        find_package(ITK ${ITK_VERSION} QUIET)
        if (NOT ITK_FOUND)
            set(ITK_FWD_DEPS ZINC)
            addAndConfigureLocalComponent(ITK
                ITK_BUILD_TESTING=OFF
                ITK_BUILD_EXAMPLES=OFF
                ITK_USE_SYSTEM_PNG=ON
                ITK_USE_SYSTEM_TIFF=ON
                ITK_USE_SYSTEM_LIBXML2=ON
                ITK_USE_SYSTEM_ZLIB=ON
                ITK_USE_SYSTEM_GDCM-ABI=OFF
                ITK_USE_KWSTYLE=OFF
                ZLIB_VERSION=${ZLIB_VERSION}
                PNG_VERSION=${PNG_VERSION}
                JPEG_VERSION=${JPEG_VERSION}
                TIFF_VERSION=${TIFF_VERSION}
                LIBXML2_VERSION=${LIBXML2_VERSION}
            )
        endif()
    endif()
    
    if(NOT OC_DEPENDENCIES_ONLY)
        string(REPLACE ";" ${OC_LIST_SEPARATOR} CMAKE_MODULE_PATH_ESC "${CMAKE_MODULE_PATH}")
        set(ZINC_BUILD_TESTS FALSE)
        if(OC_BUILD_ZINC_TESTS OR BUILD_TESTS)
            set(ZINC_BUILD_TESTS TRUE)
        endif()
        set(SUBGROUP_PATH .)
        set(GITHUB_ORGANIZATION OpenCMISS)
        addAndConfigureLocalComponent(ZINC
            ZINC_BUILD_TESTS=${ZINC_BUILD_TESTS}}
            ZINC_BUILD_PYTHON_BINDINGS=${ZINC_WITH_Python_BINDINGS}
            ZINC_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
            ZINC_DEPENDENCIES_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
            GTEST_VERSION=${GTEST_VERSION}
            PYTHON_BINDINGS_INSTALL_DIR=${PYTHON_BINDINGS_INSTALL_DIR}
            PYTHON_BINDINGS_INSTALL_DIR_IS_VIRTUALENV=${OC_PYTHON_BINDINGS_USE_VIRTUALENV}
        )
        if (OC_PYTHON_BINDINGS_USE_VIRTUALENV)
            add_dependencies(${OC_EP_PREFIX}ZINC virtualenv_install)
        endif()
    endif()
endif()

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
