set(OPENCMISS_EXAMPLES_SRC_DIR ${OPENCMISS_ROOT}/examples)
getBuildTypePathElem(BUILDTYPEEXTRA)
#${OPENCMISS_ROOT}/build/examples/${ARCHITECTURE_PATH_MPI}/${BUILDTYPEEXTRA}
set(OPENCMISS_EXAMPLES_BUILD_DIR ${OPENCMISS_COMPONENTS_BINARY_DIR_MPI}/examples/${BUILDTYPEEXTRA})
#set(OPENCMISS_EXAMPLES_INSTALL_PREFIX ${OPENCMISS_ROOT}/install/examples/${ARCHITECTURE_PATH_MPI})

# This is the examples location until we've got a working version for everyone.
SET(EXAMPLES_REPO https://github.com/rondiplomatico/examples)
set(EXAMPLES_BRANCH cmake)

message(STATUS "Setting up OpenCMISS-Examples...")
createExternalProjects(EXAMPLES ${OPENCMISS_EXAMPLES_SRC_DIR} ${OPENCMISS_EXAMPLES_BUILD_DIR} "")
# Dont build the examples with the normal main build!
set_property(TARGET EXAMPLES PROPERTY EXCLUDE_FROM_ALL TRUE)