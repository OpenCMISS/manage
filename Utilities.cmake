# Generate the wrappers (if not existing)
include(OCMUtilsGenerateFindXXXWrappers)

set(SUBGROUP_PATH utilities)
set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)

if(OCM_USE_MPI)
    # todo check for mpi and build if not found
endif()

# ... gtest, mpi, ..
