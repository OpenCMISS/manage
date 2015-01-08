# - Find the native PNG includes and library
#
# This module defines
#  PNG_INCLUDE_DIR - Where to find png.h, etc.
#  PNG_LIBRARIES   - The libraries to link against to use PNG.
#  PNG_DEFINITIONS - You should add_definitons(${PNG_DEFINITIONS}) before compiling code that includes png library files.
#  PNG_FOUND       - If false, do not try to use PNG.
#
# also defined, but not for general use are
#  PNG_LIBRARY     - where to find the PNG library.
# None of the above will be defined unles zlib can be found.
# PNG depends on ZLIB

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

IF(PNG_FIND_QUIETLY)
  SET(_FIND_ZLIB_ARG QUIET)
ENDIF(PNG_FIND_QUIETLY)

# libpng 1.5.2 possible has a config file if we can find that we will use it
# otherwise use the alternative method.
FIND_FILE(PNG_CONFIG_FILE png-config.cmake PATH_SUFFIXES lib/cmake)

IF(PNG_CONFIG_FILE)
	INCLUDE(${PNG_CONFIG_FILE})
	MARK_AS_ADVANCED(${PNG_CONFIG_FILE})
ELSE(PNG_CONFIG_FILE)
	FIND_PACKAGE(ZLIB ${_FIND_ZLIB_ARG})
	
	IF(ZLIB_FOUND)
	  FIND_PATH(PNG_INCLUDE_DIR png.h
	  /usr/local/include/libpng             # OpenBSD
	  )
	
	  SET(PNG_NAMES ${PNG_NAMES} png libpng png12 libpng12)
	  FIND_LIBRARY(PNG_LIBRARY NAMES ${PNG_NAMES} )
	
	  SET(PNG_NAMES_DEBUG ${PNG_NAMES_DEBUG} pngd libpngd png12d libpng12d)
	  FIND_LIBRARY(PNG_LIBRARY_DEBUG NAMES ${PNG_NAMES_DEBUG} )
	
	  IF( NOT PNG_LIBRARY_DEBUG )
	    SET( PNG_LIBRARIES ${PNG_LIBRARY} )
	  ELSE( NOT PNG_LIBRARY_DEBUG )
	    # Very important to use lowercase 'debug' and 'optimized' for this to work
	    SET( PNG_LIBRARIES
	      debug ${PNG_LIBRARY_DEBUG}
	      optimized ${PNG_LIBRARY} )
	  ENDIF( NOT PNG_LIBRARY_DEBUG )
	  IF (PNG_LIBRARY AND PNG_INCLUDE_DIR)
	      # png.h includes zlib.h. Sigh.
	      SET(PNG_INCLUDE_DIRS ${PNG_INCLUDE_DIR} ${ZLIB_INCLUDE_DIR} )
	      SET(PNG_LIBRARIES ${PNG_LIBRARIES} ${ZLIB_LIBRARIES})
	
	      IF (CYGWIN)
	        IF(BUILD_SHARED_LIBS)
	           # No need to define PNG_USE_DLL here, because it's default for Cygwin.
	        ELSE(BUILD_SHARED_LIBS)
	          SET (PNG_DEFINITIONS -DPNG_STATIC)
	        ENDIF(BUILD_SHARED_LIBS)
	      ENDIF (CYGWIN)
	
	  ENDIF (PNG_LIBRARY AND PNG_INCLUDE_DIR)
	
	ENDIF(ZLIB_FOUND)
	
	# handle the QUIETLY and REQUIRED arguments and set PNG_FOUND to TRUE if
	# all listed variables are TRUE
	INCLUDE(FindPackageHandleStandardArgs)
	FIND_PACKAGE_HANDLE_STANDARD_ARGS(PNG  DEFAULT_MSG  PNG_LIBRARIES PNG_INCLUDE_DIRS)
	
	MARK_AS_ADVANCED(PNG_INCLUDE_DIR PNG_LIBRARY PNG_LIBRARY_DEBUG)
	
ENDIF(PNG_CONFIG_FILE)

