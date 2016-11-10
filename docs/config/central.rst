.. _`sdk installations`:

OpenCMISS central installations
===============================
If an entire work group uses OpenCMISS, it is desireable to have a pre-compiled set of
OpenCMISS libraries and dependencies at a central location on the network.
While this can save a lot of disk space and reduce maintenance efforts, good
care needs to be taken to find and use a matching set of libraries depending on
your local architecture, compiler and MPI versions.
The OpenCMISS build system tries to find those matches automatically by using an architecture path.

User instructions (=”Client-side”)
----------------------------------
Specify the :ref:`OPENCMISS_SDK_INSTALL_DIR <sdk_install_dir_var>` in the :ref:`build options <build options>` or add
:sh:`-DOPENCMISS_SDK_INSTALL_DIR=[..]` to your initial build arguments.
The build system will then automatically search for a matching OpenCMISS installation at that directory.
The above procedure is recommended as it will use an architecture path to find compatible installations.

If that fails for some reason and you need to override that mechanism,
specify :ref:`OPENCMISS_SDK_INSTALL_DIR_FORCE <sdk_install_dir_force_var>` instead and have it point
to the mpi-dependent architecture sub-path of the sdk installation which contains the :path:`context.cmake` file.

Developer instructions (=”Server-side”)
---------------------------------------
To set up a central OpenCMISS installation:
   -  Set up the :ref:`OpenCMISSDeveloper <installationconf>` file and
      enable the (in this case mandatory) :var:`OC_USE_ARCHITECTURE_PATH` setting.
   -  Please also make sure to fill in your eMail address into :var:`OC_INSTALL_SUPPORT_EMAIL`.
   -  Next, :ref:`build and install all the different configurations <multiarchbuilds>` that you want to provide for the consuming clients.
   -  Finally, publish the installation root directory :path:`OPENCMISS_ROOT/install` (check for different mount paths!)
      as :ref:`OPENCMISS_SDK_INSTALL_DIR <sdk_install_dir_var>` to anyone wanting to use the central installation.
