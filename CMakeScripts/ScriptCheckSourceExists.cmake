# Script called within the component configuration to ensure if the associated source files are downloaded
if (NOT EXISTS "${FOLDER}/CMakeLists.txt")
    file(GLOB STAMPS ${STAMP_DIR}/${COMPONENT}_SRC*)
    file(REMOVE ${STAMPS})
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${BINDIR} --target ${COMPONENT}_SRC-download)
endif()