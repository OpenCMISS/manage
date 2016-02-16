set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(OC_SUPPORT_DIR ${OpenCMISS_BINARY_DIR}/support)
string(TIMESTAMP NOW "%Y-%m-%d_%H-%M")
##
# CMake logging
# -------------
#
# The build system creates a build log in order to ease the support process.
set(OC_BUILDLOG ${OC_SUPPORT_DIR}/configure_builds_${NOW}.log)

##
# The function :command:`log()` can be used to produce screen output as well as write messages to the build log::
#
#     log(MESSAGE [LOGLEVEL])
#
# See also: :ref:`loglevels`
function(log msg)
    #message(STATUS "@@@@@ log(\"${msg}\")")
    if (ARGC GREATER 1)
        set(level ${ARGV1})
        set(level_prefix "${level} - ")
    else()
        set(level "SCREEN")
        set(level_prefix "")
    endif()
    # Write to config log file
    if (level IN_LIST OC_CONFIG_LOG_LEVELS)
        #message(STATUS "@@@@@ writing to file")    
        if (NOT EXISTS "${OC_BUILDLOG}")
            file(WRITE "${OC_BUILDLOG}" "${level_prefix}${msg}\r\n")
        else()
            file(APPEND "${OC_BUILDLOG}" "${level_prefix}${msg}\r\n")
        endif()
    endif()
    # Also write to console output
    if (level STREQUAL "WARNING")
        message(WARNING "${msg}")
    elseif(level STREQUAL "ERROR")
        message(FATAL_ERROR "${msg}")
    elseif (level STREQUAL "SCREEN" OR OC_CONFIG_LOG_TO_SCREEN)
        message(STATUS "${level_prefix}${msg}")
    endif()
endfunction()

# Just a convenience hack to have OpenCMISS copy the developer defaults config file over.
if (DEFINED EVIL OR EVIL)
    set(EVEL ${EVIL})
endif()
if (DEFINED EVEL OR EVEL)
    if (NOT EXISTS "${PROJECT_SOURCE_DIR}/OpenCMISSDeveloper.cmake")
        log("Creating OpenCMISSDeveloper file in ${PROJECT_SOURCE_DIR}")
        configure_file(
            "${PROJECT_SOURCE_DIR}/Templates/OpenCMISSDeveloper.template.cmake"
            "${PROJECT_SOURCE_DIR}/OpenCMISSDeveloper.cmake"
            COPYONLY)
        set(EVIL_MESSAGE "Being a Developer: ${EVEL}. Copied the OpenCMISSDeveloper template.")
    else()
        set(EVIL_MESSAGE "OpenCMISSDeveloper script already copied. Not overwriting.")
    endif()
endif()

function(printnextsteps)
    message(STATUS "@@@@@@@@@@@@@@@@@@@ NEXT STEPS @@@@@@@@@@@@@@@@@@@@@@")
    message(STATUS "@")
    message(STATUS "@ - Change ${OPENCMISS_LOCALCONFIG} according to your setup/needs")
    if (DEFINED EVIL)
        message(STATUS "@ - Change ${CMAKE_CURRENT_SOURCE_DIR}/OpenCMISSDeveloper.cmake according to your developing setup/needs (Overrides anything in OpenCMISSLocalConfig!)")        
    endif()
    message(STATUS "@ - Build the 'opencmiss' target (e.g. '${CMAKE_MAKE_PROGRAM} opencmiss') to start the build process")
    message(STATUS "@")
    message(STATUS "@ Having trouble? Follow the galaxy hitchhiker's advice:")
    message(STATUS "@ DONT PANIC ... and:")
    message(STATUS "@ - Refer to http://staging.opencmiss.org/documentation/cmake/docs/config/index.html for customization instructions")
    message(STATUS "@ - Build the 'support' target to get help! (e.g. '${CMAKE_MAKE_PROGRAM} support')")
    message(STATUS "@")
    message(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
endfunction()