#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)
#SET(BUILD_SHARED_LIBS YES)

# ==============================
# Misc
# ==============================
# If you want more verbose output during builds, uncomment this line.
#SET(CMAKE_VERBOSE_MAKEFILE ON)

###########################################################################
# Component configuration
###########################################################################
# This is the value initially specified at the top level. 
SET(OCM_SYSTEM_MPI @OCM_SYSTEM_MPI@)

# Allow all components to be searched for on the local system first.
# In default config, this holds only for BLAS/LAPACK/MPI
#SET(OCM_SYSTEM_ALL YES)

# To enable local lookup of single components, set
# OCM_SYSTEM_<COMPONENT_NAME> to YES
${OCM_USE_SYSTEM_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}