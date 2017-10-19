
##
# .. _`component_branches`:
#
# <COMP>_BRANCH
# -------------
#
# Manually set the target branch to checkout for the specified component. Applies to own builds only.
# If this variable is not set, the build system automatically derives the branch name
# from the :var:`<COMP>_VERSION` variable (pattern :cmake:`v<COMP>_VERSION`).
#
# See also: `<COMP>_REPO`_ :ref:`comp_version`

#set(IRON_BRANCH myironbranch)

##
# <COMP>_DEVEL
# ------------
#
# At first, a flag :var:`<COMPNAME>_DEVEL` must be set in order to notify the setup that
# this component (Iron, Zinc, any dependency) should be under development.
#
# See also: `OPENCMISS_DEVELOP_ALL`_.
#
# .. default:: NO

#set(IRON_DEVEL YES)

##
# <COMP>_REPO
# ---------------
#
# Set this variable for any component to have the build system checkout the sources from that repository. Applies to own builds only.
#
# If this variable is not specified, the build system setup chooses the default
# public locations at the respective GitHub organizations (OpenCMISS, OpenCMISS-Dependencies etc).
# 
# .. caution::
# 
#    Those adoptions *must* currently be made before the first build is started - once a repository is
#    created there is no logic on changing the repository location (has at least not been tested).
#
# Use in conjunction with `<COMP>_BRANCH`_ if necessary.

#set(IRON_REPO git@github.com:mygithub/iron)
