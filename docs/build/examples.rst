.. _`examples_build`:

-------------------------------------------
Building OpenCMISS examples (Unix/terminal)
-------------------------------------------
With the new CMake-based build system, building OpenCMISS applications and examples has become much easier.
Any installed OpenCMISS suite has a :var:`OPENCMISS_CONFIG_DIR` directory, which contains all the information needed
to build and link applications against the installed libraries.

Building existing PMR examples
==============================
Building examples obtained from the PMR_ (Physiome Model Repository) is very simple.

   1. Download/clone the examples source code to a location of your choice
   2. Create a :path:`build` folder inside and enter it
   3. Invoke :sh:`cmake -DOPENCMISS_INSTALL_DIR=<OPENCMISS_CONFIG_DIR> ..`
   4. Invoke :sh:`make install`
   
Now you should have a binary :path:`./run` in your example source that can be executed.

For convenience, you can also define the :cmake:`OPENCMISS_INSTALL_DIR` variable in your local environment.
The examples will use that if found, simplifying the build process even more!
   
.. caution::

   Not all models found at the PMR there are CMake-based. 
   Moreoever, many examples using Iron need to be executed using your MPI binary in order to run in parallel.
   Please refer to the model's own documentation in each case.

.. _PMR: https://models.physiomeproject.org

Building all examples
---------------------

.. caution::

   This feature is for the transition phase from the SVN global examples repo to separate PMR examples only
   
Among the :ref:`build system targets <build targets>` is also a :cmake:`examples` target.
Invoke that to have the build system create a folder :path:`<OPENCMISS_ROOT>/examples` for you, which contains
all the examples from the `GitHub main examples`_ repository.
All of them will be attempted to build.

Also see the :ref:`troubleshooting` section for common issues.

.. _`GitHub main examples`: https://github.com/OpenCMISS-Examples/examples


Creating new OpenCMISS applications
===================================
With the new CMake-based build system, building OpenCMISS applications and examples has become much easier.
Any installed OpenCMISS suite has a :var:`OPENCMISS_CONFIG_DIR` directory, which also contains a CMake package config file.

Hence, any (CMake-powered) application using OpenCMISS just need to add the OpenCMISS installation directory
to their :cmake:`CMAKE_PREFIX_PATH` and can import OpenCMISS build targets via :cmake:`find_package(OpenCMISS)`.
The config file provides the following CMake link targets:

   :opencmiss: An `interface target`__ to add as link library to any example library or executable.
      Wraps the :cmake:iron and :cmake:zinc build targets (if installed).
   :iron: The iron library. Only available if :var:`OC_USE_IRON` is set.
   :zinc: The zinc library. Only available if :var:`OC_USE_ZINC` is set.
   
.. __: https://cmake.org/cmake/help/v3.3/command/add_library.html?highlight=add_library#interface-libraries   
  
.. note::

   The :cmake:`OPENCMISS_INSTALL_DIR` variable used for the PMR examples does nothing but set the :cmake:`CMAKE_PREFIX_PATH`
   variable. For unexperienced users this is more intuitive and it also allows to specify the environment variable of the 
   same name (using CMAKE_PREFIX_PATH in the environment has wider consequences!)
