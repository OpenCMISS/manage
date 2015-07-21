########### END OF GENERATED PART ###########

# Configure use of MPI
set(_HAVE_MPI_WRAPPER NO)
foreach(lang C CXX Fortran)
    if (MPI_${lang}_COMPILER)
        if (EXISTS ${MPI_${lang}_COMPILER})
            set(CMAKE_${lang}_COMPILER ${MPI_${lang}_COMPILER})
            set(_HAVE_MPI_WRAPPER YES)
        else()
            message(FATAL_ERROR "The MPI compiler ${MPI_${lang}_COMPILER} could not be found.")
        endif()
    endif() 
endforeach()
# Modern MPI implementations provide wrappers that avoid setting libs/incs/flags manually.
# However, e.g. on windows this is not yet provided, so we need manual settings here. 
if (NOT _HAVE_MPI_WRAPPER)
    # Instead of calling FindMPI again, we use the exported config from the OpenCMISS build environment;
    # this find_package call is supposed to be executed BEFORE any project command is issued; FindMPI however
    # may not be working in future versions if issued before any project command (which is the "normal" cmake case)
    foreach(lang C CXX Fortran)
        if (MPI_${lang}_INCLUDE_PATH)
            include_directories(${MPI_${lang}_INCLUDE_PATH})
        endif()
        if (MPI_${lang}_INCLUDE_PATH)
            link_libraries(MPI_${lang}_LIBRARIES)
        endif()
        if (MPI_${lang}_COMPILE_FLAGS)
            set(CMAKE_${lang}_FLAGS "${CMAKE_${lang}_FLAGS} ${MPI_${lang}_COMPILE_FLAGS}")
        endif()
    endforeach()
endif()
unset(_HAVE_MPI_WRAPPER)