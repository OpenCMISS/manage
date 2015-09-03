# We recommend using the architecture path for OpenCMISS developers.
SET(OCM_USE_ARCHITECTURE_PATH YES)

# Set this to YES to build with the -p profiling flags.
set(OCM_WITH_PROFILING NO)

# Override the default setting when being an OpenCMISS-Developer - you of all should build and run tests!
set(BUILD_TESTS ON)

# Override any local variable and have CMake download/checkout the "devel" branch of any components repository
#set(OCM_DEVEL_ALL YES)

# If you issue "make clean" from the manage build folder, normally the external projects (i.e. dependencies) wont completely re-build.
# Set this to true to have the build system remove the CMakeCache.txt of each dependency, which triggers a complete re-build. 
set(OCM_CLEAN_REBUILDS_COMPONENTS YES)

# The default for developers is to directly print the build output to the standard output/terminal.
# This way developers directly see any errors instead of having to open log files.
set(OCM_CREATE_LOGS NO)

##############################################################################################
############################################### Maintainer setup
# Please set this to your email address, especially if you plan to provide several architecture installations and
# expect people to use your installation
#set(OC_INSTALL_SUPPORT_EMAIL "admin@institu.te")

# When installing OpenCMISS, the opencmiss-config file defines a default MPI version.
# If unspecified, this will always be set to the version used for the latest build
#set(OC_DEFAULT_MPI "mpich|openmpi|...")

# When installing OpenCMISS, the opencmiss-config file defines a default MPI build type version.
# If unspecified, this will always be set to the version used for the latest build
#set(OC_DEFAULT_MPI_BUILD_TYPE "RELEASE|DEBUG|...")

##############################################################################################
############################################### Git
# If you have Git on your system, you can further customize where repositories are going to be cloned from. 

# If you set a github username, cmake will automatically try and locate all the components as repositories under that github account.
#set(GITHUB_USERNAME )

# If enabled, ssl connections like git@github.com/username are used instead of https access.
# Requires public key registration with github but wont require to enter the password (for push) every time. 
#set(GITHUB_USE_SSL YES)

# To specify your own repository locations on a per-component basis, use
#set(<COMPONENT_NAME>_REPO https://github.com/myacc/defunct)

# Unless you want to checkout the default branch, set this to use your own
#set(<COMPONENT_NAME>_BRANCH mybranch)


