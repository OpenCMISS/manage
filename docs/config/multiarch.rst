.. _multiarchbuilds:
.. _`toolchain and MPI type`:

--------------------------------------------------
Building for multiple architectures/configurations
--------------------------------------------------
If you want to compile OpenCMISS using different compilers, MPI implementations etc.,
the build environment is aware of most common “architecture” choices and automatically
places builds in appropriate `architecture paths`_.
Most importantly:

   * All architecture choices **except** toolchain and MPI configuration can be made
     inside the :ref:`local config files <localconf>` (and :ref:`developer config files <develconf>`).
     Toolchain and MPI setup are explained below. See also the main :path:`CMakeLists.txt` file.
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

.. _`archpaths`:
.. _`architecture paths`:
   
Architecture paths
==================
.. cmake-source:: ../../CMakeScripts/OCArchitecturePath.cmake

Toolchain/compiler choice
=========================
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
===
MPI is a crucial dependency to OpenCMISS and is required by many components, especially Iron.
By default, CMake looks and detects the system’s default MPI (if present) and configures the build system to use that.

.. note::

   If you only want to build Zinc, specify :cmake:`MPI=none` in order to deactivate the use of MPI. See also :ref:`selected components`

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