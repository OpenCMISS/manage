# - Find TIFF library
# Find the native TIFF includes and library
#
# This module defines
#  TIFF_INCLUDE_DIRS - Where to find tiff.h, etc
#  TIFF_LIBRARIES    - Libraries to link against to use TIFF.
#  TIFF_DEFINITIONS  - List of definitions when using zlib.
#  TIFF_FOUND        - If false, do not try to use TIFF.
# also defined, but not for general use are
#  TIFF_LIBRARY, where to find the TIFF library.

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

IF(TIFF_FIND_QUIETLY)
	SET(_FIND_QUIETLY_ARG QUIET)
ENDIF(TIFF_FIND_QUIETLY)

# TIFF has conditional dependencies on zlib and jpeg
FIND_PACKAGE(ZLIB ${_FIND_QUIETLY_ARG})
FIND_PACKAGE(JPEG ${_FIND_QUIETLY_ARG})

FIND_PATH(TIFF_INCLUDE_DIR tiff.h)

SET(TIFF_NAMES ${TIFF_NAMES} tiff libtiff libtiff3)
FIND_LIBRARY(TIFF_LIBRARY NAMES ${TIFF_NAMES} )

SET(TIFF_NAMES_DEBUG ${TIFF_NAMES_DEBUG} tiffd libtiffd libtiff3d)
FIND_LIBRARY(TIFF_LIBRARY_DEBUG NAMES ${TIFF_NAMES_DEBUG} )

# Per-recommendation
SET(TIFF_INCLUDE_DIRS ${TIFF_INCLUDE_DIR})
IF( NOT TIFF_LIBRARY_DEBUG )
	SET( TIFF_LIBRARIES ${TIFF_LIBRARY} ${ZLIB_LIBRARY} ${JPEG_LIBRARY})
ELSE( NOT TIFF_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( TIFF_LIBRARIES
		debug ${TIFF_LIBRARY_DEBUG} debug ${ZLIB_LIBRARY_DEBUG} debug ${JPEG_LIBRARY_DEBUG}
		optimized ${TIFF_LIBRARY} optimized ${ZLIB_LIBRARY} optimized ${JPEG_LIBRARY})
ENDIF( NOT TIFF_LIBRARY_DEBUG )
SET(TIFF_DEFINITIONS )

# handle the QUIETLY and REQUIRED arguments and set TIFF_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(TIFF  DEFAULT_MSG  TIFF_LIBRARIES  TIFF_INCLUDE_DIRS)

MARK_AS_ADVANCED(TIFF_INCLUDE_DIR TIFF_LIBRARY TIFF_LIBRARY_DEBUG)

