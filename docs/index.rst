:Date: 2016-01-11
:Version: 1.1
:Authors: Daniel Wirtz

.. title:: OpenCMISS Build Environment: CMake Reference Documentation
  
==================
Building OpenCMISS
==================

Specifications and Techdocs for building the OpenCMISS_ Modelling Suite with CMake_.

The OpenCMISS_ main “logical” components are Iron_, Zinc_, examples, dependencies, utilities and documentation.
Those components are managed by the `OpenCMISS manage project`_, which downloads (& manages) the sources,
sets up build trees and according installation directories.

.. _CMake: http://www.cmake.org/download
.. _Iron: https://github.com/OpenCMISS/iron
.. _`OpenCMISS`: http://www.opencmiss.org
.. _Zinc: /documentation/zinc

.. toctree::
   :maxdepth: 2
   
   build/index
   build/examples
   config/index
   config/multiarch
   config/remote
   
.. _`OpenCMISS manage project`: https://github.com/OpenCMISS/manage

============
Getting help
============
   
.. toctree::
   :maxdepth: 1
   
   build/support

=======================   
Technical documentation
=======================
   
.. toctree::
   :maxdepth: 1
   
   techdocs/index
  

