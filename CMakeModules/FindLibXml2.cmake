# - Try to find LibXml2
# Once done this will define
#
#  LIBXML2_FOUND - System has LibXml2
#  LIBXML2_INCLUDE_DIR - The LibXml2 include directory
#  LIBXML2_LIBRARIES - The libraries needed to use LibXml2
#  LIBXML2_DEFINITIONS - Compiler switches required for using LibXml2
#  LIBXML2_XMLLINT_EXECUTABLE - The XML checking tool xmllint coming with LibXml2

# Copyright (c) 2006, Alexander Neundorf, <neundorf@kde.org>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.


IF (LIBXML2_INCLUDE_DIR AND LIBXML2_LIBRARY)
   # in cache already
   SET(LibXml2_FIND_QUIETLY TRUE)
ENDIF (LIBXML2_INCLUDE_DIR AND LIBXML2_LIBRARY)

INCLUDE(FindPackageMessage)
FUNCTION( PRINT_CMISS_BANNER MODULE )
	SET( PRINT_BANNER FALSE )
	FOREACH(_CURRENT_VAR ${ARGN})
		IF( NOT _CURRENT_VAR )
			SET( PRINT_BANNER TRUE )
		ENDIF( NOT _CURRENT_VAR )
	ENDFOREACH(_CURRENT_VAR ${ARGN})
	IF( PRINT_BANNER )
		MESSAGE( STATUS "\n-- CMISS FIND ${MODULE} MODULE --" )
	ELSE( PRINT_BANNER )
		FIND_PACKAGE_MESSAGE( CMISS_${MODULE} "\n-- CMISS FIND ${MODULE} MODULE --" "CMISS_${MODULE}_DETAILS" )
	ENDIF( PRINT_BANNER )
ENDFUNCTION( PRINT_CMISS_BANNER )

IF (NOT WIN32)
   # use pkg-config to get the directories and then use these values
   # in the FIND_PATH() and FIND_LIBRARY() calls
   FIND_PACKAGE(PkgConfig)
   PKG_CHECK_MODULES(PC_LIBXML libxml-2.0)
   SET(LIBXML2_DEFINITIONS ${PC_LIBXML_CFLAGS_OTHER})
ENDIF (NOT WIN32)

# I have no way of knowing if a user is linking to the static library
# or not, I am just assuming this for the mean time.
SET(LIBXML2_DEFINITIONS ${LIBXML2_DEFINITIONS} LIBXML_STATIC )

FIND_PATH(LIBXML2_INCLUDE_DIR libxml/xpath.h
   HINTS
   ${PC_LIBXML_INCLUDEDIR}
   ${PC_LIBXML_INCLUDE_DIRS}
   PATH_SUFFIXES libxml2
   )

FIND_LIBRARY(LIBXML2_LIBRARY NAMES xml2 libxml2
   HINTS
   ${PC_LIBXML_LIBDIR}
   ${PC_LIBXML_LIBRARY_DIRS}
   )

FIND_LIBRARY(LIBXML2_LIBRARY_DEBUG NAMES xml2d libxml2d
   HINTS
   ${PC_LIBXML_LIBDIR}
   ${PC_LIBXML_LIBRARY_DIRS}
   )

# Per-recommendation
SET(LIBXML2_INCLUDE_DIRS ${LIBXML2_INCLUDE_DIR})
IF( NOT LIBXML2_LIBRARY_DEBUG )
	SET( LIBXML2_LIBRARIES ${LIBXML2_LIBRARY} )
ELSE( NOT LIBXML2_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( LIBXML2_LIBRARIES
		debug ${LIBXML2_LIBRARY_DEBUG}
		optimized ${LIBXML2_LIBRARY} )
ENDIF( NOT LIBXML2_LIBRARY_DEBUG )

FIND_PROGRAM(LIBXML2_XMLLINT_EXECUTABLE xmllint)
# for backwards compat. with KDE 4.0.x:
SET(XMLLINT_EXECUTABLE "${LIBXML2_XMLLINT_EXECUTABLE}")


# handle the QUIETLY and REQUIRED arguments and set LIBXML2_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(LibXml2 DEFAULT_MSG LIBXML2_LIBRARIES LIBXML2_INCLUDE_DIRS)

MARK_AS_ADVANCED(LIBXML2_INCLUDE_DIR LIBXML2_LIBRARY LIBXML2_LIBRARY_DEBUG LIBXML2_XMLLINT_EXECUTABLE)

