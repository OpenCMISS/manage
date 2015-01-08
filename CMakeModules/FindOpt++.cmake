# - Find the native Opt++ (OPTPP) includes and library
#
# This module defines
#  OPTPP_INCLUDE_DIR - Where to find OPT++_config.h, etc.
#  OPTPP_LIBRARIES   - The libraries to link against to use Opt++.
#  OPTPP_DEFINITIONS - You should add_definitons(${OPTPP_DEFINITIONS}) before compiling code that includes Opt++ library files.
#  OPTPP_FOUND       - If false, do not try to use Opt++.
#
# also defined, but not for general use are
#  OPTPP_LIBRARY     - where to find the Opt++ library.

#=============================================================================
# Copyright 2002-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

IF(NOT DEFINED OPTPP_DEBUG_SUFFIX)
  SET(OPTPP_DEBUG_SUFFIX d)
ENDIF(NOT DEFINED OPTPP_DEBUG_SUFFIX)

FIND_PATH(OPTPP_INCLUDE_DIR OPT++_config.h PATH_SUFFIXES optpp)
IF(OPTPP_INCLUDE_DIR)
  SET(OPTPP_DEFINITIONS HAVE_OPTPP_CONFIG_H)
  SET(OPTPP_INCLUDE_DIRS ${OPTPP_INCLUDE_DIR})
ENDIF(OPTPP_INCLUDE_DIR)

FOREACH(COMPONENT ${Opt++_FIND_COMPONENTS})
  SET(OPTPP_${COMPONENT}_FOUND FALSE)
  FIND_LIBRARY(OPTPP_${COMPONENT}_LIBRARY NAMES ${COMPONENT} PATH_SUFFIXES optpp)
  FIND_LIBRARY(OPTPP_${COMPONENT}_LIBRARY_DEBUG NAMES ${COMPONENT}${OPTPP_DEBUG_SUFFIX} PATH_SUFFIXES optpp)
  LIST(APPEND COMPONENT_LIBRARY_NAMES OPTPP_${COMPONENT}_LIBRARY)
  MARK_AS_ADVANCED(OPTPP_${COMPONENT}_LIBRARY OPTPP_${COMPONENT}_LIBRARY_DEBUG)
  IF(NOT OPTPP_${COMPONENT}_LIBRARY_DEBUG)
    LIST(APPEND OPTPP_LIBRARIES ${OPTPP_${COMPONENT}_LIBRARY})
  ELSE(NOT OPTPP_${COMPONENT}_LIBRARY_DEBUG)
    LIST(APPEND OPTPP_LIBRARIES optimized ${OPTPP_${COMPONENT}_LIBRARY}
      debug ${OPTPP_${COMPONENT}_LIBRARY_DEBUG})
  ENDIF(NOT OPTPP_${COMPONENT}_LIBRARY_DEBUG)
  IF(OPTPP_${COMPONENT}_LIBRARY)
    SET(OPTPP_${COMPONENT}_FOUND TRUE)
  ENDIF(OPTPP_${COMPONENT}_LIBRARY)
ENDFOREACH(COMPONENT ${Opt++_FIND_COMPONENTS})

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(OPTPP DEFAULT_MSG ${COMPONENT_LIBRARY_NAMES} OPTPP_INCLUDE_DIR)

MARK_AS_ADVANCED(OPTPP_INCLUDE_DIR)

