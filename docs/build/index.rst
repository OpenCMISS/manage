.. _`build opencmiss`:

----------------------------
Building the OpenCMISS Suite
----------------------------

.. note::
   If you encounter any troubles, don’t miss reading the :ref:`build support` section!

The base for the installation is a folder called :path:`OPENCMISS_ROOT`.
We’ll use :path:`<manage>` as shorthand to :path:`<OPENCMISS_ROOT>/manage`.

.. _`build_prerequisites`:

Prerequisites
=============
In order to build OpenCMISS or any part of it, you need:

   #. A compiler toolchain :code:`(gnu/intel/clang/...)`
   #. CMake_ 3.4 or higher.
   
      - If you are on Linux/Mac and already have an older version installed (higher than 2.6),
        the build procedure will automatically provide a target “cmake” to build the required CMake version and
        prompt you to re-start the configuration with the new binary.
      - On Windows just download the current installer, e.g. http://www.cmake.org/files/v3.3/cmake-3.3.2-win32-x86.exe
      - Only for Linux/Mac without Git_: OpenSSL_.
        This is required to enable CMake to download files via the :code:`https` protocol from GitHub.
        OpenSSL_ will automatically be detected & built into CMake if the setup script triggers
        the build, for own/a-priori cmake builds please use the :cmake:`CMAKE_USE_OPENSSL=YES`
        flag at cmake build configuration time.
   #. Disk space! Make sure to have at least 5 GB of free disk space if you plan to build everything in Release and Debug modes. 
   #. [*Optional*] Git_ version control.
      This is recommended as cloning the repositories makes contributing back easier from the start!
   #. [*Iron only*] A MPI implementation - some are shipped with OpenCMISS and can be automatically built for you.
      If you want a different one, no one holds you back.
   #. [*Python bindings only*] Python_ and various libraries. This is only relevant if you want to build Python bindings.
   
      - Python itself (:code:`python`), minimum version 2.7.9.
      - The SWIG_ interface generator (e.g. `Windows download`_)  
      - The Python libraries and development packages (:code:`libpython, python-dev`)
      - [Iron only] The NumPy_ library (:code:`python-numpy`), see `SourceForge <numpy_dl_general>`_
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
.. _`numpy_dl_general`: http://sourceforge.net/projects/numpy/files/NumPy 
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
      
This will compile *everything* using the default compiler and default mpi - if you only want a certain component of OpenCMISS,
please refer to :ref:`selected components`.
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
   
Building on Windows
===================

Building on MS Windows is *not* recommended for anyone just running examples or building applications against the OpenCMISS Libraries.
The documentation will be augmented to more specific instructions for various use cases later.

Prerequisites
-------------

In addition to the :ref:`general prerequisites <build_prerequisites>`:

   #. Visual Studio 2013 Update 5. Other versions *might* work, they have not been tested yet. The Update 5 was necessary to
      fix some compiler issues for some dependencies.
   #. If you want to build Iron:
   
      #. A Fortran compiler that integrates with Visual Studio. We use the Intel Composer Framework (license costs!)
      #. MPI: We use MPICH2_, MSMPI_ can be configured but there are `known compatibility issues`_ regarding the MSVCRT.
   #. Make sure that any pre-installed programs (MPI, Git, ..) are available on the PATH (either User or System scope).
      Path entries must be *without* quotation marks in order to have CMake pick them up correctly!

.. _MPICH2: http://www.mpich.org/static/tarballs/1.4.1p1/mpich2-1.4.1p1-win-x86-64.msi
.. _MSMPI: https://msdn.microsoft.com/en-us/library/bb524831%28v=vs.85%29.aspx
.. _`known compatibility issues`: https://github.com/OpenCMISS/manage/issues/52

Visual Studio (32/64bit)
------------------------

   #. Create the :cmake:`OPENCMISS_ROOT` folder somewhere and enter it
   #. Clone the setup git repo into that folder via :sh:`git clone https://github.com/OpenCMISS/manage`.
      Alternatively, if you don't have Git, go to `GitHub and download a zip file`_
   #. Open CMake GUI
   
      #. Use the "Browse Source" button and select the :path:`OPENCMISS_ROOT/manage` folder
      #. Use the "Browse Build" button and select the :path:`OPENCMISS_ROOT/manage/build` folder
   
   #. If you want to use MPI, you *need* to specify the MPI cache variable to "msmpi" or "mpich2" in order to have the 
      build system find the corresponding packages. Use the "Add entry" button for that (Type "STRING").
   #. Click on "Configure". CMake will prompt you to select a Toolchain. Make sure you choose the correct one, this also
      determines if you will build 32 or 64 bit versions.
   #. After the configuration finished, click "Generate".
   #. Navigate to :path:`OPENCMISS_ROOT/manage/build` and open the generated Visual Studio solution file "OpenCMISS"
   #. Within Visual Studio, select the build type (it seems to default to "Debug", you might want to select "Release")
   #. Build the project "opencmiss".
   #. Have a coffee or two.
   
.. note::

   Building with Visual Studio in 32bit mode has not been tested yet.

Python bindings (64bit)
'''''''''''''''''''''''
Make sure you download a `64bit Python installer`_ (see e.g. general 2.7.11 `download page`_).

Unfortunately, for NumPy_, there is **no** official support for 64bit Windows binaries!
However, `this article`_ describes how to install unofficial `64bit Windows NumPy`_ builds, 
created and maintained by `Christoph Gohlke`_. Woot!
Essentially, you need to download the binary package and use an Administrator-Mode Windows Command Prompt to 
install the package via :sh:`pip install <path-to-package.whl>`. 
For the above Python 2.7.11 link, we use `this build`_.

.. _`this article`: http://stackoverflow.com/questions/11200137/installing-numpy-on-64bit-windows-7-with-python-2-7-3
.. _`download page`: https://www.python.org/downloads/release/python-2711/
.. _`64bit Python installer`: https://www.python.org/ftp/python/2.7.11/python-2.7.11.amd64.msi
.. _`64bit Windows NumPy`: http://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy
.. _`Christoph Gohlke`: http://www.lfd.uci.edu/~gohlke/
.. _`this build`: http://www.lfd.uci.edu/~gohlke/pythonlibs/bofhrmxk/numpy-1.10.4+mkl-cp27-none-win_amd64.whl


Python bindings (32bit)
'''''''''''''''''''''''
For NumPy_, there are 32bit Windows binaries available via `SourceForge <numpy_dl_general>`_.
For some reason newer releases don't come with the 'superpack' .msi installers, `Version 1.10.2 <numpy_dl>`_ currently does. 

.. _numpy_dl: http://sourceforge.net/projects/numpy/files/NumPy/1.10.2/ 

MinGW and MSYS (64bit)
----------------------

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
   
MinGW and MSYS (32bit)
----------------------
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
