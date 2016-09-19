###############################
# OpenCMISS local configuration
###############################
#
# This file can be used to change the build parameters and component settings and
# is created for each choice of toolchain and MPI.
#
# For a complete description of all options, refer to
# 
# http://opencmiss.org/documentation/cmake/docs/config
# 
# or the <manage>/Config/OpenCMISSDefaultConfig.cmake script.
#
# The exemplatory values used in this file are initialized to already 
# be the opposite of the default values, if applicable.

######################
# SDK INSTALLATIONS
######################
#set(OPENCMISS_SDK_INSTALL_DIR ~/software/opencmiss/install)
#set(OPENCMISS_SDK_INSTALL_DIR_FORCE ~/software/opencmiss/install/x86_64_linux/gnu-4.8.4/openmpi_release/static/release)

##################
# GENERAL SETTINGS
##################

#set(OC_CREATE_LOGS NO)
#set(OC_CONFIG_LOG_TO_SCREEN YES)
#set(OPENCMISS_INSTALL_ROOT "${OPENCMISS_ROOT}/install")
#set(BUILD_PRECISION sdcz)
#set(INT_TYPE int64)
#set(BUILD_TESTS OFF)
#set(PARALLEL_BUILDS OFF)
#set(BLA_VENDOR Intel10_64lp)
#set(DISABLE_GIT YES)
#set(OC_USE_ARCHITECTURE_PATH NO)
#set(OC_PYTHON_BINDINGS_USE_VIRTUALENV YES)

###############
# BUILD CONTROL
###############
#set(BUILD_SHARED_LIBS YES)
#set(CMAKE_BUILD_TYPE DEBUG)
#set(MPI_BUILD_TYPE DEBUG)
#set(OC_WARN_ALL NO)
#set(OC_CHECK_ALL NO)
#set(OC_MULTITHREADING ON)

#########################
# COMPONENT CONFIGURATION
#########################
#set(IRON_SHARED NO)
#set(ZINC_SHARED NO)
#set(OC_DEPENDENCIES_ONLY YES)
#set(OC_COMPONENTS_SYSTEM NONE)
#set(OC_WITH_DIAGNOSTICS NO)
#set(OC_BUILD_ZINC_TESTS YES)

${OC_USE_SYSTEM_FLAGS}

${OC_USE_FLAGS}

#######################
# COMPONENT INTERACTION
#######################
#set(CELLML_USE_CSIM YES)

#set(MUMPS_WITH_SCOTCH YES)
#set(MUMPS_WITH_PTSCOTCH NO)
#set(MUMPS_WITH_METIS YES)
#set(MUMPS_WITH_PARMETIS NO)

#set(SUNDIALS_WITH_LAPACK NO)

#set(SCOTCH_USE_THREADS NO)
#set(SCOTCH_WITH_ZLIB NO)
#set(SCOTCH_WITH_BZIP2 NO)

#set(SUPERLU_DIST_WITH_PARMETIS NO)

#set(PASTIX_USE_THREADS NO)
#set(PASTIX_USE_METIS NO)
#set(PASTIX_USE_PTSCOTCH NO)

#set(HDF5_WITH_MPI YES)
#set(HDF5_WITH_SZIP NO)
#set(HDF5_WITH_ZLIB NO)

#set(FIELDML-API_WITH_HDF5 NO)
#set(FIELDML-API_WITH_JAVA_BINDINGS NO)
#set(FIELDML-API_WITH_FORTRAN_BINDINGS NO)

#set(IRON_WITH_CELLML NO)
#set(IRON_WITH_FIELDML NO)
#set(IRON_WITH_HYPRE NO)
#set(IRON_WITH_SUNDIALS NO)
#set(IRON_WITH_MUMPS NO)
#set(IRON_WITH_SCALAPACK NO)
#set(IRON_WITH_PETSC NO)
#set(IRON_WITH_C_BINDINGS NO)
#set(IRON_WITH_Python_BINDINGS NO)

#set(ZINC_WITH_Python_BINDINGS NO)

#set(LIBXML2_WITH_ZLIB NO)
