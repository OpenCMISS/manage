# Uncomment if you dont want to use architecture paths.
#set(OC_USE_ARCHITECTURE_PATH NO)

# Set this to YES to build with the -p profiling flags.
set(OC_PROFILING NO)

# Override any local variable and have CMake download/checkout the "devel" branch of any components repository
#set(OC_DEVEL_ALL YES)

# If you issue "make clean" from the manage build folder, normally the external projects (i.e. dependencies) wont completely re-build.
# Set this to true to have the build system remove the CMakeCache.txt of each dependency, which triggers a complete re-build. 
set(OC_CLEAN_REBUILDS_COMPONENTS YES)

# The default for developers is to directly print the build output to the standard output/terminal.
# This way developers directly see any errors instead of having to open log files.
set(OC_CREATE_LOGS NO)

# If you want more verbose output during builds, uncomment this line.
#set(CMAKE_VERBOSE_MAKEFILE ON)

# The levels of log entries written to the config build log.
# This is the same as for normal users but also contains the DEBUG entries
# More values are: VERBOSE
set(OC_CONFIG_LOG_LEVELS SCREEN WARNING ERROR DEBUG)

# For developers, all non SCREEN-level logs are also printed on the console by default.
#set(OC_CONFIG_LOG_TO_SCREEN YES)

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
# Disable use of Git to obtain sources.
# The build systems automatically looks for Git and uses that to clone the respective source repositories
# If Git is not found, a the build system falls back to download .zip files of the source.
# To enforce that behaviour (e.g. for nightly tests), set this to YES
#set(DISABLE_GIT YES)

# If you set a github username, cmake will automatically try and locate all the components as repositories under that github account.
#set(GITHUB_USERNAME )

# If enabled, ssl connections like git@github.com/username are used instead of https access.
# Requires public key registration with github but wont require to enter the password (for push) every time. 
#set(GITHUB_USE_SSL YES)

# To specify your own repository locations on a per-component basis, use
#set(<COMPONENT_NAME>_REPO https://github.com/myacc/defunct)

# Unless you want to checkout the default branch, set this to use your own
#set(<COMPONENT_NAME>_BRANCH mybranch)


