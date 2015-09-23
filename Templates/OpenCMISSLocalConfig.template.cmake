#####################################################################
# This is the local config file that you can use to change the
# build parameters and component settings.
# This file is created for each choice of toolchain and MPI.
#
# See the <OPENCMISS_ROOT>/manage/Config/OpenCMISSDefaultConfig.cmake
# script for all other defaults.
# The exemplatory values used in this file are initialized to already
# be the opposite of the value in the default config file
# above (if applicable) 
#####################################################################

####################################################################
################# GENERAL SETTINGS
####################################################################

# Have the build system wrap the builds of component into log files.
# Selecting NO will directly print the build process to the standard output.
#set(OC_CREATE_LOGS NO)

# Set the installation directory for OpenCMISS.
# You can use the variable OPENCMISS_ROOT.
#set(OPENCMISS_INSTALL_ROOT "${OPENCMISS_ROOT}/install")

# Precision to build (if applicable)
# Valid choices are s,d,c,z and any combinations.
# s: Single / float precision
# d: Double precision
# c: Complex / float precision
# z: Complex / double precision
#set(BUILD_PRECISION sdcz)

# Some packages allow int64 or longint - this has not been tested for anything but int32
# Used only by PASTIX yet
#set(INT_TYPE int64)

# Always build the test targets by default.
# This does not mean they're run (which you should do!)
#set(BUILD_TESTS OFF)

# Uncomment this if you don't want parallel builds of OpenCMISS components. 
#set(PARALLEL_BUILDS OFF)

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
# The default is static for all dependencies and shared for main components (iron and zinc)
# If set to yes, every component will be built as shared library.
# See also: IRON_SHARED ZINC_SHARED
#set(BUILD_SHARED_LIBS YES)

# For different build types, use this variable.
# Possible values are (in general): [RELEASE]|DEBUG|MINSIZEREL|RELWITHDEBINFO
#set(CMAKE_BUILD_TYPE DEBUG)

# Set compiler flags for all warnings and checks.
# DEBUG builds only!
#set(OC_WARN_ALL NO)
#set(OC_CHECK_ALL NO)

# Enable multithreaded builds for all components (if applicable)
# Currently the default is to leave every dependency as-is.
# Full support not implemented yet. 
#set(OC_MULTITHREADING ON)


####################################################################
################# COMPONENT CONFIGURATION
####################################################################

# By default, Iron and Zinc are being build shared.
# Uncomment this to have either component built as static library.
#set(IRON_SHARED NO)
#set(ZINC_SHARED NO)

# Global setting to control use of system components. Possible values: [DEFAULT]|NONE|ALL
# DEFAULT: Holds only for the components specified in OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT (Config/Variables.cmake)
# NONE: The OpenCMISS build system exclusively builds components from its own repositories
# ALL: Enable search for any component on the system
# The global system component selection preference. 
#set(OC_COMPONENTS_SYSTEM DEFAULT NONE) 

# To enable local lookup of single components, set
# OCM_SYSTEM_<COMPONENT_NAME> to YES
${OCM_USE_SYSTEM_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}

# Disable build of Python bindings for iron (enabled if Python is found)
#set(IRON_WITH_Python_BINDINGS NO)