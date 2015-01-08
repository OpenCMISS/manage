# - Try to find netgen
# Once done this will define
#
#  NETEGN_FOUND - System has netgen
#  NETGEN_INCLUDE_DIR - The netgen include directory
#  NETGEN_LIBRARIES - The libraries needed to use neten
#  NETGEN_DEFINITIONS - Compiler switches required for using netgen <-- not implemented yet!

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


IF( NETGEN_INCLUDE_DIR AND NETGEN_LIBRARY )
   # in cache already
   SET( NETGEN_FIND_QUIETLY TRUE )
ENDIF( NETGEN_INCLUDE_DIR AND NETGEN_LIBRARY )

FIND_PATH( NETGEN_INCLUDE_DIR nglib.h 
	PATH_SUFFIXES netgen )

SET( NETGEN_NAMES ${NETGEN_NAMES} nglib )
FIND_LIBRARY( NETGEN_LIBRARY NAMES ${NETGEN_NAMES} )

SET( NETGEN_NAMES_DEBUG ${NETGEN_NAMES_DEBUG} nglibd )
FIND_LIBRARY( NETGEN_LIBRARY_DEBUG NAMES ${NETGEN_NAMES_DEBUG} )

# I'd like to (but don't know how to) consult the config variable to see 
# if this is important but for now if I find the optimised library I won't
# be to worried about the debug version
SET(NETGEN_INCLUDE_DIRS ${NETGEN_INCLUDE_DIR})
IF( NOT NETGEN_LIBRARY_DEBUG )
	SET( NETGEN_LIBRARIES ${NETGEN_LIBRARY} )
ELSE( NOT NETGEN_LIBRARY_DEBUG )
	# Very important to use lowercase 'debug' and 'optimized' for this to work
	SET( NETGEN_LIBRARIES
		debug ${NETGEN_LIBRARY_DEBUG}
		optimized ${NETGEN_LIBRARY} )
ENDIF( NOT NETGEN_LIBRARY_DEBUG )

# handle the QUIETLY and REQUIRED arguments and set NETGEN_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS( NETGEN DEFAULT_MSG NETGEN_LIBRARIES NETGEN_INCLUDE_DIRS )

MARK_AS_ADVANCED( NETGEN_INCLUDE_DIR NETGEN_LIBRARY NETGEN_LIBRARY_DEBUG )

