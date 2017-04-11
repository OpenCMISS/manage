#!/usr/bin/env python
# This file contains information about installed virtual environments 

info = { "dir": "@_OC_PYTHON_INSTALL_PREFIX@", "toolchain": "@_ACTIVE_TOOLCHAIN@",
         "mpi": "@_ACTIVE_MPI@", "mpi_home": "@_ACTIVE_MPI_HOME@", "buildtype": "@BTYPE@",
         "compiler": "@COMPILER@", "mpi_buildtype": "@_ACTIVE_MPI_BUILD_TYPE@",
         "library_path": "@LIBRARY_PATH@", "is_virtual_env": @IS_VIRTUALENV@, "activate": "@ACTIVATE_SCRIPT@", }

