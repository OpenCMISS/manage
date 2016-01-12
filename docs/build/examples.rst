.. _`examples_build`:

-------------------------------------------
Building OpenCMISS examples (Unix/terminal)
-------------------------------------------
With the new CMake-based build system, building OpenCMISS applications and examples has become much easier.
Any installed OpenCMISS suite has a :var:`OPENCMISS_INSTALL_ROOT`
Any (CMake-built) application using OpenCMISS libraries just need to add the OpenCMISS installation directory
to their :cmake:`CMAKE_PREFIX_PATH` and prefix pathspecify the

Essentially, all that is required is to specify the :var:`OPENCMISS_INSTALL_DIR` variable: 

The instructions here are for building a single example.


Building an example requires some effort in order to have compatible settings to your OpenCMISS installation.
Luckily, the OpenCMISS build system can manage that for you.
But this, in turn, means that a local OpenCMISS manage repository
is always required, even if you want to use a remote installation and only build examples yourself.
So, make sure you have that first, as it will look for (and possibly build) at least a local MPI implementation.



   1. Download the desired example from PMR or GitHub.
      (*Transition phase only*: Clone the https://github.com/OpenCMISS-Examples/examples repository
      and navigate to the folder of your desired example)
   2. Create a build folder within the example source, e.g. :path:`build` and change to it
   3. Invoke :sh:`cmake -DOPENCMISS_INSTALL_DIR=<OPENCMISS_ROOT>/install ..`
   4. Invoke :sh:`make install`
   
Now you should have a binary :path:`./run` in your example source that can be executed.