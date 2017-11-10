
# Remove components which are not required according to the configuration.

set(OC_REQUIRED_COMPONENTS ${OPENCMISS_COMPONENTS})
if (OPENCMISS_DEPENDENCIES_ONLY)
    list(REMOVE_ITEM OC_REQUIRED_COMPONENTS ZINC IRON)
endif ()

# TODO: Implement the following logic into this script.
# if (OC_USE_LAPACK AND (OC_DEPENDENCIES_ONLY OR OC_USE_IRON OR (OC_USE_OPTPP AND OPTPP_WITH_BLAS)))
if (OPENCMISS_LIBRARIES_ONLY)
    set(OC_REQUIRED_COMPONENTS IRON ZINC)
endif ()

foreach(_COMPONENT ${OPENCMISS_COMPONENTS})
    if (NOT OC_USE_${_COMPONENT})
        list(REMOVE_ITEM OC_REQUIRED_COMPONENTS ${_COMPONENT})
    endif ()
endforeach()

if (NOT OC_USE_IRON OR OPENCMISS_ZINC_ONLY)
    list(REMOVE_ITEM OC_REQUIRED_COMPONENTS IRON)
    foreach(_COMPONENT ${OPENCMISS_IRON_ONLY_COMPONENTS})
        list(REMOVE_ITEM OC_REQUIRED_COMPONENTS ${_COMPONENT})
    endforeach()
endif ()

if (NOT OC_USE_ZINC OR OPENCMISS_IRON_ONLY)
    list(REMOVE_ITEM OC_REQUIRED_COMPONENTS ZINC)
    foreach(_COMPONENT ${OPENCMISS_ZINC_ONLY_COMPONENTS})
        list(REMOVE_ITEM OC_REQUIRED_COMPONENTS ${_COMPONENT})
    endforeach()
endif ()

set(OC_BUILD_LOCAL_COMPONENTS)
foreach(_component ${OC_REQUIRED_COMPONENTS})
    find_package(${_component} ${${_component}_VERSION} QUIET)
    if (NOT ${_component}_FOUND)
        list(APPEND OC_BUILD_LOCAL_COMPONENTS ${_component})
    endif ()
endforeach()
