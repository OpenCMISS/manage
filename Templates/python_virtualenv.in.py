# This file contains information about installed virtual environments 

info = { dir: "@PYTHON_BINDINGS_INSTALL_DIR@", toolchain: "@TOOLCHAIN@",
         mpi: "@MPI@", mpi_home: "@MPI_HOME@", buildtype: "@BTYPE@",
         compiler: "@COMPILER@", mpi_buildtype: "@MPI_BUILD_TYPE@",
         library_path: "@LIBRARY_PATH@", is_virtual_env: @IS_VIRTUALENV@ }

if not virtualenvs:
    virtualenvs = []
virtualenvs.append(info)