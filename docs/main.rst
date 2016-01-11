:Date: 2016-01-11
:Version: 1.1
:Authors: Daniel Wirtz

.. include:: definitions.rst
  
=================================
CMake OpenCMISS Build Environment
=================================

Specifications and Techdocs for building the OpenCMISS_ Modelling Suite with CMake.

This document specifies the components of the OpenCMISS_ Modelling Suite including Iron,
Zinc, their respective dependencies and (build-)utilities.
The (planned) GitHub repository structure can be found here, and this document explains the layout of
the different components and the overall build process.
The OpenCMISS_ main “logical” components are iron, zinc, examples, dependencies, utilities and documentation.
Those components are managed by the `OpenCMISS manage project`_, which downloads (& manages) the sources,
sets up build trees and according installation directories.

.. toctree::
   :maxdepth: 1
   
   techdocs

----------------------------
Building the OpenCMISS Suite
----------------------------

.. caution::
   If you encounter any troubles, don’t miss the `Build support`_ section!

The base for the installation is a folder called :path:`OPENCMISS_ROOT`.
We’ll use :path:`<manage>` as shorthand to :path:`<OPENCMISS_ROOT>/manage`.

User groups
===========
Shortly, we have two major groups of people using OpenCMISS: Users and Developers.

   Users 
      only use the OpenCMISS components Iron/Zinc but may of course create/develop their own examples.
   
   Developers 
      are people that intend to make changes to the OpenCMISS codebase itself,
      i.e. add functionality to Iron, Zinc or any other component.
      
Consequently, some parts of this documentation apply only to certain user groups.

Prerequisites
=============
In order to build OpenCMISS or any part of it, you need:
   1. A compiler toolchain :code:`(gnu/intel/clang/...)`
   2. A MPI implementation - some are shipped with OpenCMISS and can be automatically built for you.
      If you want a different one, no one holds you back.
   3. [Optional] Git_ version control.
      This is recommended as cloning the repositories makes contributing back easier from the start!
   4. CMake_ 3.3.1 or higher.
   
      - If you are on Linux/Mac and already have an older version installed (higher than 2.6),
        the build procedure will automatically provide a target “cmake” to build the required CMake version and
        prompt you to re-start the configuration with the new binary.
      - On Windows just download the current installer, e.g. http://www.cmake.org/files/v3.3/cmake-3.3.1-win32-x86.exe
      - Only for Linux/Mac without Git_: OpenSSL_.
        This is required to enable CMake to download files via the :code:`https` protocol from GitHub.
        OpenSSL_ will automatically be detected & built into CMake if the setup script triggers
        the build, for own/a-priori cmake builds please use the :cmake:`CMAKE_USE_OPENSSL=YES`
        flag at cmake build configuration time.

Building on Linux
=================

Default steps for Users (terminal/command line)
-----------------------------------------------

   1. Create the :cmake:`OPENCMISS_ROOT` folder somewhere and enter it
   2. Clone the setup git repo into that folder via :sh:`git clone https://github.com/OpenCMISS/manage`.
      Alternatively, if you don't have Git, download and unzip https://github.com/OpenCMISS/manage/archive/v1.1.zip
   3. Enter the :path:`OPENCMISS_ROOT/manage/build` folder
   4. Type :sh:`cmake ..`
   5. *optional* Make changes to the configuration by changing the OpenCMISSLocalConfig_ file
      in the current build directory.
   6. Build the :sh:`opencmiss` target via :sh:`make | nmake | .. opencmiss` (or whatever native build system you have around).
      Multithreading is used automatically, no “-j4” or so needed.
   7. Have a coffee.
   8. Coming back from the coffee and something failed? Checkout the `support section`_.
      
This will compile everything using the default compiler and default mpi.
Basic warnings will be in place for all known erroneous system configurations.
The OpenCMISS-Examples are a competely different package/project and if you want to build them after you’ve
finished building the OpenCMISS libraries please see here.

Default steps for Developers (terminal/command line)
----------------------------------------------------

