# Return the compiler path for the given toolchain mnemonic.
function(GET_COMPILER_PATH_FOR_TOOLCHAIN TOOLCHAIN_MNEMONIC VAR_NAME)

    set(OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/CompilerPath/")
    file(MAKE_DIRECTORY "${OUTPUT_DIRECTORY}")
    set(OUTPUT_FILENAME "${OUTPUT_DIRECTORY}/output.txt")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" -DTOOLCHAIN=${TOOLCHAIN_MNEMONIC} -DOPENCMISS_CMAKE_MODULE_PATH=${OPENCMISS_CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/CompilerPath/"
        WORKING_DIRECTORY "${OUTPUT_DIRECTORY}"
        RESULT_VARIABLE RESULT
        OUTPUT_FILE "${OUTPUT_FILENAME}"
        ERROR_FILE "${OUTPUT_FILENAME}"
    )

    if ("${RESULT}" STREQUAL "0")
        file(STRINGS "${OUTPUT_FILENAME}" OUTPUT_CONTENTS)

        foreach(line ${OUTPUT_CONTENTS})
            if ("${line}" MATCHES "COMPILER_PART=*")
                string(SUBSTRING "${line}" 14 -1 CREATED_COMPILER_PATH)
                set(${VAR_NAME} ${CREATED_COMPILER_PATH} PARENT_SCOPE)
            endif ()
        endforeach()
        file(REMOVE_RECURSE "${OUTPUT_DIRECTORY}")
    else ()
        message(STATUS "Things have gone pear shaped.")
        set(${VAR_NAME} "error" PARENT_SCOPE)
    endif ()
endfunction()
