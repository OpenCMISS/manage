:Date: 2016-01-11
:Version: 1.1
:Authors: Daniel Wirtz

.. title:: OpenCMISS Build Environment
  
**Welcome to the OpenCMISS software suite documentation!**

We have two major groups of people using OpenCMISS:

   :Users: They use the OpenCMISS components to run, create and modify applications and examples.
   :Developers: These folks intend to make changes to the OpenCMISS library codebase itself, 
      i.e. add functionality to Iron, Zinc or any other component.

Consequently, if you are new to OpenCMISS and want to get familiar with it or you already have a
certain application in mind, you should start with the :ref:`user documentation`.
If you have a more involved project at hand or you already know that you will end up adding functionality to OpenCMISS components,
the :ref:`developer documentation` are the right place to start.
      
.. _`user documentation`:  
  
===========================
OpenCMISS User instructions
===========================

Downloading binary packages is a good place to start to get to know OpenCMISS.
If you are a user without programming experience, you should start with :ref:`using neon`.
If you have some experience with programming and want to use the OpenCMISS libraries via its offered bindings,
you should have a look at :ref:`user sdk`.

.. _`using neon`:

Using OpenCMISS via Neon
========================

.. _`user sdk`:

Using the OpenCMISS User SDK
============================

The User SDK provides pre-compiled binaries of all OpenCMISS main libraries and can be used to develop own applications against them
using either the directly exposed APIs or provided bindings to C or Python languages.
Check the `downloads section <http://www.opencmiss.org/downloads.html>`_ for current packages.

In addition to the SDK, you need a local MPI installation if you want to run parallel code with OpenCMISS-Iron.

For an example using Fortran, C and Python bindings see the :path:`Resources/Examples` folder within the installation directory of the User SDK.

As the use is different depending on the intended API, please see the appropriate sections below.

Using the Fortran API or C bindings
===================================

We recommend to use CMake_ to develop OpenCMISS applications (OpenCMISS itself is built by CMake), of which you need version 3.4 or newer.
Instructions for other ways of using the installed SDK libraries in your development environment will be `added later`_.
Essentially, all you need to do is add the :path:`Resources/OpenCMISS.cmake` file from the SDK installation directory to your example project
and include that *before* you issue the :cmake:`project(..)` command. After your project command, you can use the :cmake:`find_package(OpenCMISS ..)`
command to find and prepare use of OpenCMISS in your application.
An exemplary :path:`CMakeLists.txt` could look like::

   # This is my OpenCMISS application
   
   include(./OpenCMISS.cmake)
   
   cmake_minimum_required(VERSION 3.4)
   project(MyOpenCMISSApplication LANGUAGES C Fortran)
   
   [...]
   
   find_package(OpenCMISS <VERSION> REQUIRED COMPONENTS [Iron|Zinc] CONFIG)
   
This will look for an OpenCMISS package information, which is contained in your User SDK installation. 
It will also verify that the found User SDK in fact matches your locally configure toolchain and mpi choice.
Then, to add OpenCMISS-powered libraries and executables, use::   
   
   # For a library use
   add_library(mylib <SOURCES>)
   target_link_libraries(mylib PRIVATE opencmiss)
   
   # For an executable use
   add_executable(myexec <SOURCES>)
   target_link_libraries(mylib PRIVATE opencmiss)
   
If you wanted to add a test for your binaries/libraries, you can conveniently use::

   # Add a test that runs your binary
   add_test(myapptest myexec)
   add_opencmiss_environment(myapptest)
   
The :cmake:`add_opencmiss_environment` function will set up the test environment to contain the necessary library paths.
The testing can then be run using CTest_

.. _CTest: https://cmake.org/cmake/help/v3.4/manual/ctest.1.html 

Finally, to configure your application, you need to set the variable :cmake:`OPENCMISS_SDK_DIR` to your User SDK installation
folder in CMake (define in CMake-GUI or set via :cmake:`-DOPENCMISS_SDK_DIR` in command line).

.. note::

   If suitable, you may also define the :cmake:`OPENCMISS_SDK_DIR` variable in your environment. This way you dont have to specify it when
   configuring your own component builds through CMake/manage.
   *Windows only* If you chose the default install location, CMake can pick up the installation via system default paths and you dont have to
   specify anything!

For an CMake-enabled example using Fortran and C see the :path:`Resources/Examples/classicalfield_laplace_simple` example within the installation directory.
         
.. _CMake: http://www.cmake.org/download
.. _`added later`: https://github.com/OpenCMISS/manage/issues/54

Using the Python bindings
=========================

