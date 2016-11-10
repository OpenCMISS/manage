.. _`build options`:

-------------------------------
Build customisation and options
-------------------------------
OpenCMISS comes with a default build behaviour that is intended be sufficient for most cases of api-users.
However, if you need to make (well-informed!) changes to the default build configuration, here is what we offer.

.. caution::

   Due to the way CMake is designed, one cannot change the compiler once the configuration phase is run
   (without a big fuss or deleting the directory contents).
   Moreover, changing the MPI implementation turned out to be very error-prone as well.
   Hence, we decided to exclude those settings from those you can “easily” change.
   For information on toolchain/mpi configuration see :ref:`multiarchbuilds`.
 
The OpenCMISS default configuration is set by the :path:`<manage>/Config/OpenCMISSDefaultConfig` file.
Any value defined there can be overridden by re-definition in *local* configuration files, which are
created (from a template at :path:`<manage>/Templates/OpenCMISSLocalConfig.template.cmake`)
within your top-level binary dir as :path:`OpenCMISSLocalConfig.cmake`.

*Yes, you have a separate local configuration file for each toolchain/mpi combination!*

For example, in the default setting this file is located at

::

   <OPENCMISS_ROOT>/manage/build/OpenCMISSLocalConfig.cmake

The local config file will be automatically read by CMake upon configuration stage. Any subsequent changes to that
file trigger an automatic re-run of :sh:`cmake` to propagate the changes to the current build.

.. _`selected components`:

Building only Iron or Zinc
==========================

In many cases you might only want to build Iron or Zinc. You can easily
achieve that by setting the following variables in your
:ref:`OpenCMISSLocalConfig <localconf>` (terminal) or CMake GUI environment:

   - Building only Iron: Set :cmake:`OC_USE_ZINC` to :cmake:`NO`
   - Building only Zinc: Set :cmake:`OC_USE_IRON` to :cmake:`NO`, set :cmake:`MPI` to :cmake:`none`

.. _`local config file`:
.. _`localconf`:
.. _`defaultconfig`:

OpenCMISS configuration options
===============================

These are the options available within the :path:`OpenCMISSLocalConfig.cmake` file.

.. toctree::
   :maxdepth: 1
   
   config

.. _`intercomponent`:

OpenCMISS inter-component configuration
---------------------------------------
.. cmake-source:: ../../Config/OpenCMISSInterComponentConfig.cmake
   
.. _OpenCMISSInstallaionConfig:
.. _installationconf:
   
OpenCMISS developer options
===========================

For OpenCMISS developers, there are a range of extra options that can be set.
The corresponding file is located at the build directory: :path:`<manage>/OpenCMISSInstallationConfig.cmake`.

In principal, all the configuration options :ref:`above <localconf>` can also be set in the developer config file.
However, this file is included in **all** top-level build tree configurations for all architectures
- hence those setting are *global* in a sense.

.. caution::
   
   The OpenCMISSInstallationConfig file is included *after* any OpenCMISSLocalConfig file. Hence, all settings specified in the
   developer config take precedence over any local setting.

As OpenCMISS-Developers will mainly work only on a selection of components, the extra configuration
file is intended to tell the build system which those components are and have the setup checkout
the correct Git repos etc.

.. toctree::
   :maxdepth: 1
   
   installation/index
