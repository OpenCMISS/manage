########################################################################
# Collect common arguments for components/subprojects
SET(COMPONENT_COMMON_DEFS )

# As the CMAKE_ARGS are a list themselves, we need to treat the ; in the (possible) list of module_paths
# specially. Therefore CMAKE has a special command LIST_SEPARATOR within the ExternalProject macros
# See also OCComponentSetupMacros.cmake:144
set(OC_LIST_SEPARATOR "-<ocm_list_sep>-") # just use anything unlikely to be passed as an actual variable string
STRING(REPLACE ";" ${OC_LIST_SEPARATOR} CMAKE_MODULE_PATH_ESC "${OPENCMISS_COMPONENT_MODULE_PATH}")
STRING(REPLACE ";" ${OC_LIST_SEPARATOR} OPENCMISS_PREFIX_PATH_ESC "${OPENCMISS_PREFIX_PATH}")

LIST(APPEND COMPONENT_COMMON_DEFS
    -DCMAKE_PREFIX_PATH=${OPENCMISS_PREFIX_PATH_ESC}
    -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH_ESC}
    -DPACKAGE_CONFIG_DIR=${COMMON_PACKAGE_CONFIG_DIR}
    -DCMAKE_NO_SYSTEM_FROM_IMPORTED=YES
    -DCMAKE_DEBUG_POSTFIX=${CMAKE_DEBUG_POSTFIX}
    -DCMAKE_POSITION_INDEPENDENT_CODE=YES # -fPIC flag - always enable
    -DOPENCMISS_INSTRUMENTATION=${OPENCMISS_INSTRUMENTATION}
    -DWARN_ALL=${OC_WARN_ALL}
    -DCHECK_ALL=${OC_CHECK_ALL}
    -DCMAKE_INSTALL_DEFAULT_COMPONENT_NAME=Development
)

# Use the correct install RPATH to enable binaries to find the shared libs (if any, ignored otherwise).
# See http://www.cmake.org/Wiki/CMake_RPATH_handling
#STRING(REPLACE ";" ${OC_LIST_SEPARATOR} OPENCMISS_LIBRARY_PATH_ESC "${OPENCMISS_LIBRARY_PATH}")
#list(APPEND COMPONENT_COMMON_DEFS 
#    -DCMAKE_INSTALL_RPATH=${OPENCMISS_LIBRARY_PATH_ESC}
#    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE)

# Forward verbosity if wanted
if (CMAKE_VERBOSE_MAKEFILE)
    list(APPEND COMPONENT_COMMON_DEFS -DCMAKE_VERBOSE_MAKEFILE=YES)
endif()

#message(STATUS "OpenCMISS components common definitions:\n${COMPONENT_COMMON_DEFS}")
