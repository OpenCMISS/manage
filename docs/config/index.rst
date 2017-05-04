.. _`build options`:

===============================
Build customisation and options
===============================

The OpenCMISS libraries build framework comes with a default build behaviour that is intended be sufficient for most cases of users.
However, if you need to make (well-informed!) changes to the default build configuration, here is what we offer.

There are two configuration files that control how the build framework configures builds.  The first is an *installation* wide configuration file located within your top-level binary dir as :path:`OpenCMISSInstallationConfig.cmake`.  As it's name suggests the settings in this file are applied to every configuration within the installation.  Something very important to take into consideration is this, once the first configuration is created the settings in the *installation* configuration file can no longer be changed.

The second is a *local* configuration file located within the configuration root location.  This configuration file settings apply across all the different build types of that particular configuration.  The *local* configuration file is seeded from the default configuration, the OpenCMISS default configuration is set by the :path:`<manage>/Config/OpenCMISSDefaultConfig` file. Any value defined there can be overridden by re-definition in *local* configuration files, which are created (from a template at :path:`<manage>/Templates/OpenCMISSLocalConfig.template.cmake`) within your top-level configuration binary dir as :path:`OpenCMISSLocalConfig.cmake`.

*Yes, you have a separate local configuration file for each toolchain/mpi combination!*

For example, in the default setting this file is located at

::

   <OPENCMISS_ROOT>/build/manage/release/configs/<ARCH PATH for SYSTEM>/OpenCMISSLocalConfig.cmake

The local config file will be automatically read by CMake upon configuration stage. Any subsequent changes to that
file trigger an automatic re-run of :sh:`cmake` to propagate the changes to the current build.

.. _`selected components`:

--------------------------
Building only Iron or Zinc
--------------------------

In many cases you might only want to build Iron or Zinc. You can easily
achieve that by setting the following variables in your
:ref:`OpenCMISSLocalConfig <localconf>` (terminal) or CMake GUI environment:

   - Building only Iron: Set :cmake:`OC_USE_ZINC` to :cmake:`NO`
   - Building only Zinc: Set :cmake:`OC_USE_IRON` to :cmake:`NO`, set :cmake:`MPI` to :cmake:`none`

.. _`local config file`:
.. _`localconf`:
.. _`defaultconfig`:

-----------------------------------------
OpenCMISS libraries configuration options
-----------------------------------------

Installation configuration options
==================================

These are the options available within the :path:`OpenCMISSInstallationConfig.cmake` file.

.. toctree::
   :maxdepth: 1

   installation_config

Local configuration options
===========================

These are the options available within the :path:`OpenCMISSLocalConfig.cmake` file.

.. toctree::
   :maxdepth: 1

   local_config

.. _`intercomponent`:

Inter-component configuration
=============================

These options control behaviour between components of OpenCMISS libraries.  They can also be changed within the :path:`OpenCMISSLocalConfig.cmake` file.

.. toctree::
   :maxdepth: 1

   intercomponent_config

.. _OpenCMISSInstallaionConfig:
.. _installationconf:

