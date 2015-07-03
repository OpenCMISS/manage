#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)
#SET(BUILD_SHARED_LIBS YES)
#set(CMAKE_BUILD_TYPE DEBUG)

# If you have a remote installation of opencmiss components 
# (e.g. you are using OpenCMISS in a shared network environment
# specify the installation directory here.
# This will have the build environment search for opencmiss components there.
#set(OPENCMISS_DEPENDENCIES_DIR )
# e.g.
#set(OPENCMISS_DEPENDENCIES_DIR ~/software/opencmiss/install/x86_64_linux/gnu-4.8.4/openmpi_release/static/release)

# Alternatively, if you are using architecture paths, you can just specify the root "install" folder
# of the dependencies, and the build system will automatically look for dependencies at the matching architecture subpaths. 
#set(OPENCMISS_DEPENDENCIES_ROOT )
#set(OPENCMISS_DEPENDENCIES_ROOT ~/software/opencmiss/install)

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