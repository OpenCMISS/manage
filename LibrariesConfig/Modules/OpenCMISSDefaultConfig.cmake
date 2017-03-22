##
#
# The default configuration file is located at :path:`<manage>/Config/OpenCMISSDefaultConfig.cmake`
# In order to change any of the subsequently listed variables, specify your values in the :ref:`local config file <localconf>`.
#

##
# BLA_VENDOR
# ----------
#
# Define a BLAS library vendor. This variable is consumed by the FindBLAS/FindLAPACK modules.
# Not specifying anything will perform a generic search. If you have the Intel MKL library, use e.g. *Intel10_64lp*.
#
# .. caution::
#     
#     If you change the BLAS implementation after a previous build has finished, the binaries for the old BLAS version will
#     be overwritten by the ones using the specified BLAS implementation.
#     This could be avoided if the BLAS implementation type was somehow reflected in the :ref:`architecture path <archpaths>`,
#     however, having installations for the same toolchain and compiler but different BLAS libraries is not expected
#     to be necessary. This might change in future versions.
#
# .. cmake-var:: BLA_VENDOR
# .. default:: <empty>
set(BLA_VENDOR )

##
# BUILD_PRECISION
# ---------------
# The flags :cmake:`sdcz` are available to be set in the :cmake:BUILD_PRECISIONS variable.
# It is initialized as cache variable wherever suitable.
# 
# .. note::
#    Currently LAPACK/BLAS is always built using dz minimum, as suitesparse has test
#    code that only compiles against both versions (very integrated code).
#    SCALAPACK is always built with s minimum.
# 
# Valid choices are s,d,c,z and any combinations:
#     :s: Single / float precision
#     :d: Double precision
#     :c: Complex / float precision
#     :z: Complex / double precision
#
# .. default:: sd
set(BUILD_PRECISION sd CACHE STRING "Build precisions for OpenCMISS components. Choose any of [sdcz]")

##
# BUILD_SHARED_LIBS
# -----------------
#
# Enable this flag to build all the components libraries as shared object files (\*.so / \*.dll).
# The default behaviour is to build all the dependencies' libraries as static and only the main components Iron and Zinc
# as shared libraries. 
#
# See also: <COMP>_SHARED_
# 
# .. cmake-var:: BUILD_SHARED_LIBS
# .. default:: NO
option(BUILD_SHARED_LIBS "Build shared libraries within/for every component" NO)

##
# BUILD_TESTS
# -----------
#
# Most OpenCMISS components come with their own test cases and suites. This flag enables all component tests
# to be built along with the components.
#
# This does not mean they're run (which you should do, see :ref:`build targets`)
#
# .. default:: ON
option(BUILD_TESTS "Build OpenCMISS(-components) tests" ON)

##
# OPENCMISS_DEFAULT_BUILD_TYPE
# ----------------------------
#
# For different build types, use this variable.
# Possible values are (in general)
#
#     :Release: Optimised build
#     :Debug: Build including debug information
#     :MinSizeRel: Optimised build for minimal library/binary size
#     :RelWithDebInfo: Optimised build with debug information
#
# .. cmake-var:: OPENCMISS_DEFAULT_BUILD_TYPE
# .. default:: Release
set(OPENCMISS_DEFAULT_BUILD_TYPE Release)

##
# CMAKE_DEBUG_POSTFIX
# -------------------
#
# Specifies a postfix for all libraries when build in :cmake:`CMAKE_BUILD_TYPE=Debug`
#
# .. cmake-var:: CMAKE_DEBUG_POSTFIX
# .. default:: d
set(CMAKE_DEBUG_POSTFIX d CACHE STRING "Debug postfix for library names of DEBUG-builds") # Debug postfix

##
# CMAKE_VERBOSE_MAKEFILE
# ----------------------
#
# .. cmake-var:: CMAKE_VERBOSE_MAKEFILE
# .. default:: NO
option(CMAKE_VERBOSE_MAKEFILE "Generate verbose makefiles/projects for builds" NO)

##
# <COMP>_SHARED
# -------------
#
# This flag determines if the specified component should be build as shared library rather than a static library.
# The default is :cmake:`NO` for all components except Iron and Zinc.
#
# .. default:: NO
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    set(_VALUE OFF)
    if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_SHARED_BY_DEFAULT)
        set(_VALUE ON)
    endif()
    option(${COMPONENT}_SHARED "Build all libraries of ${COMPONENT} as shared" ${_VALUE})
endforeach()

##
# INT_TYPE
# --------
#
# Some packages allow int64 or longint as integer types - this has not been tested for anything but int32
# Used only by PASTIX yet
#
# .. default:: int32
set(INT_TYPE int32 CACHE STRING "OpenCMISS integer type (only used by PASTIX yet)")

