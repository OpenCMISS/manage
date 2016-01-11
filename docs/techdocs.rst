:Date: 2016-01-11
:Author: Daniel Wirtz

====================================
Techdocs for build system developers
====================================

File System Layout
==================
The top level folder subsequently called :var:`OPENCMISS_ROOT` is the base folder for the build environment.
Its subfolders are as follows:
   * build/
      Global root for all build trees. Every build tree is optionally (default:no) further organized using an architecture path arch-dir that separates binaries and libraries build with different mpi/compiler versions etc; see below for its specifications.
      * [arch-dir-short/]mpi/
         Contains the builds of different mpi implementations (if no system ones are used)
         * openmpi
         * mpich
      * [arch-dir/]
         Contains the actual components of OpenCMISS, sorted into subfolders according to the logical grouping. The last level of each component is the build configuration, to keep consistent with multi-configuration generators like xcode or visual studio
         * dependencies
         * blas[/release|/debug/|...]
         * …
         * petsc[/release/|/debug|...]
         * iron[/release/|/debug|...]
         * zinc[/release/|/debug|...]
         * examples[/release/|/debug|...]
         * utilities/
         * gtest
         * manage/
            Contains the main setup project and scripts that organize source downloads and builds. For details see the developer tech notes here. The only relevant folder for api-users is
            * build
               Default build tree folder for top level project.
            * build_intel
               [more build folders for different toolchain/mpi configs - suggestion only]
            * build_intel_mpi_debug
            * build_my_naming
   * src/
      Contains all component and utilities sources, again sorted into subfolders by logical groups.
      * iron/
      * zinc/
      * dependencies/
         this folder collects all dependencies sources into one folder for tidyness
         * blas/
         * ...
         * zlib/
      * utilities/
         * cmake/
         * git/
      * mpi/
         * openmpi/
         * mpich/
      * examples/
         * ex1/
         * ex2/
   * install/
      In order to be able to discard of any build/source folders when necessary, all binaries, includes (and config files) are installed under a global install directory, subjected to the architecture path used for the current build. In order to have consistent behaviour for linux and windows, the build type (release/debug) is the last path component.
      * [/arch-dir][/release|/debug|...]
         * bin
            * cmgui-exe
            * …
         * lib
            * iron.mod
            * zinc.a
            * blas.a
            * zlib.a
         * include
         * cmake
            Contains the cmake package config files.
            If the libraries are given relative to the install prefix (which is a good thing),
            unfortunately we cant have the config.cmake files outside the install_prefix.
            That would be suitable as the naming convention for package files is to append
            -release or -debug automatically, thus we’d ideally have one folder “cmake” on
            the parent level along “debug|release”.
            This is, however, not implemented in current cmake versions.
      * utilities
         * gtest
         * cmake

The main setup project organization
===================================
The setup project is the main access point for OpenCMISS builds and shows the following
structure (mounted on :path:`OPENCMISS_ROOT/manage/`):
   * CMakeLists.txt
      Main CMake build config file.
   * Config/
      A collection of CMake files regarding the configuration of the build process
      * CMakeScripts/
         A collection of scripts performing a specific task. Merely created for tidyness and separation of concerns.
         * CMakeCheck.cmake
         * OCSetupBuildMacros.cmake
         * ...
      * CMakeFindModuleWrappers/
         Own wrappers for find_package() calls in OpenCMISS
         * FindXXX.cmake
      * CMakeModules/
         Own provided MODULE mode search scripts
         * FindSUNDIALS.cmake
         * …
      * Templates/
         Files that are configured at some stage of the configuration or build phase
         * OpenCMISSLocalConfig.template.cmake
         * ...

Examples structure
==================
Similar to the old build system, the examples available for OpenCMISS_ are kept separate. 
Ultimately, all the available examples will be hosted in their own GIT repository,
and a central examples repository will collect all working examples for any OpenCMISS release.
In the process of conversion, however, there still only exists one global
examples repository (initialized with the old examples svn repo) 
at https://github.com/OpenCMISS-Examples/examples, branch “v1.0”.
 
The current global project can generate the :path:`CMakeLists.txt` files automatically
(not very clever though) for each example.
The detection is done simply via looking if the according folder contains a :path:`Makefile` file.
This is far from ideal, but a quick way to see what’s working and what not.
