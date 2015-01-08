# - Find JPEG
# Find the native JPEG includes and library
# 
#  JPEG_INCLUDE_DIRS - Where to find jpeglib.h, etc.
#  JPEG_LIBRARIES    - The libraries needed to use JPEG.
#  JPEG_DEFINITIONS  - List of definitions when using JPEG.
#  JPEG_FOUND        - If false, do not try to use JPEG.
#
#  also defined, but not for general use are
#  JPEG_LIBRARY      - Where to find the JPEG library.

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

IF (JPEG_INCLUDE_DIR)
  # Already in cache, be silent
  SET(JPEG_FIND_QUIETLY TRUE)
ENDIF (JPEG_INCLUDE_DIR)

FIND_PATH(JPEG_INCLUDE_DIR jpeglib.h)

SET(JPEG_NAMES ${JPEG_NAMES} jpeg)
FIND_LIBRARY(JPEG_LIBRARY NAMES ${JPEG_NAMES} )

SET(JPEG_NAMES_DEBUG ${JPEG_NAMES_DEBUG} jpegd)
FIND_LIBRARY(JPEG_LIBRARY_DEBUG NAMES ${JPEG_NAMES_DEBUG} )

# Per-recommendation
SET(JPEG_INCLUDE_DIRS ${JPEG_INCLUDE_DIR})
IF( NOT JPEG_LIBRARY_DEBUG )
	SET( JPEG_LIBRARIES ${JPEG_LIBRARY} )
ELSE( NOT JPEG_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( JPEG_LIBRARIES
		debug ${JPEG_LIBRARY_DEBUG}
		optimized ${JPEG_LIBRARY} )
ENDIF( NOT JPEG_LIBRARY_DEBUG )
SET(JPEG_DEFINITIONS )

# handle the QUIETLY and REQUIRED arguments and set JPEG_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(JPEG DEFAULT_MSG JPEG_LIBRARIES JPEG_INCLUDE_DIRS)

# Deprecated declarations.
SET (NATIVE_JPEG_INCLUDE_PATH ${JPEG_INCLUDE_DIR} )
IF(JPEG_LIBRARY)
  GET_FILENAME_COMPONENT (NATIVE_JPEG_LIB_PATH ${JPEG_LIBRARY} PATH)
ENDIF(JPEG_LIBRARY)

MARK_AS_ADVANCED(JPEG_LIBRARY JPEG_INCLUDE_DIR JPEG_LIBRARY_DEBUG)

