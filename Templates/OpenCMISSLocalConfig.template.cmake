#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)
#SET(BUILD_SHARED_LIBS YES)
#set(CMAKE_BUILD_TYPE DEBUG)

# Define a BLAS library vendor here.
# This is consumed by the FindBLAS package, see its documentation for all possible values.
#set(BLA_VENDOR Intel10_64lp)

# ==============================
# Misc
# ==============================
# If you want more verbose output during builds, uncomment this line.
#SET(CMAKE_VERBOSE_MAKEFILE ON)

###########################################################################
# Component configuration
###########################################################################
# This is the value initially specified at the top level. 

# Allow all components to be searched for on the local system first.
# In default config, this holds only for the components specified in OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT (Config/Variables.cmake)
#SET(OCM_SYSTEM_ALL YES)

# To enable local lookup of single components, set
# OCM_SYSTEM_<COMPONENT_NAME> to YES
${OCM_USE_SYSTEM_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}