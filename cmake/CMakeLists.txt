project(test)

set(SOURCES main.c foo.c)

foreach(f ${SOURCES})
        set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
endforeach()

add_executable(main
    ${SOURCES})

if(MSVC)

endif()