The currently available User SDKs come with Python bindings built with Python 2.7.11 (x64).
We aim to provide other versions in the future. 

You will need to install:

   - `Python 2.7.11 64 bit <https://www.python.org/ftp/python/2.7.11/python-2.7.11.amd64.msi>`_
   - The NumPy_ library (:code:`python-numpy`), `this article`_ describes how to install unofficial `64bit Windows NumPy`_ builds, 
     created and maintained by `Christoph Gohlke`_. Woot!
   - [Recommended] The Python virtualenv_ mechanism for independent Python environments
        
        - Linux/Mac: Install via your package management system (:code:`python-virtualenv`)
        - Windows: See http://pymote.readthedocs.org/en/latest/install/windows_virtualenv.html
        
If you intend to use virtual environments, make sure to activate your target environment before proceeding with the following installation steps.
        
To install the Python bindings, open a command prompt and type::

   pip install <USERSDK_DIR>/<ARCHPATH>/python/(Release|Debug)
   
Here, :path:`USERSDK_DIR` is the installation root of your SDK, :path:`ARCHPATH` is the sub-path matching your
current environment, and :path:`(Release|Debug)` refers to the build type. For the current Windows User SDK, this path
could be e.g.:: 
    
   pip install <USERSDK_DIR>/AMD64_Windows/msvc-18.0-F15.0/mpich2_release/python/Release
   
for Iron Python bindings or::

   pip install <USERSDK_DIR>/AMD64_Windows/msvc-18.0-F15.0/no_mpi/python/Release
   
for Zinc bindings (Zinc does not need MPI and will always be located within :path:`no_mpi`).   
  
.. _NumPy: http://www.numpy.org/
.. _virtualenv: https://virtualenv.readthedocs.org/en/latest/  
.. _`this article`: http://stackoverflow.com/questions/11200137/installing-numpy-on-64bit-windows-7-with-python-2-7-3
.. _`64bit Windows NumPy`: http://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy
.. _`Christoph Gohlke`: http://www.lfd.uci.edu/~gohlke/

Building everything from source
===============================

As a OpenCMISS user, you should not really have to build the entire OpenCMISS software suite - the :ref:`Neon <using neon>` 
frontend and :ref:`User SDK <user sdk>` should get you going in most scenarios.
However, if we don't have the pre-built binaries for your scenario (e.g. you are maintaining a computational cluster),
you will need to :ref:`build the OpenCMISS suite from source <building opencmiss>`. 

.. _`developer documentation`:

================================
OpenCMISS Developer instructions
================================

Depending on the scenario at hand, there are two options for OpenCMISS developers.
If you intend to modify the OpenCMISS main components but wont need to fuddle with any of the dependencies, the :ref:`developer sdk` is
probably the most convenient way to achieve this. If you need to modify some of the dependencies (*experienced programmers only*),
you will have to stick with :ref:`building opencmiss`.

.. _`developer sdk`:

Using the Developer SDK
=======================

Check the `downloads section <http://www.opencmiss.org/downloads.html>`_ for current packages.

Once you've installed the developer SDK, you can essentially follow the steps at :ref:`build opencmiss` with the following addition:
You need to set the variable :cmake:`OPENCMISS_SDK_DIR` to your Developer SDK installation
folder in CMake (define in CMake-GUI or set via :cmake:`-DOPENCMISS_SDK_DIR` in command line).

.. note::

   If suitable, you may also define the :cmake:`OPENCMISS_SDK_DIR` variable in your environment. This way you dont have to specify it when
   configuring your own component builds through CMake/manage.

.. _`building opencmiss`:

Building OpenCMISS from source
==============================

Specifications and Techdocs for building the OpenCMISS_ Modelling Suite with CMake_.

The OpenCMISS_ main “logical” components are Iron_, Zinc_, examples, dependencies, utilities and documentation.
Those components are managed by the `OpenCMISS manage project`_, which downloads (& manages) the sources,
sets up build trees and according installation directories.

.. _Iron: https://github.com/OpenCMISS/iron
.. _`OpenCMISS`: http://www.opencmiss.org
.. _Zinc: /documentation/zinc

.. toctree::
   :maxdepth: 2
   
   build/index
   build/examples
   config/index
   config/multiarch
   config/central
   
.. _`OpenCMISS manage project`: https://github.com/OpenCMISS/manage

============
Getting help
============
   
.. toctree::
   :maxdepth: 1
   
   build/support

=======================   
Technical documentation
=======================
   
.. toctree::
   :maxdepth: 2
   
   techdocs/index
  

