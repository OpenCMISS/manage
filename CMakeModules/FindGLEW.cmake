# - Find glew
# Find the native GLEW includes and library
#
#  GLEW_INCLUDE_DIRS - Where to find glew.h, etc.
#  GLEW_LIBRARIES    - List of libraries when using glew.
#  GLEW_DEFINITIONS  - List of definitions when using glew.
#  GLEW_FOUND        - True if glew found.

#=============================================================================
# Copyright 2001-2009 Kitware, Inc.
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

IF (GLEW_INCLUDE_DIR)
  # Already in cache, be silent
  SET(GLEW_FIND_QUIETLY TRUE)
ENDIF (GLEW_INCLUDE_DIR)

FIND_PATH(GLEW_INCLUDE_DIR GL/glew.h)

SET(GLEW_NAMES ${GLEW_NAMES} glew)
FIND_LIBRARY(GLEW_LIBRARY NAMES ${GLEW_NAMES})

SET(GLEW_NAMES_DEBUG ${GLEW_NAMES_DEBUG} glewd)
FIND_LIBRARY(GLEW_LIBRARY_DEBUG NAMES ${GLEW_NAMES_DEBUG})

# Per-recommendation
SET(GLEW_INCLUDE_DIRS ${GLEW_INCLUDE_DIR})
IF( NOT GLEW_LIBRARY_DEBUG )
	SET( GLEW_LIBRARIES ${GLEW_LIBRARY} )
ELSE( NOT GLEW_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( GLEW_LIBRARIES
		debug ${GLEW_LIBRARY_DEBUG}
		optimized ${GLEW_LIBRARY} )
ENDIF( NOT GLEW_LIBRARY_DEBUG )
SET(GLEW_DEFINITIONS )

# handle the QUIETLY and REQUIRED arguments and set GLEW_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(GLEW DEFAULT_MSG GLEW_LIBRARIES GLEW_INCLUDE_DIRS)

MARK_AS_ADVANCED(GLEW_LIBRARY GLEW_LIBRARY_DEBUG GLEW_INCLUDE_DIR)
