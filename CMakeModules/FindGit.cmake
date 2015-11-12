#.rst:
# FindGit
# -------
#
# This module helps finding a local Git_ installation and provides convenience functions for common Git queries.
#
# .. _Git: http://git-scm.com/
#
# Defined variables
# """""""""""""""""
#
# :variable:`GIT_EXECUTABLE`
#    Path to Git_ command line client
# :variable:`GIT_FOUND`
#    True if the Git_ command line client was found
# :variable:`GIT_VERSION_STRING`
#    The version of Git_ found (since CMake 2.8.8)
#
# Defined functions
# """""""""""""""""
#
# For convenience, the module provides the additional functions
#
# :command:`git_get_revision`
#     Get commit revision number information. 
#
# :command:`git_get_branch` 
#     Get current branch information.
#
# **WARNING**
#
# If you use those functions at *configure* time and checkout a different Git_ revision after running :manual:`cmake(1)`,
# the information from :command:`git_get_revision` or :command:`git_get_branch` will be outdated.
# If you need to be sure, we recommend using :command:`add_custom_command` or :command:`add_custom_target` in conjunction with
# the :manual:`cmake(1)` script mode (:code:`-P`) to ensure the Git_ information is obtained at *build* time.  
# 
#
# Example usage
# """""""""""""
#
# ::
#
#    find_package(Git)
#    if(GIT_FOUND)
#      message("git found: ${GIT_EXECUTABLE}")
#      git_get_branch(GITBRANCH)
#      message("current branch at ${CMAKE_CURRENT_SOURCE_DIR}: ${GITBRANCH}")
#    endif()
#
# Details
# """""""
#
# .. variable:: GIT_EXECUTABLE
#
#    Returns the full path to the Git_ executable to use in e.g. :command:`add_custom_command` like
#
# ::
#
#        add_custom_command(COMMAND ${GIT_EXECUTABLE} clone https://github.com/myrepo mydir)
#    
# .. variable:: GIT_FOUND
#
#    Boolean variable set to TRUE if a local Git_ was found, FALSE else.
# 
# .. variable:: GIT_VERSION_STRING
#
#    The output of :code:`git --version`


#=============================================================================
# Copyright 2010 Kitware, Inc.
# Copyright 2012 Rolf Eike Beer <eike@sf-mail.de>
# Copyright 2015 Daniel Wirtz <daniel.wirtz@simtech-uni-stuttgart.de>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# Look for 'git' or 'eg' (easy git)
#
set(git_names git eg)

# Prefer .cmd variants on Windows unless running in a Makefile
# in the MSYS shell.
#
if(WIN32)
  if(NOT CMAKE_GENERATOR MATCHES "MSYS")
    set(git_names git.cmd git eg.cmd eg)
    # GitHub search path for Windows
    set(github_path "$ENV{LOCALAPPDATA}/Github/PortableGit*/bin")
    file(GLOB github_path "${github_path}")
  endif()
endif()

find_program(GIT_EXECUTABLE
  NAMES ${git_names}
  PATHS ${github_path}
  PATH_SUFFIXES Git/cmd Git/bin
  DOC "git command line client"
  )
mark_as_advanced(GIT_EXECUTABLE)

if(GIT_EXECUTABLE)
  execute_process(COMMAND ${GIT_EXECUTABLE} --version
                  OUTPUT_VARIABLE git_version
                  ERROR_QUIET
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  if (git_version MATCHES "^git version [0-9]")
    string(REPLACE "git version " "" GIT_VERSION_STRING "${git_version}")
  endif()
  unset(git_version)
endif()

# Handle the QUIETLY and REQUIRED arguments and set GIT_FOUND to TRUE if
# all listed variables are TRUE

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Git
                                  REQUIRED_VARS GIT_EXECUTABLE
                                  VERSION_VAR GIT_VERSION_STRING)

# Convenience Git repo & branch information functions

#.rst:
# .. command:: git_get_revision
#
# ::
#
#     git_get_revision(VARNAME
#        [SHORT]
#        [GIT_OPTIONS] <string>
#        [WORKING_DIRECTORY] <directory>)
#
# Obtain Git_ revision information using the rev-parse_ command. Effectively calls :code:`rev-parse [GIT_OPTIONS] --verify -q HEAD`.
#
# ``VARNAME``
#    The workspace variable name to assign the result to.
#
# ``SHORT``
#    Optional. If set to TRUE, the short revision string will be returned. Otherwise, the full revision hash is returned.
#
# ``GIT_OPTIONS``
#    Optional. Specify a string like :code:`"--sq"` to add to the options of the rev-parse_ command.
#
# .. _rev-parse: https://www.kernel.org/pub/software/scm/git/docs/git-rev-parse.html
#
# ``WORKING_DIRECTORY``
#   The working directory at which to execute the git commands.
#   If not specified, :variable:`CMAKE_CURRENT_SOURCE_DIR` is assumed. 
function(git_get_revision VARNAME)
    if (NOT GIT_FOUND)
        message(FATAL_ERROR "Cannot use git_get_revision: Git was not found.")
    endif()
    
    cmake_parse_arguments(GIT "SHORT" "WORKING_DIRECTORY;GIT_OPTIONS" "" ${ARGN})
    
    if(NOT GIT_WORKING_DIRECTORY OR "${GIT_WORKING_DIRECTORY}" STREQUAL "")
        set(GIT_WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse ${GIT_OPTIONS} --verify -q HEAD
        OUTPUT_VARIABLE RES
        ERROR_VARIABLE ERR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${GIT_WORKING_DIRECTORY})
    set(${VARNAME} ${RES} PARENT_SCOPE)
    if (ERR)
        message(WARNING "Issuing Git command '${GIT_EXECUTABLE} rev-parse --verify -q HEAD' failed: ${ERR}")
    endif()
endfunction()

#.rst:
# .. command:: git_get_branch
#
# ::
#
#     git_get_branch(VARNAME
#        [WORKING_DIRECTORY] <directory>)
#
# ``VARNAME``
#    The workspace variable name to assign the result to.
#
# ``WORKING_DIRECTORY``
#   The working directory at which to execute the git commands.
#   If not specified, :variable:`CMAKE_CURRENT_SOURCE_DIR` is assumed.
function(git_get_branch VARNAME)
    if (NOT GIT_FOUND)
        message(FATAL_ERROR "Cannot use git_get_branch: Git was not found.")
    endif()
    
    cmake_parse_arguments(GIT "" "WORKING_DIRECTORY" "" ${ARGN})

    if(NOT GIT_WORKING_DIRECTORY OR "${GIT_WORKING_DIRECTORY}" STREQUAL "")
        set(GIT_WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    execute_process(COMMAND ${GIT_EXECUTABLE} symbolic-ref -q HEAD
        OUTPUT_VARIABLE RES
        ERROR_VARIABLE ERR
        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY ${GIT_WORKING_DIRECTORY})
    if (ERR)
        message(WARNING "Issuing Git command '${GIT_EXECUTABLE} symbolic-ref -q HEAD' failed: ${ERR}")
    endif()
    set(${VARNAME} ${RES} PARENT_SCOPE)
endfunction()