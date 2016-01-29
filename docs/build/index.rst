.. _`build opencmiss`:

----------------------------
Building the OpenCMISS Suite
----------------------------

.. note::
   If you encounter any troubles, don’t miss reading the :ref:`build support` section!

The base for the installation is a folder called :path:`OPENCMISS_ROOT`.
We’ll use :path:`<manage>` as shorthand to :path:`<OPENCMISS_ROOT>/manage`.

We have two major groups of people using OpenCMISS:

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
   4. CMake_ 3.3.2 or higher.
   
      - If you are on Linux/Mac and already have an older version installed (higher than 2.6),
        the build procedure will automatically provide a target “cmake” to build the required CMake version and
        prompt you to re-start the configuration with the new binary.
      - On Windows just download the current installer, e.g. http://www.cmake.org/files/v3.3/cmake-3.3.2-win32-x86.exe
      - Only for Linux/Mac without Git_: OpenSSL_.
        This is required to enable CMake to download files via the :code:`https` protocol from GitHub.
        OpenSSL_ will automatically be detected & built into CMake if the setup script triggers
        the build, for own/a-priori cmake builds please use the :cmake:`CMAKE_USE_OPENSSL=YES`
        flag at cmake build configuration time.
   5. [Optional] Python_ and various libraries. Only relevant if you want to build Python bindings.
   
      - Python itself (:code:`python`), minimum version 2.7.9.
      - The SWIG_ interface generator (e.g. `Windows download`_)  
      - The Python libraries and development packages (:code:`libpython, python-dev`)
      - [Iron only] The NumPy_ library (:code:`python-numpy`)
      - [Optional] For :ref:`multi-architecture builds <multiarchbuilds>`,
        the Python virtualenv_ mechanism allows to easily switch between different configurations.
        
        - Linux/Mac: Install via your package management system (:code:`python-virtualenv`)
        - Windows: See http://pymote.readthedocs.org/en/latest/install/windows_virtualenv.html

.. _OpenSSL: https://www.openssl.org/
.. _Git: http://git-scm.com/downloads
.. _GitHub: http://www.github.com
.. _CMake: http://www.cmake.org
.. _Python: https://www.python.org/
.. _NumPy: http://www.numpy.org/
.. _virtualenv: https://virtualenv.readthedocs.org/en/latest/
.. _SWIG: http://www.swig.org/
.. _`Windows download`: http://prdownloads.sourceforge.net/swig/swigwin-3.0.8.zip

Building on Linux
=================

.. _`linux steps`:

Default steps for Users (terminal/command line)
-----------------------------------------------

   1. Create the :cmake:`OPENCMISS_ROOT` folder somewhere and enter it
   2. Clone the setup git repo into that folder via :sh:`git clone https://github.com/OpenCMISS/manage`.
      Alternatively, if you don't have Git, go to `GitHub and download a zip file`_ 
   3. Enter the :path:`OPENCMISS_ROOT/manage/build` folder
   4. Type :sh:`cmake ..`
   5. *optional* Make changes to the configuration, see  by changing the :ref:`OpenCMISSLocalConfig <localconf>` file
      in the current build directory.
   6. Build the :sh:`opencmiss` target via :sh:`make | nmake | .. opencmiss` (or whatever native build system you have around).
      Multithreading is used automatically, no :sh:`-j4` or so needed.
   7. Have a coffee.
   8. Coming back from the coffee and something failed? Checkout the :ref:`support section`.
      
.. _`GitHub and download a zip file`: https://github.com/OpenCMISS/manage      
      
This will compile everything using the default compiler and default mpi.
Basic warnings will be in place for all known erroneous system configurations.
The OpenCMISS-Examples are a competely different package/project and if you want to build them after you’ve
finished building the OpenCMISS libraries please see :ref:`examples_build`.

Default steps for Developers (terminal/command line)
----------------------------------------------------

The default steps are the same as for users, but with two changes:
      1. At step 4, invoke :sh:`cmake -DEVIL=<YES|your_freely_chooseable_evilness_value> ..`
      2. In addition to the changes you can make at step 5, change the 
         :ref:`OpenCMISSDeveloper <develconf>` file according to your OpenCMISS development needs.
         
.. note::
   Ideally, the first step for developers is to fork any components of OpenCMISS that should be worked
   on at GitHub (or to some other git-aware location) and modify the developer config script accordingly
   to have the build system checkout the repos from your own location.
   You can still change repository locations later, however that might require a complete re-build.
   
Building on Windows (64bit) (experimental!)
===========================================

   1. Get CMake. Minimum version: 3.3.1
   #. Get MSYS2:
   
      a. Get installer from http://sourceforge.net/projects/msys2/
      #. Install (assume here: :path:`C:\MSYS2_64`), dont use spaces in the installation folder!
      #. Follow the instructions in Section III to update your version http://sourceforge.net/p/msys2/wiki/MSYS2%20installation
   #. Get MinGW 64:
   
      a. Get installer from http://sourceforge.net/projects/mingw-w64/
      #. Choose you GCC version and threading model (use posix); the installer automatically suggests a suitable subfolder for your selection so you can have multiple versions in parallel.
      #. Install, (assume here: C:\mingw-w64\...)
      #. Create a directory junction to include the mingw64-folder into the msys directory tree     
   #. Open a windows command prompt **IN ADMINISTRATOR MODE**
   
      a. Go into C:\MSYS2_64
      #. Remove the old :path:`mingw64`-folder (it should only contain an :path:`/etc` folder)
      #. Type :sh:`mklink /J mingw64 C:\mingw-w64\<your selection>\mingw64`
      #. Windows will confirm e.g. :sh:`Junction created for mingw64 <<===>> C:\mingw-w64\x86_64-4.9.2-posix-seh-rt_v4-rev2\mingw64`
      #. If you want to switch to another toolchain version/model later, install mingw-w64 with that
         config and repeat the symlink steps.
   #. Get an MPI implementation!
   
      a. http://www.mpich.org/downloads for MPICH2
         (unofficial binary packages section, we used 64bit version http://www.mpich.org/static/tarballs/1.4.1p1/mpich2-1.4.1p1-win-x86-64.msi)
      #. https://msdn.microsoft.com/en-us/library/bb524831%28v=vs.85%29.aspx for MS MPI
      #. Install to a location WITHOUT spaces!
      
   #. Use the :sh:`C:\MSYS2_64\mingw64_shell.bat` to open an mingw64-pathed msys2 console/command
      (all that does is adding mingw64/bin to the path)
   #. Install necessary packages: :sh:`pacman -S git make flex bison` (flex/bison for ptscotch builds)
   #. Follow the build instructions for linux, with the only change of invoking :sh:`cmake -G “MSYS Makefiles” <args> ..`
 
.. note::
      * Most likely you will need to specify :var:`MPI_HOME` when running the main build configuration.
      * Get SSH keys if you want to make a development checkout of sources
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
For building OpenCMISS-Iron on OS X install the following prerequisites:

   1. CMake >= version 3.3.1
   #. From CMake GUI install for command line use in the Tools menu 
   #. XCode from the AppStore
   #. From XCode install the command line utilities
   #. Install Homebrew
   #. Using :sh:`brew install gfortran` with openmp support using the :sh:`--without-mutlilib` flag

Then, the procedure follows along the lines of the :ref:`linux steps`.

.. _`build targets`:

Available build targets
=======================

.. cmake-source:: ../../CMakeScripts/OCMainTargets.cmake

Component-level build targets
-----------------------------

.. cmake-source:: ../../CMakeScripts/OCFunctionComponentTargets.cmake