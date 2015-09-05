####################################################################
################# GENERAL SETTINGS
####################################################################
#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)

# Define a BLAS library vendor here.
# This is consumed by the FindBLAS package, see its documentation for all possible values.
#set(BLA_VENDOR Intel10_64lp)

# Disable use of Git to obtain sources.
# The build systems automatically looks for Git and uses that to clone the respective source repositories
# If Git is not found, a the build system falls back to download .zip files of the source.
# To enforce that behaviour (e.g. for nightly tests), set this to YES
#set(DISABLE_GIT YES)

####################################################################
################# REMOTE INSTALLATIONS
####################################################################
# If you have a remote installation of opencmiss components, 
# (e.g. you are using OpenCMISS in a shared network environment)
# specify the installation directory here.
# This will have the build environment search for opencmiss components at that location.
#set(OPENCMISS_REMOTE_INSTALL_DIR ~/software/opencmiss/install)
# Note:
# There are alternate ways to specify the remote install directory:
# - Set OPENCMISS_REMOTE_INSTALL_DIR in your system environment to have the build system use that automatically.
# - Specify -DOPENCMISS_REMOTE_INSTALL_DIR at the main build already, it will cache the variable and insert it into this
#   file automatically. This will be done for ALL subsequent builds using different toolchains or mpi implementations. 
# Note:
# You do NOT have to specify the full architecture-path dependend installation directory.
# OpenCMISS will try to find a matching subpath for your local compiler and mpi settings and issue a warning
# if no matching installation can be found.

# However, if that fails and you are sure that the remote installation is compatible, you can
# also directly specify the remote directory containing the "context.cmake" file in this variable:
#set(OPENCMISS_REMOTE_INSTALL_DIR_FORCE ~/software/opencmiss/install/x86_64_linux/gnu-4.8.4/openmpi_release/static/release)

####################################################################
################# BUILD CONTROL
####################################################################
# If you want more verbose output during builds, uncomment this line.
#set(CMAKE_VERBOSE_MAKEFILE ON)
# In order to build shared libraries (.so/.dll) set this to YES
#set(BUILD_SHARED_LIBS YES)
# For different build types, use this variable.
# Possible values are (in general): [RELEASE]|DEBUG|MINSIZEREL|RELWITHDEBINFO
#set(CMAKE_BUILD_TYPE DEBUG)


####################################################################
################# COMPONENT CONFIGURATION
####################################################################
# This is the value initially specified at the top level. 

# Global setting to control use of system components. Possible values: [DEFAULT]|NONE|ALL
# DEFAULT: Holds only for the components specified in OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT (Config/Variables.cmake)
# NONE: No system components may be used
# ALL: Enable search for any component on the system 
#set(OCM_COMPONENTS_SYSTEM DEFAULT) 

# To enable local lookup of single components, set
# OCM_SYSTEM_<COMPONENT_NAME> to YES
${OCM_USE_SYSTEM_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}