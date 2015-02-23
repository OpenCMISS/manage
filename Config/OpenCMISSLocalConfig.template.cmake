#SET(BUILD_PRECISION sdcz)
#SET(INT_TYPE int32)
#SET(BUILD_TESTS ON)
#SET(BUILD_SHARED_LIBS YES)

# ==============================
# Compiler
# ==============================
# Usually you dont need to tell CMake which compilers to use.
# If you change compilers here, YOU SHOULD KNOW WHY!!!
# If by some chance you have to, first try to specify your desired toolchain via
#SET(TOOLCHAIN GNU)
#SET(TOOLCHAIN Intel)
#SET(TOOLCHAIN IBM)

# If still not functional, you can specify each compiler using the CMAKE_<lang>_COMPILER variables,
# where <lang> can be each of "C","CXX" or "Fortran".
# For example, to have CMake use the GNU C compiler, set the binary name via 
#SET(CMAKE_C_COMPILER gcc)
# If that can not be found on CMake's PATH, you should specify an absolute path to the binary like
#SET(CMAKE_C_COMPILER /usr/local/mygcc/bin/gcc)

# If you still fail to have CMake successfully configure OpenCMISS with non-default compilers, please contact the OpenCMISS Team.

# ==============================
# MPI
# ==============================
# Global switch for enabling/disabling MPI. [No-MPI case not yet implemented!]
#SET(OCM_USE_MPI NO)

# By default, the default/only MPI on the local machine is looked for and used if compatible.
# To have the manage system also build MPI, uncomment the following line. 
#SET(OCM_SYSTEM_MPI NO)

# Choose your MPI type my mnemonic
# If you change those variables, YOU SHOULD KNOW WHY!!!!
#SET(MPI mpich)
#SET(MPI mpich2)
#SET(MPI openmpi)
#SET(MPI intel)

# - ALTERNATIVELY -
# You can also specify a custom MPI root directory to have CMake look there EXCLUSIVELY.
#SET(MPI_HOME ~/software/openmpi-1.8.3_install)

# - ALTERNATIVELY -
# Further, you can specify an explicit name of the compiler executable (full path or just the binary name)
# This can be used independently of (but possibly with) the MPI_HOME setting.
#SET(MPI_C_COMPILER mpicc)
#SET(MPI_CXX_COMPILER mpic++)
#SET(MPI_Fortran_COMPILER mpif77)

###########################################################################
# Component configuration
###########################################################################

# Allow all components to be searched for on the local system first.
# In default config, this holds only for BLAS/LAPACK/MPI
#SET(OCM_SYSTEM_ALL YES)

# To enable local lookup of single components, set
# OCM_SYSTEM_<COMPONENT_NAME> to YES
# All those who default to system lookup first are initialized here with NO value
${OCM_USE_SYSTEM_FLAGS}

# To disable the use of selected components, uncomment the appropriate lines
# The default is to build all.
${OCM_USE_FLAGS}