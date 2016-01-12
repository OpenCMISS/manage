.. _`support section`:
.. _`build support`:

-------------
Build support
-------------
Having a smoothly working build is what we aim to provide for you.
Yet, facing all those different systems, there are still situations where stuff goes wrong.

In order to help you out as good and fast as possible we implemented a build report system for support.
The report system is realized via a :sh:`support` target that can be built, e.g.::
 
   make support
   
This will collect build information and create a zip file, which you can attach to any support email.

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

See the :ref:`remote installations` section.

.. _`troubleshooting`:

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

   1. For remote installations: You specified an incorrect remote directory - see :ref:`remote installations`.
   2. The :sh:`install` target was not run. This most commonly occurs if you did not build the :sh:`opencmiss` target.
   
*Solution*: Run the :sh:`install` target, which installs the :path:`opencmiss-config.cmake` files.
Then, your example / application can use that to find your opencmiss installation.
As the :sh:`install` target is a part of the :sh:`opencmiss` target, we recommend building :sh:`opencmiss`
from the start as described in :ref:`build opencmiss`.

   Running the :cmake:`examples` target stops with errors.
   
At the current stage, the examples repo contains *all* the examples from the SVN opencmiss examples repository.
We are currently working on updating/repairing/removing all of them.
 
*Solution*: Invoke your build with flags to ignore intermediate errors. For :sh:`make` this is achieved using the :sh:`-k` flag.