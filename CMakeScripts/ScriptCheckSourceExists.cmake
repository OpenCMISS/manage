# Script called within the component configuration to ensure if the associated source files are downloaded
if (NOT EXISTS "${FOLDER}/CMakeLists.txt")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E remove "${STAMP_DIR}/${COMPONENT}_SRC-download"
        COMMAND ${CMAKE_COMMAND} -E remove "${STAMP_DIR}/${COMPONENT}_SRC-gitclone-lastrun.txt"
        COMMAND ${CMAKE_COMMAND} --build ${BINDIR} --target ${COMPONENT}_SRC-download
    )
endif()