##
# OPENCMISS_MPI_BUILD_TYPE
# --------------
#
# For different MPI build types, use this variable.
# Possible values are (in general)
#
#     :Release: Optimised build
#     :Debug: Build including debug information
#     :MinSizeRel: Optimised build for minimal library/binary size
#     :RelWithDebInfo: Optimised build with debug information
#
# .. default:: Release
if (NOT DEFINED OPENCMISS_MPI_BUILD_TYPE)
    set(OPENCMISS_MPI_BUILD_TYPE Release)
endif()

##
# OC_BUILD_ZINC_TESTS
# -------------------
#
# Allow users to build the tests for Zinc in isolation to other 
# testing.
#
# .. default:: NO
option(OC_BUILD_ZINC_TESTS "Build the Zinc tests in isolation" NO)

##
# OC_CHECK_ALL
# ------------
#
# Enable to have maximum compiler checks. Debug builds only.
#
# .. default:: YES
option(OC_CHECK_ALL "Compiler flags choices - all checks on" YES)

##
# OC_COMPONENTS_SYSTEM
# --------------------
#
# Global setting to control use of system components. Possible values:
# 
#     :DEFAULT: Holds only for the components specified in OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT (Config/Variables.cmake)
#     :NONE: The OpenCMISS build system exclusively builds components from its own repositories
#     :ALL: Enable search for any component on the system 
#
# .. default:: DEFAULT
set(OC_COMPONENTS_SYSTEM DEFAULT)

##
# .. _`loglevels`:
#
# OC_CONFIG_LOG_LEVELS
# --------------------
#
# This variable controls the messages generated and written to the configure log files during the CMake configuration phase.
# It is intended for developers and anyone trying to debug the CMake scripts. Possible values are:
#
#    :SCREEN: Also print the log text to the console.
#    :WARNING: Equivalent to issuing :command:`message(WARNING ...)`.
#        However, the warning text will also be put into the log file.
#    :ERROR: Equivalent to issuing :command:`message(FATAL_ERROR ...)`.
#        However, the error text will also be put into the log file.
#    :DEBUG: Any output not intended for production use, but thought useful for debugging purposes.
#    :VERBOSE: Verbose output, thought of as the *maximum verbosity* level.
#
# The build log files are put into the :path:`<CMAKE_CURRENT_BINARY_DIR>/support` folder into a file with the pattern
# :path:`configure_builds_YYYY-MM-DD_hh-mm.log`. The function to write log entries is called :command:`log()`.
#
# .. default:: SCREEN WARNING ERROR
set(OC_CONFIG_LOG_LEVELS SCREEN WARNING ERROR)

##
# OC_CONFIG_LOG_TO_SCREEN
# -----------------------
# 
# Have all non SCREEN-level logs are also printed on the console (helps debugging).
# See also OC_CONFIG_LOG_LEVELS_.
# .. default:: NO
option(OC_CONFIG_LOG_TO_SCREEN "Also print the created log file entries to console output" NO)

##
# OC_CREATE_LOGS
# --------------
#
# Have the build system wrap the builds of component into log files.
# Selecting :cmake:`NO` will directly print the build process to the standard output.
#
# .. default:: YES
option(OC_CREATE_LOGS "Create logfiles instead of direct output to screen" YES)

##
# OC_DEPENDENCIES_ONLY
# --------------------
# 
# If you want to compile the dependencies for iron/zinc only, enable this setting.
# This flag is useful for setting up sdk installations or continuous integration builds.
#
# .. caution::
#     You can also disable building Iron or Zinc using the component variables, e.g. OC_USE_IRON=NO.
#     However, this is considered a special top-level flag, which also causes any components that are
#     exclusively required by e.g. Iron will not be build. 
#
# See also OC_USE_<COMP>_ 
#
# .. default:: NO
option(OC_DEPENDENCIES_ONLY "Build dependencies only (no Iron or Zinc)" NO)

##
# OC_MULTITHREADING
# -----------------
#
# The build environment uses this to control if “local” multithreading should be enabled/used.
# Thus far only OpenMP is implemented in the build system (and not for every component),
# so this controls the :cmake:`WITH_OPENMP` flag being passed to any dependencies that can make use of it.
# If used, the architecture path will also contain an extra segment “mt” between MPI and toolchain parts.
#
# .. default:: NO
option(OC_MULTITHREADING "Use multithreading in OpenCMISS (where applicable)" NO)

##
# OC_PYTHON_BINDINGS_USE_VIRTUALENV
# ---------------------------------
#
# This option allows to use the Python virtual environments to conveniently switch between the different
# bindings created for different compiler/mpi/build configurations.
# 
# The build system will issue an error if this option is turned on and the :sh:`virtualenv` executable can not be
# located.
#
# .. default:: YES if prerequisites are found, NO else
set(_DEF NO)
if (OC_PYTHON_PREREQ_FOUND AND VIRTUALENV_EXECUTABLE)
    set(_DEF YES)
endif()
option(OC_PYTHON_BINDINGS_USE_VIRTUALENV "Use Python virtual environments to install Python bindings" ${_DEF})
unset(_DEF)

