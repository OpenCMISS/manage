.. _`techdocs`:

====================================
Techdocs for build system developers
====================================

The (planned) GitHub repository structure `can be found here`_,
and this document explains the layout of the different components and the overall build process.

.. _`can be found here`: https://docs.google.com/document/d/1_HCyBMDRsyIEPLOUVVXSP0b4uDRsdCmbJuezVgySdbg

File System Layout
==================
The top level folder subsequently called :var:`OPENCMISS_ROOT` is the base folder for the build environment.
Its subfolders are as follows:

::

   build/                                       # Root for all build trees
      [arch-dir-short/]mpi/                     # Root for local MPI builds
         openmpi
         mpich
      [arch-dir/]                               # Architecture path including toolchain, mpi, multithreading, ...
         blas[/release|/debug/|...]        
         ...
         petsc[/release/|/debug|...]            # The build type is a sub-folder of the component to be consistent with Windows
         iron[/release/|/debug|...]
         zinc[/release/|/debug|...]
         examples[/release/|/debug|...]
      utilities/                                # Architecture-independent build root
         gtest
   manage/                                      # The top-level source directory.            
      build                                     # The default top-level binary directories
      build_intel
      build_intel_mpi_debug                     # More (examplatory) user-defined top-level build directories
      build_my_naming
   src/                                         # Root source directory for all OpenCMISS components
      iron/
      zinc/
      dependencies/                             # Dependency sources are grouped into this folder
         blas/
         ...
         zlib/
      utilities/                                # Utility sources
         cmake/
         git/
      mpi/                                      # Sources for own MPI builds 
         openmpi/
         mpich/
   examples/                                    # Default folder for OpenCMISS examples
      ex1/
      ex2/
   install/                                     # Default OpenCMISS installation root
      [/arch-dir]                               # Architecture path segment
         [/release|/debug|...]                  # The build type if this installation
            bin/                                # Any produced binaries
               cmgui-exe
            lib/                                # All compiled libraries and Fortran modules
               iron.mod
               zinc.a
               blas.a
               zlib.a
            include/                            # The top-level include directory for this installation
               mumps/                           # In order to avoid naming clashes, components with many
               petsc/                           # installed headers are put into subfolders
               ...
      cmake/                                    # CMake-related necessary files
         OpenCMISSExtraFindModules/             # FindXXX.cmake module files to find system components
         OpenCMISSFindModuleWrappers/           # Wrapper files for all FindXXX find module scripts
      utilities/
         gtest/
         cmake/

The main setup project organization
===================================
The setup project is the main access point for OpenCMISS builds and shows the following
structure (mounted on :path:`OPENCMISS_ROOT/manage/`):

::

   CMakeLists.txt                               # Main CMake build config file.
   Config/                                      # A collection of CMake files regarding the configuration of the build process
   CMakeScripts/                                # A collection of scripts performing a specific task. Merely created for tidyness and separation of concerns.
      CMakeCheck.cmake
      OCSetupBuildMacros.cmake
      ...
   CMakeFindModuleWrappers/                     # Own wrappers for find_package() calls in OpenCMISS
      FindXXX.cmake
   CMakeModules/                                # Own provided MODULE mode search scripts
      FindSUNDIALS.cmake
      ...
   Templates/                                   # Files that are configured at some stage of the configuration or build phase
      OpenCMISSLocalConfig.template.cmake
      ...

Examples structure
==================
Similar to the old build system, the examples available for OpenCMISS are kept separate. 
Ultimately, all the available examples will be hosted in their own GIT repository,
and a central examples repository will collect all working examples for any OpenCMISS release.
In the process of conversion, however, there still only exists one global
examples repository (initialized with the old examples svn repo) 
at https://github.com/OpenCMISS-Examples/examples, branch “v1.0”.
 
The current global project can generate the :path:`CMakeLists.txt` files automatically
(not very clever though) for each example.
The detection is done simply via looking if the according folder contains a :path:`Makefile` file.
This is far from ideal, but a quick way to see what’s working and what not.

.. This adds in the buildlog documentation
.. cmake-source:: ../../CMakeScripts/OCMiscFunctionsMacros.cmake

.. _`keytests`:

Key tests
=========

.. cmake-source:: ../../Tests/OCKeyTests.cmake

Writing Iron IO routines
========================

For any routine that does not directly belong to the OpenCMISS-Iron API (:sh:`opencmiss_iron.f90`), extra declarations have to be made
in order to have the according methods exported to Windows .dll files.

Within the respective source, say :sh:`test_framework_routines.f90`, you need to include::

   #include "dllexport.h"
   
to define the DLL export macro. Within each publicly visible routine, you then need to specify :code:`!DLLEXPORT(<routinename>)` as a comment inside
the routine body, e.g::

   SUBROUTINE TEST_FRAMEWORK_ASSERT_EQUALS_INTG(EXPECTED_VALUE,ACTUAL_VALUE,ERR)
    !DLLEXPORT(TEST_FRAMEWORK_ASSERT_EQUALS_INTG)
    
    !Argument variables 
    [...]
 

Building applications
=====================

If you write Fortran code and use MPI, you need to use the following MPI directives::

  #ifndef NOMPIMOD
    USE MPI
  #endif
  [...]
    IMPLICIT NONE
  [...]
  #ifdef NOMPIMOD
    #include "mpif.h"
  #endif

Reasoning: In some cases like Windows/MPICH2 there sometimes is no mpi.mod file. In order to yet make
the example work the build system adds the definition 'NOMPIMOD', which can be checked and acted to accordingly.