The default steps are the same as for users, but with two changes:
      1. At step 4, invoke :sh:`cmake -DEVIL=<YES|your_freely_chooseable_evilness_value> ..`
      2. In addition to the changes you can make at step 5, change the 
         OpenCMISSDeveloper_ file according to your OpenCMISS development needs.
         
.. note::
   Ideally, the first step for developers is to fork any components of OpenCMISS that should be worked
   on at GitHub (or to some other git-aware location) and modify the developer config script accordingly
   to have the build system checkout the repos from your own location.
   You can still change repository locations later, however that might require a complete re-build.
   
Building on Windows (64bit) (experimental!)
===========================================

   - Get CMake >= 3.3.1! An issue has been fixed upon request that messed up the FortranInterface verification.
     This is included as of 3.3.1.
   - Get MSYS2!
   
     - Get installer from http://sourceforge.net/projects/msys2/
     - Install (assume here: :path:`C:\MSYS2_64`), dont use spaces in the installation folder!
     - Follow the instructions in Section III to update your version http://sourceforge.net/p/msys2/wiki/MSYS2%20installation 
   - Get MinGW 64!
   
     - Get installer from http://sourceforge.net/projects/mingw-w64/
     - Choose you GCC version and threading model (use posix); the installer automatically suggests a suitable subfolder for your selection so you can have multiple versions in parallel.
     - Install, (assume here: C:\mingw-w64\...)
     - Create a directory junction to include the mingw64-folder into the msys directory tree
   - Open a windows command prompt **IN ADMINISTRATOR MODE**
   
      - Go into C:\MSYS2_64
      - Remove the old :path:`mingw64`-folder (it should only contain an :path:`/etc` folder)
      - Type :sh:`mklink /J mingw64 C:\mingw-w64\<your selection>\mingw64`
      - Windows will confirm e.g. :sh:`Junction created for mingw64 <<===>> C:\mingw-w64\x86_64-4.9.2-posix-seh-rt_v4-rev2\mingw64`
      - If you want to switch to another toolchain version/model later, install mingw-w64 with that
        config and repeat the symlink steps.
   - Get an MPI implementation!
   
     - http://www.mpich.org/downloads for MPICH2
       (unofficial binary packages section, we used 64bit version http://www.mpich.org/static/tarballs/1.4.1p1/mpich2-1.4.1p1-win-x86-64.msi)
     - https://msdn.microsoft.com/en-us/library/bb524831%28v=vs.85%29.aspx for MS MPI
     - Install to a location WITHOUT spaces!
   - Use the :sh:`C:\MSYS2_64\mingw64_shell.bat` to open an mingw64-pathed msys2 console/command
     (all that does is adding mingw64/bin to the path)
   - Install necessary packages: :sh:`pacman -S git make flex bison` (flex/bison for ptscotch builds)
   - Follow the build instructions for linux, with the only change of invoking :sh:`cmake -G “MSYS Makefiles” <args> ..`
 
.. note::
      * Most likely you will need to specify MPI_HOME when running the main build configuration.
      * Get ssh keys if you want to make a development checkout of sources
        (copy the existing id.pub etc into the :path:`~/.ssh` folder (absolute path :path:`C:\MSYS2_64\home\<windows-username>`),
        otherwise find out how to create them and notify github, see https://help.github.com/articles/generating-ssh-keys)
      * MSYS comes with mingw32/64 packages (which must still be installed using packman,
        (i.e. :sh:`pacman -S mingw-w64-x86_64-gcc`), but we found that those packages don’t come with gfortran (yet).
        Thus, use the procedure above.
      * Parmetis builds: get http://sourceforge.net/p/mingw-w64/code/HEAD/tree/experimental/getrusage/ to have
        :path:`resource.h` header (followed source forge link) *or* comment out the line.
        Does not seem to matter (for compilation :-))   
   
Building on Windows (32bit) (experimental!)
===========================================
Its basically the same as for 64 bit, but obviously using the :sh:`msys2` 32bit and :sh:`mingw32`-packages.

.. note::
   The most current version of mingw32 comes with a pthread package, but unfortunately
   there is a severe error (or here) on GNULib’s side:
   The struct “timespec” is also defined for mingw32 versions and conflicts whenever :path:`unistd.h` is also included.
   Either apply the patch or simply uncomment the struct definition in :path:`<mingw32-root>\include\pthread.h:320`.   

Building on OS X 10.10
======================
For building OpenCMISS-Iron on OS X install the following prerequisites
   * CMake >= version 3.2.0
   * From CMake GUI install for command line use in the Tools menu 
   * XCode from the AppStore
   * From XCode install the command line utilities
   * Install Homebrew
   * Using :sh:`brew install gfortran` with openmp support using the :sh:`--without-mutlilib` flag

Available build targets
=======================
Just building :sh:`all` is not enough for OpenCMISS, as the install step is
important to create the information about the OpenCMISS build that is needed by any examples or applications.
Therefore, the build system’s main target is called :sh:`opencmiss` and should be invoked for any build.

   :opencmiss: Main build target. Comprises :sh:`all, install, featuretests`
   :update: Goes through all OpenCMISS_ components that are locally build and fetches
      the newest commit on the configured version branches.
   :support: See the `support section`_.
   :gitstatus: This target is intended for developers, who would like a quick way of
      obtaining the current status of all components that are build locally.
      Only available if Git_ is found.
   :featuretests: Builds and runs the featuretests. These are selected OpenCMISS_ examples that cover the parts of
      OpenCMISS that are used most frequently but are yet fast to run. These tests are run after every build in order
      to provide a fast first test suite to assess overall health.
   :test: Run all the tests for all current components. Lengthy!
   :examples: Convenience target to download & build all the examples registered
      as submodule of the :path:`OpenCMISS-Examples/examples` repository.
   :examples-test: Uses CTest to simply execute all the examples (if successfully built).
      Currently they’re invoked without arguments which may break some of them due to that.
   :reset: Removes everything from the current build root but the OpenCMISSLocalConfig_ file.
      Also invokes the following (independently usable) targets:
   :reset_featuretests: Triggers a re-build of the feature tests
   :reset_mpionly: Blows away all the build and install data of components with MPI capabilities. 
   :utter_destruction: Removes the complete build/ and install/ root directories created by any architecture build.

Component-level build targets
-----------------------------
Besides the top-level targets, each OpenCMISS_ component also provides targets
for direct invocation. In the following, *<compname>* stands for any OpenCMISS component (lowercase).

   :<compname>: Trigger the build for the specified component, e.g. :sh:`make iron`
   :<compname>-clean: Invoke the classical :sh:`clean` target for the specified component and
      triggers a re-run of CMake for that component.
   :<compname>-update: Update the sources for the specified component.
      Please note that you should ALWAYS use the top level :sh:`make update` command to ensure
      fetching a compatible set of components - single component updates are for experienced users only.
   :<compname>-gitstatus: Get a current git status report. Only available if Git is used.
   :<compname>-test: Run any tests provided by the component.

.. _`support section`:

Build support
=============
A word! Having a smoothly working build is what we aim to provide for you.
Yet, facing all those different systems, there are still situations where stuff goes woo.
In order to help you out as good and fast as possible we implemented a build report system for support.
The report system is realized via a :sh:`support` target that can be built (e.g. :sh:`make support`).
This will collect build information and create a zip file, which you can attach to any support email.
Nice, heh?

.. _`build and install all the different configurations`:
.. _`toolchain and MPI type`:

Building for multiple architectures/configurations
==================================================
If you want to compile OpenCMISS using different compilers, MPI implementations etc.,
the build environment is aware of most common “architecture” choices and automatically
places builds in appropriate architecture paths.
Most importantly:

   * All architecture choices **except** toolchain and MPI configuration can be made
     inside the OpenCMISSLocalConfig_. Toolchain and MPI setup are explained below.
     See also the main :path:`CMakeLists.txt` file.
   * You need a different base binary directory for each intended toolchain/mpi combination!
     The build instructions above are laid out by default for only one (=the default) toolchain and mpi choice.
     The name and place of the different binary directories are up to you, however, we recommend 
     to put them inside the :path:`<OPENCMISS_ROOT>/manage` directory to get simple :sh:`cmake ..`-style
     invocations without lengthy relative source directory paths.
     If you decide to put them somewhere else (e.g. :path:`<OPENCMISS_ROOT>/build/my_toolchain_mpi_combo`),
     you will need to invoke cmake at that location and pass an absolute or relative
     path to :path:`<OPENCMISS_ROOT>/manage` as argument.
      
Example directory layout and cmake invocation::

   <OPENCMISS_ROOT>/manage/
      build/
      >> cmake -DTOOLCHAIN=GNU -DMPI=mpich ..
      build_intel/
      >> cmake -DTOOLCHAIN=intel -DMPI=intel ..

.. caution::
   As the sources for one OpenCMISS installation are the same for each different architecture build,
   you cannot have two different source versions (e.g. branches) for any component for two or
   more different architectures.
   For example, you cannot have the current release version of IRON within a build using
   Intel MPI and the devel version of IRON with OpenMPI.
   To solve this, you need two different OpenCMISS root installations.

Toolchain/compiler choice
-------------------------
With CMake and a “normal” toolchain setup, one shouldn’t have to change any compilers
as CMake finds the default ones and uses them.
However, if for some reason your default compiler setup is messed up or you need
a specific compiler, there are two ways to change them:

   1. Define the :var:`TOOLCHAIN` variable on the command line via :sh:`-DTOOLCHAIN=[GNU|Intel|IBM]`
      or specify the corresponding quantities in your CMake GUI application.
      The values listed are currently supported and the build system has some included
      logic to locate and find the correct toolchain compilers.
   2. Specify the desired compilers for any language explicitly using the :cmake:`CMAKE_<lang>_COMPILER` variables.
      See the :path:`<manage>/CMakeScripts/OCToolchainCompilers.cmake` file for more background on option one.

MPI
---
MPI is a crucial dependency to OpenCMISS and is required by many components, especially Iron.
By default, CMake looks and detects the system’s default MPI (if present) and configures the build system to use that.

If you want a specific MPI version, there are several ways to achieve that:
   - Use the :var:`MPI` variable and set it to one of the values :sh:`[mpich, mpich2, openmpi, intel, mvapich2, msmpi]`,
     e.g. :sh:`cmake -DMPI=mpich`.
     The build system is aware of those implementations and tries to find according compiler
     wrappers at pre-guessed locations.
   - If you want the build environment to build the specified MPI for you, set :var:`SYSTEM_MPI` to :cmake:`NO`
     and let the build system download and compile the specified implementation.
     
     .. note::
      Note that this is only possible for selected implementations and environments that use
      GNU makefiles, as most MPI implementations are not “cmakeified” yet.
   - Set the :var:`MPI_HOME` variable to the root folder of your MPI installation.
     CMake will then exclusively look there and try to figure the rest by itself.
   - Specify the compiler wrappers directly by providing :cmake:`MPI_<LANG>_COMPILER`,
     which should ideally be an absolute path or at least the binary name.
     Possible values for <LANG> are C,CXX and Fortran (case sensitive!).
      
At a later stage, the option :cmake:`MPI=none` is planned to build a sequential version of opencmiss.
   
Building OpenCMISS examples (Unix/terminal)
===========================================
The instructions here are for building a single example.
For developers/testers, see the instructions for building all examples.

Building an example requires some effort in order to have compatible settings to your OpenCMISS installation.
Luckily, the OpenCMISS build system can manage that for you.
But this, in turn, means that a local OpenCMISS installation (=manage repository)
is always required, even if you want to use a remote installation and only build examples yourself.
So, make sure you have that first, as it will look for (and possibly build) at least a local MPI implementation.

Essentially, all that is required is to specify the :var:`OPENCMISS_INSTALL_DIR` variable:

   1. Download the desired example from PMR or GitHub.
      (*Transition phase only*: Clone the https://github.com/OpenCMISS-Examples/examples repository
      and navigate to the folder of your desired example)
   2. Create a build folder within the example source, e.g. :path:`build` and change to it
   3. Invoke :sh:`cmake -DOPENCMISS_INSTALL_DIR=<OPENCMISS_ROOT>/install ..`
   4. Invoke :sh:`make install`
   
Now you should have a binary :path:`./run` in your example source that can be executed.
   
.. _`remote installations`:
   
OpenCMISS remote installations
==============================
If an entire work group uses OpenCMISS, it is desireable to have a pre-compiled set of
OpenCMISS libraries and dependencies at a central location on the network.
While this can save a lot of disk space and reduce maintenance efforts, good
care needs to be taken to find and use a matching set of libraries depending on
your local architecture, compiler and MPI versions.
The OpenCMISS build system tries to find those matches automatically by using an architecture path.

User instructions (=”Client-side”)
----------------------------------
Specify the :var:`OPENCMISS_REMOTE_INSTALL_DIR` in the OpenCMISSLocalConfig_ file or add
:sh:`-DOPENCMISS_REMOTE_INSTALL_DIR=[..]` to your initial build arguments.
The build system will then automatically search for a matching OpenCMISS installation at that remote directory.
The above procedure is recommended as it will use an architecture path to find compatible installations.

If that fails for some reason and you need to override that mechanism,
specify :var:`OPENCMISS_REMOTE_INSTALL_DIR_FORCE` instead and have it point
to the mpi-dependent architecture sub-path of the remote installation which contains the :path:`context.cmake` file.

Developer instructions (=”Server-side”)
---------------------------------------
To set up a remote OpenCMISS installation, at first setup the OpenCMISSDeveloper_ file and
enable the (in this case mandatory) :var:`OC_USE_ARCHITECTURE_PATH` setting.
Please also make sure to fill in your eMail address into :var:`OC_INSTALL_SUPPORT_EMAIL`.
Next, `build and install all the different configurations`_ that you want to provide for the consuming clients.
Finally, publish the installation root directory :path:`OPENCMISS_ROOT/install` (check for different mount paths!)
to anyone wanting to use the remote installation.
   
Build customization
===================
OpenCMISS comes with a default build behaviour that is intended be sufficient for most cases of api-users. However, if you need to make (well-informed!) changes to the default build configuration, here is what we offer.
Attention: Due to the way CMake is designed, one cannot change the compiler once the configuration phase is run (without a big fuss or deleting the directory contents). Moreover, changing the MPI implementation turned out to be very error-prone as well. Hence, we decided to exclude those settings from those you can “easily” change. See here for information on toolchain/mpi configuration.

Common Options
--------------
All the OpenCMISS_ options and their defaults are currently listed `in a separate document`_.

.. _`in a separate document`: http://drive.google.com/open?id=102FpkxhHzpG1YWel20aqDdjd-l__jykfQ5KT7p8Se28

.. _`local config file`:
.. _OpenCMISSLocalConfig:

The OpenCMISSLocalConfig.cmake file
-----------------------------------
Everything but the `toolchain and MPI type`_ can be configured in config files.
The OpenCMISS default configuration is set by the :path:`<manage>/Config/OpenCMISSDefaultConfig.cmake` file.
Any value defined there can be overridden by re-definition in the local configuration files,
which are the central point to change the build behaviour or add/remove components.

The template file can be found at :path:`<manage>/Config/OpenCMISSLocalConfig.template.cmake`.
This template will be automatically processed and copied into your current build binary directory
(if not already existing - default:  :path:`<manage>/build`), where it will be read and processed
by the main CMake script.

*Yes, you have a possibly different local configuration file for each toolchain/mpi combination!*

Build precisions
''''''''''''''''
The flags :cmake:`sdcz` are available to be set in the :var:`BUILD_PRECISIONS` variable.
It is initialized as cache variable wherever suitable.

.. note::
   Currently LAPACK/BLAS is always built using dz minimum, as suitesparse has test
   code that only compiles against both versions (very integrated code).
   SCALAPACK is always built with s minimum.

OpenMP
''''''
The build environment uses the variable :var:`OC_MULTITHREADING` to control if “local” multithreading
should be enabled/used.
Thus far only OpenMP is implemented in the build system (and not for every component),
so this controls the :var:`WITH_OPENMP` flag being passed to any dependencies that can make use of it.
If used, the architecture path will also contain an extra segment “mt” between MPI and toolchain parts.

Single component configuration
''''''''''''''''''''''''''''''
A central concept of the build system is a component.
A list of all components known to the setup process can be found in :path:`<manage>/Config/Variables.cmake`
or :var:`OPENCMISS_COMPONENTS`.
We will abbreviate a placeholder for a component by :cmake:`<COMPNAME>` in the following.

   * To enable/disable the use of a component in OpenCMISS, use the :cmake:`OC_USE_<COMPNAME>` variable.
     This will, however, only disable the build of the component and does not check for violation of interdependencies.
   * To specify a certain version of a component, use the :var:`<COMPNAME>_VERSION` variable.
     See the default configuration file :path:`<manage>/Config/OpenCMISSDefaultConfig.cmake` 
     for a set of interoperable versions of all components.
   * Component interconnections are realized via variables like :var:`SUPERLU_DIST_WITH_PARMETIS`.
     For a list of all possible component connections see the :path:`<manage>/Config/OpenCMISSDefaultConfig.cmake` file.
     Those default settings can be overwritten by re-definition in the `local config file`_.
      
Testing
'''''''
For testing, the variable :var:`BUILD_TESTS` can be set and is turned on by default for each dependency.

Use of local system components
------------------------------
Many libraries are also available via the default operating system package managers or
downloadable as precompiled binaries.
OpenCMISS allows to use those packages, however, the default policy is to download &
build every required/selected package from our repositories as they are known to be compatible
with any other OpenCMISS component at any published version of the setup script.
To allow the local search for a component, set the :var:`OC_SYSTEM_<COMPNAME>` flag to :cmake:`YES`
in the `local config file`_.
Note that the search scripts for local packages (CMake: :cmake:`find_package` command and 
:path:`Find<COMPNAME>.cmake` scripts) are partially unreliable;
cmake is improving them continuously and we also try to keep our own written ones
up-to-date and working on many platforms.
This is another reason why the default policy is to rather build our own packages than
tediously looking for binaries that might not even have the right version and/or components.

Package version management
--------------------------
OpenCMISS uses `Git`_ and version-number named branches to maintain
consistency and interoperability throughout all components.
Each dependency as well as Iron and Zinc has branches like “v3.5.0”,
and the OpenCMISSDefaultConfig.cmake file contains the respective version numbers “3.5.0”
[that will/can also be used to look for local versions].
Those quantities are not intended to be changed by api-users, but might be subject to changes
for development tests.
Assuming the existence of the respective branches on GitHub, all that needs to be done to
change a package version is to set the version number accordingly.
The setup will then checkout the specified version and attempt to build and link with it.

.. caution::
   Having a consistent set of interoperable packages (especially dependencies) is a nontrivial
   task considering the amount of components, so be aware that hasty changes will most likely break the build!

.. _OpenCMISSDeveloper:

The OpenCMISSDevelopers.cmake configuration file
------------------------------------------------
As OpenCMISS-Developers will mainly work only on a selection of components, the configuration
file is intended to tell the build system which those components are and have the setup checkout
the correct git repos instead of downloading plain sources.
At first, a flag :var:`<COMPNAME>_DEVEL` must be set in order to notify the setup that
this component (Iron, Zinc, any dependency) should be under development.
As we recommend OpenCMISS development via GitHub forks, we recommend to set the
variable :var:`GITHUB_USERNAME`.
If so, the setup will automatically compute the repositories location
(assuming you wont change the forked repos names) and that’s it.
If you have an SSL Key registered on GitHub for your local machine, set :var:`GITHUB_USE_SSL` to :cmake:`YES`
to have the setup clone via SSL instead of HTTPS.

Alternatively, for every component there is a pair of variables :var:`<COMPNAME>_REPO`
and :var:`<COMPNAME>_BRANCH` which can be set to any value.
The setup will then clone the repositories from there and switch to the specified branch.
If no :var:`<COMPNAME>_REPO` or :var:`GITHUB_USERNAME` is given, the setup chooses the default
public locations at the respective GitHub organizations (OpenCMISS, OpenCMISS-Dependencies etc).
If no :var:`<COMPNAME>_BRANCH` is given, the setup automatically derives the branch name
from the :var:`<COMPNAME>_VERSION` (pattern :cmake:`v<COMPNAME>_VERSION`).
   
---
FAQ
---

*Why do you have different folder structures for debug/release builds?*

By design, users/developers should be able to build a debug version of their example or even
iron while having optimized MPI and dependencies.
In order to ensure to have CMake find the correct builds, separate directories are employed.
Moreover, while the new cmake package config file system allows to store library information
for multiple configurations, different include directories are not yet natively supported.
As some packages provide fortran module files (which are different for debug/release),
they need to be stored at different paths using different include directories.

*How do i use precompiled dependencies like in the old build system?*

See the `remote installations`_ section.

---------------
Troubleshooting
---------------
This section is intended to be used as first place of collection for common errors and mishaps

   Im getting errors from CMake claiming “You have changed variables that require your cache to be deleted [...]
   The following variables have changed: CMAKE_C_COMPILER=/usr/bin/gcc (or similar)*
   
One case where this occurs is if you try to configure an OpenCMISS build using the same compiler but different aliases/symlinks like “gcc” or “cc”, where “cc” just is the system’s default compiler pointing to e.g. “gcc”. Assume your first configure run was just cmake .., and later you’ve decided to re-configure using cmake -DTOOLCHAIN=GNU ... Now, if selecting GNU as toolchain effectively selects the same compiler, but the binary path is different, CMake (correctly) assumes you’ve got a new compiler and needs to delete the cache. The trouble comes in as the build environment (correctly) detects that your default compiler in fact was from the GNU toolchain and hence placed the builds for the external projects under the same architecture path - boom.

*Solution*: Run make reset in the current architecture main build directory and re-build using make.

   MPI detection mismatch. Aborting.
   
This occurs when the automatic MPI detection/selection system fails.
A known case is e.g. if you have GNU/Intel toolchains with mpich/intel mpi installed,
and there is a mpigcc wrapper within the intel MPI path, but the mpich gcc wrapper is simply called mpicc.

*Solution*: Instead of choosing the :var:`MPI` value, specify the :var:`MPI_HOME` directly.

   Could not find a package configuration file provided by "OpenCMISS" with any of the
   following names / opencmiss-config.cmake is missing

Two scenarios commonly happen here:

   1. For remote installations: You specified an incorrect remote directory - see `remote installations`_ section.
   2. The :sh:`install` target was not run. This most commonly occurs if you did not build the :sh:`opencmiss` target.
   
*Solution*: Run the :sh:`install` target, which installs the :path:`opencmiss-config.cmake` files.
Then, your example / application can use that to find your opencmiss installation.
As the :sh:`install` target is a part of the :sh:`opencmiss` target, we recommend building :sh:`opencmiss`
from the start as described in `Building the OpenCMISS Suite`_.
  
.. _Git: http://git-scm.com/downloads
.. _CMake: http://www.cmake.org/download
.. _OpenSSL: https://www.openssl.org/
.. _`OpenCMISS manage project`: https://github.com/OpenCMISS/manage