##
# OC_SYSTEM_<COMP>
# ----------------
#
# Many libraries are also available via the default operating system package managers or
# downloadable as precompiled binaries.
# This flag determines if the respective component may be searched for on the local machine, i.e. the local environment.
#
# As there are frequent incompatibilities with pre-installed packages due to mismatching versions, these flags can be set 
# to favor own component builds over consumption of local packages.
# 
# The search scripts for local packages (CMake: :cmake:`find_package` command and :path:`Find<COMP>.cmake` scripts)
# are partially unreliable; CMake is improving them continuously and we also try to keep our own written ones
# up-to-date and working on many platforms. This is another reason why the default policy is to
# rather build our own packages than tediously looking for binaries that might not even have the
# right version and/or components.
#
# .. caution::
#     
#    *Applies to setting in OpenCMISSLocalConfig only*: If you decide to enable one of those variables
#    at some stage and later want to disable it, just *commenting* out like :cmake:`#set(OC_SYSTEM_MUMPS YES)` will
#    **not** set its value to :cmake:`NO`, as it is registered as an CMake `option`__. You need to explicitly set the value
#    to :cmake:`NO` to have the desired effect.
#
# .. __: https://cmake.org/cmake/help/v3.3/command/option.html   
#
# See also: OC_COMPONENTS_SYSTEM_ and the :cmake:`OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT` variable in :path:`<manage>/Config/Variables.cmake`.
# 
# .. default:: OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    # Look for some components on the system first before building
    set(_VALUE OFF)
    if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_SYSTEM_BY_DEFAULT)
        set(_VALUE ON)
    endif()
    option(OC_SYSTEM_${COMPONENT} "Allow ${COMPONENT} to be used from local environment/system" ${_VALUE})
    unset(_VALUE)
endforeach()

##
# OC_USE_<COMP>
# -------------
#
# For every OpenCMISS component, this flag determines if the respective component is to be used by the build environment.
# This means it's searched for at configuration stage and built if not found.
#
# The list of possible components can be found in the :cmake:`OPENCMISS_COMPONENTS` variable in :path:`<manage>/Config/Variables.cmake`.
#
# .. caution::
#    There is no advanced logic implemented to check if a custom selection of components breaks the overall build - e.g.
#    if you disable OC_USE_LIBXML2 and there is no LibXML2 installed on your system, other components requiring LIBXML2 will
#    not build correctly.
#
# See also OC_SYSTEM_<COMP>_ and the :cmake:`OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT` variable in :path:`<manage>/Config/Variables.cmake`.
foreach(COMPONENT ${OPENCMISS_COMPONENTS})
    set(_VALUE ON)
    if (${COMPONENT} IN_LIST OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT)
        set(_VALUE OFF)
    endif()
    # Use everything but the components in OPENCMISS_COMPONENTS_DISABLED_BY_DEFAULT
    option(OC_USE_${COMPONENT} "Enable use/build of ${COMPONENT}" ${_VALUE})
    unset(_VALUE)
endforeach()

##
# OC_WARN_ALL
# -----------
#
# Enable to have maximum compiler warnings. Debug builds only.
#
# .. default:: YES
option(OC_WARN_ALL "Compiler flags choices - all warnings on" YES)

##
# .. _`sdk_install_dir_var`:
#
# OPENCMISS_SDK_INSTALL_DIR
# ----------------------------
#
# If you have a remote installation of opencmiss components, (e.g. you are using OpenCMISS in a shared network environment)
# specify the installation directory here.
# This will have the build environment search for opencmiss components at that location.
#
# .. note::
#
#     There are alternate ways to specify the remote install directory.
#         - Set OPENCMISS_SDK_INSTALL_DIR in your system environment to have the
#           build system use that automatically.
#         - Specify :sh:`-DOPENCMISS_SDK_INSTALL_DIR` at the main build,
#           it will cache the variable and insert it into this file automatically.
# 
# .. caution::
#
#     You do NOT have to specify the full architecture-path dependend installation directory.
#     OpenCMISS will try to find a matching subpath for your local compiler and mpi settings and issue a warning
#     if no matching installation can be found.
#
# .. default:: <empty>
set(OPENCMISS_SDK_INSTALL_DIR )

##
# .. _`sdk_install_dir_force_var`:
#
# OPENCMISS_SDK_INSTALL_DIR_FORCE
# ----------------------------------
#
# If using OPENCMISS_SDK_INSTALL_DIR_ fails and you are sure that the remote installation is compatible, you can
# also directly specify the remote directory containing the "context.cmake" file in this variable.
#
# For example, this could be useful if you wanted to compile an example using a different toolchain than that used to compile
# the OpenCMISS libraries. *This is intended for developers only and has not been thoroughly tested*.  
# 
# .. default:: <empty>
set(OPENCMISS_SDK_INSTALL_DIR_FORCE )

##
# PARALLEL_BUILDS
# ---------------
# 
# Enable this flag to have the build system automatically use multithreaded builds
#
# .. default:: ON
option(PARALLEL_BUILDS "Use multithreading (-jN etc) for builds" ON)
