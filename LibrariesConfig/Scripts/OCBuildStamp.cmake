
string(TIMESTAMP NOW "%Y-%m-%d, %H:%M")
file(APPEND "${LOGFILE}" "Build of OpenCMISS component ${COMPONENT_NAME} started at ${NOW}\r\n")

