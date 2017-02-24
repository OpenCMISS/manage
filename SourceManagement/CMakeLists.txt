

########################################################################################################################
function(addSourceManagementTargets COMPONENT_NAME SOURCE_DIR)
    # Convention: github repo is the lowercase equivalent of the component name
    string(TOLOWER ${COMPONENT_NAME} REPO_NAME)

    # Git clone mode
    if(GIT_FOUND)
        # Construct the repository name 
        if (NOT ${COMPONENT_NAME}_REPO)
            if(GITHUB_USERNAME)
                SET(_GITHUB_USERNAME ${GITHUB_USERNAME})
            else()
                SET(_GITHUB_USERNAME ${GITHUB_ORGANIZATION})
            endif()
            if (GITHUB_USE_SSL)
                SET(GITHUB_PROTOCOL "git@github.com:")
            else()
                SET(GITHUB_PROTOCOL "https://github.com/")
            endif()
            set(${COMPONENT_NAME}_REPO ${GITHUB_PROTOCOL}${_GITHUB_USERNAME}/${REPO_NAME})
        endif()

        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_download
            COMMAND ${GIT_EXECUTABLE} clone ${${COMPONENT_NAME}_REPO} .
            COMMAND ${GIT_EXECUTABLE} checkout ${${COMPONENT_NAME}_BRANCH}
            COMMENT "Cloning ${COMPONENT_NAME} sources"
            WORKING_DIRECTORY "${SOURCE_DIR}"
        )

        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update
            DEPENDS ${OC_SM_PREFIX}${COMPONENT_NAME}_sources
            COMMAND ${GIT_EXECUTABLE} pull
            COMMAND ${GIT_EXECUTABLE} checkout ${${COMPONENT_NAME}_BRANCH}
            # We can't have this here which binary dir should we be removing the stamp files from?
            # COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/${OC_EXTPROJ_STAMP_DIR}/*-build
            COMMENT "Updating ${COMPONENT_NAME} sources"
            WORKING_DIRECTORY "${SOURCE_DIR}"
        )

    # Fallback: Download the current version branch as zip
    else()
        # Unless explicitly specified, use the GitHub repository location
        if (NOT ${COMPONENT_NAME}_REPO)
            set(${COMPONENT_NAME}_REPO https://github.com/${GITHUB_ORGANIZATION}/${REPO_NAME})
        endif()

        set(_FILENAME ${${COMPONENT_NAME}_BRANCH}.tar.gz)
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_download
            COMMAND ${CMAKE_COMMAND}
                -DMODE=Download
                -DURL=${${COMPONENT_NAME}_REPO}/archive/${_FILENAME}
                -DTARGET="${SOURCE_DIR}/${_FILENAME}"
                -P ${CMAKE_CURRENT_SOURCE_DIR}/Scripts/OCSourceManager.cmake
            COMMENT "Downloading ${COMPONENT_NAME} sources"
        )

        # For tarballs, update is the same as download!
        add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update
            DEPENDS ${OC_SM_PREFIX}${REPO_NAME}_download
            # We can't have this here which binary dir should we be removing the stamp files from?
            # COMMAND ${CMAKE_COMMAND} -E remove -f ${BINARY_DIR}/${OC_EXTPROJ_STAMP_DIR}/*-build
            COMMENT "Updating ${COMPONENT_NAME} sources"
        )
    endif()
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_download PROPERTIES FOLDER "Source management")
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_update PROPERTIES FOLDER "Source management")

    # Add extra target that makes sure the source files are being present
    # Triggers build of ${OC_SM_PREFIX}${REPO_NAME}_download if the directory does not exist or 
    # no CMakeLists.txt is found in the target source directory.
    add_custom_target(${OC_SM_PREFIX}${COMPONENT_NAME}_sources
        COMMAND ${CMAKE_COMMAND}
            -DMODE=Check
            -DCOMPONENT=${REPO_NAME}
            -DSRC_DIR=${SOURCE_DIR}
            -DBIN_DIR=${CMAKE_CURRENT_BINARY_DIR}
            -DTARGET_PREFIX=${OC_SM_PREFIX}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/Scripts/OCSourceManager.cmake
        COMMENT "Checking ${COMPONENT_NAME} sources are present"
    )
    set_target_properties(${OC_SM_PREFIX}${COMPONENT_NAME}_sources PROPERTIES FOLDER "Internal")

    add_custom_target(${OC_SM_PREFIX}${REPO_NAME}_update_force
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${SOURCE_DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${SOURCE_DIR}"
        COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${OC_SM_PREFIX}${REPO_NAME}_download
        COMMENT "Forced update of ${COMPONENT_NAME} - removing and downloading"
    )
    set_target_properties(${OC_SM_PREFIX}${REPO_NAME}_update_force PROPERTIES FOLDER "Source management")

endfunction()


set(COMMON_DEPENDENCIES GTEST ZLIB LIBXML2 LAPACK BZIP2 SZIP HDF5 FIELDML-API)
set(IRON_DEPENDENCIES SCOTCH PLAPACK SCALAPACK PARMETIS MUMPS SUITESPARSE SUPERLU HYPRE SUPERLU_DIST SUNDIALS PASTIX SOWING PETSC SLEPC LIBCELLML CELLML LLVM CLANG CSIM)
set(ZINC_DEPENDENCIES JPEG NETGEN FREETYPE FTGL GLEW OPTPP PNG TIFF GDCM-ABI IMAGEMAGICK ITK)

set(ALL_SOURCE_COMPONENTS IRON ZINC ${IRON_DEPENDENCIES} ${ZINC_DEPENDENCIES} ${COMMON_DEPENDENCIES})

##############################################################
# Compute directories
message(STATUS "OPENCMISS_LIBRARIES_SOURCE_DIR: ${OPENCMISS_LIBRARIES_SOURCE_DIR}")
message(STATUS "OPENCMISS_DEPENDENCIES_SOURCE_DIR: ${OPENCMISS_DEPENDENCIES_SOURCE_DIR}")
message(STATUS "GITHUB_USERNAME: ${GITHUB_USERNAME}")
message(STATUS "GITHUB_ORGANIZATION: ${GITHUB_ORGANIZATION}")

# GITHUB_ORGANIZATION: For the default source locations, we use the OpenCMISS github organizations to group the components sources.
#                      Those are used to both clone the git repo in development mode or generate the path to the zipped source file on github. 
foreach (COMPONENT_NAME ALL_SOURCE_COMPONENTS)
    string(TOLOWER ${COMPONENT_NAME} FOLDER_NAME)
    if (COMPONENT_NAME STREQUAL "IRON" OR COMPONENT_NAME STREQUAL "ZINC")
        set(COMPONENT_SOURCE_DIR "${OPENCMISS_LIBRARIES_SOURCE_DIR}/${FOLDER_NAME}")
        set(GITHUB_ORGANIZATION OpenCMISS)
    else ()
        set(COMPONENT_SOURCE_DIR "${OPENCMISS_DEPENDENCIES_SOURCE_DIR}/${FOLDER_NAME}")
        if (COMPONENT_NAME STREQUAL "GTEST")
            set(GITHUB_ORGANIZATION OpenCMISS-Utilities)
        else ()
            set(GITHUB_ORGANIZATION OpenCMISS-Dependencies)
        endif ()
    endif ()
    addSourceManagementTargets(${COMPONENT_NAME} ${COMPONENT_SOURCE_DIR})
    
    list(APPEND COMPONENT_SOURCE_TARGETS ${OC_SM_PREFIX}${COMPONENT_NAME}_sources)
endforeach ()



