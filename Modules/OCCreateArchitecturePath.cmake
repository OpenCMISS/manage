
function(CREATE_ARCHITECTURE_PATH TOOLCHAIN_MNEMONIC MPI_MNEMONIC VAR_NAME)

    set(OUTPUT_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/ArchPath/output.txt")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" "${CMAKE_CURRENT_SOURCE_DIR}/ArchPath/"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/ArchPath/"
        RESULT_VARIABLE RESULT
        OUTPUT_FILE "${OUTPUT_FILENAME}"
        ERROR_FILE "${OUTPUT_FILENAME}"
        )
 
    if ("${RESULT}" STREQUAL "0")
        file(STRINGS "${OUTPUT_FILENAME}" OUTPUT_CONTENTS)

        message(STATUS "${OUTPUT_CONTENTS}")
        foreach(line ${OUTPUT_CONTENTS})
            if ("${line}" MATCHES "ARCHITECTURE_PATH=*")
                message(STATUS "============= ARCHITECTURE_PATH: ${line}")
                set(${VAR_NAME} ${line} PARENT_SCOPE)
            endif ()
        endforeach()
    else ()
        message(STATUS "Things have gone pear shaped.")
        set(${VAR_NAME} "<error>" PARENT_SCOPE)
    endif ()
endfunction()
