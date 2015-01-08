# - Try to find gdcm
# Once done this will define
#
#  LIBGDCM_FOUND - System has gdcm
#  LIBGDCM_INCLUDE_DIRS - The gdcm include directory
#  LIBGDCM_LIBRARIES - The libraries needed to use gdcm
#  LIBGDCM_DEFINITIONS - Compiler switches required for using gdcm <-- not implemented yet!

 # ***** BEGIN LICENSE BLOCK *****
 # Version: MPL 1.1/GPL 2.0/LGPL 2.1
 #
 # The contents of this file are subject to the Mozilla Public License Version
 # 1.1 (the "License"); you may not use this file except in compliance with
 # the License. You may obtain a copy of the License at
 # http://www.mozilla.org/MPL/
 #
 # Software distributed under the License is distributed on an "AS IS" basis,
 # WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 # for the specific language governing rights and limitations under the
 # License.
 #
 # The Original Code is cmgui
 #
 # The Initial Developer of the Original Code is
 # Auckland Uniservices Ltd, Auckland, New Zealand.
 # Portions created by the Initial Developer are Copyright (C) 2005
 # the Initial Developer. All Rights Reserved.
 #
 # Contributor(s): 
 #
 # Alternatively, the contents of this file may be used under the terms of
 # either the GNU General Public License Version 2 or later (the "GPL"), or
 # the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 # in which case the provisions of the GPL or the LGPL are applicable instead
 # of those above. If you wish to allow use of your version of this file only
 # under the terms of either the GPL or the LGPL, and not to allow others to
 # use your version of this file under the terms of the MPL, indicate your
 # decision by deleting the provisions above and replace them with the notice
 # and other provisions required by the GPL or the LGPL. If you do not delete
 # the provisions above, a recipient may use your version of this file under
 # the terms of any one of the MPL, the GPL or the LGPL.
 #
 # ***** END LICENSE BLOCK ***** */


IF( LIBGDCM_INCLUDE_DIR AND LIBGDCM_LIBRARY )
   # in cache already
   SET( LIBGDCM_FIND_QUIETLY TRUE )
ENDIF( LIBGDCM_INCLUDE_DIR AND LIBGDCM_LIBRARY )

FIND_PATH( LIBGDCM_INCLUDE_DIR nglib.h 
	PATH_SUFFIXES gdcm )

SET( LIBGDCM_NAMES ${LIBGDCM_NAMES} gdcm )
FIND_LIBRARY( LIBGDCM_LIBRARY NAMES ${LIBGDCM_NAMES} )

SET( LIBGDCM_NAMES_DEBUG ${LIBGDCM_NAMES_DEBUG} gdcmd )
FIND_LIBRARY( LIBGDCM_LIBRARY_DEBUG NAMES ${LIBGDCM_NAMES_DEBUG} )

# I'd like to (but don't know how to) consult the config variable to see 
# if this is important but for now if I find the optimised library I won't
# be to worried about the debug version
SET( LIBGDCM_INCLUDE_DIRS ${LIBGDCM_INCLUDE_DIR} )
IF( NOT LIBGDCM_LIBRARY_DEBUG )
	SET( LIBGDCM_LIBRARIES ${LIBGDCM_LIBRARY} )
ELSE( NOT LIBGDCM_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( LIBGDCM_LIBRARIES
		debug ${LIBGDCM_LIBRARY_DEBUG}
		optimized ${LIBGDCM_LIBRARY} )
ENDIF( NOT LIBGDCM_LIBRARY_DEBUG )


INCLUDE(FindPackageHandleStandardArgs)

# handle the QUIETLY and REQUIRED arguments and set LIBGDCM_FOUND to TRUE if 
# all listed variables are TRUE
FIND_PACKAGE_HANDLE_STANDARD_ARGS( LIBGDCM DEFAULT_MSG LIBGDCM_LIBRARIES LIBGDCM_INCLUDE_DIRS )

MARK_AS_ADVANCED( LIBGDCM_INCLUDE_DIR LIBGDCM_LIBRARY LIBGDCM_LIBRARY_DEBUG )

