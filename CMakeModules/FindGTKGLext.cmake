# - Try to find GTKGLext
# Once done this will define
#
#  GTKGLEXT_FOUND - System has GTKGLext
#  GTKGLEXT_INCLUDE_DIRS - The GTKGLext include directory
#  GTKGLEXT_LIBRARIES - The libraries needed to use GTKGLext

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
 # Portions created by the Initial Developer are Copyright (C) 2012
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


IF (GTKGLEXT_INCLUDE_DIR)
  # Already in cache, be silent
  SET(GTKGLext_FIND_QUIETLY TRUE)
ENDIF (GTKGLEXT_INCLUDE_DIR)

IF (NOT WIN32)
   # use pkg-config to get the directories and then use these values
   # in the FIND_PATH() and FIND_LIBRARY() calls
   FIND_PACKAGE(PkgConfig)
   PKG_CHECK_MODULES(PC_GTKGLEXT gdkglext-x11-1.0)
ENDIF (NOT WIN32)

FIND_PATH(GTKGLEXT_INCLUDE_DIR gdk/gdkgl.h
   HINTS
   ${PC_GTKGLEXT_INCLUDEDIR}
   ${PC_GTKGLEXT_INCLUDE_DIRS}
   PATH_SUFFIXES gtkglext-1.0)
   
FIND_PATH(GDKGLEXT_INCLUDE_DIR gdkglext-config.h
   HINTS
   ${PC_GTKGLEXT_INCLUDEDIR}
   ${PC_GTKGLEXT_INCLUDE_DIRS}
   PATH_SUFFIXES include)
   
SET(GTKGLEXT_NAMES ${GTKGLEXT_NAMES} gtkglext-x11-1.0 gdkglext-x11-1.0)
FIND_LIBRARY(GTKGLEXT_LIBRARY NAMES ${GTKGLEXT_NAMES})

# Per-recommendation
SET(GTKGLEXT_INCLUDE_DIRS ${GTKGLEXT_INCLUDE_DIR} ${GTKGLEXT_INCLUDE_DIR} ${GDKGLEXT_INCLUDE_DIR} ) 
SET(GTKGLEXT_LIBRARIES ${GTKGLEXT_LIBRARY} )

# handle the QUIETLY and REQUIRED arguments and set GTKGLEXT_FOUND to TRUE if 
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(GTKGLext DEFAULT_MSG GTKGLEXT_LIBRARIES GTKGLEXT_INCLUDE_DIRS)

MARK_AS_ADVANCED(GTKGLEXT_LIBRARY GTKGLEXT_INCLUDE_DIR)

