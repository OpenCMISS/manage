if (NOT EXISTS ${FOLDER}/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} --build ${BINDIR} --target ${TARGET})
endif()