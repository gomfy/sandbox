project(test)

set(SOURCES foo.c)

foreach(f ${SOURCES})
        set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
endforeach()

add_executable(main
    main.c
    ${SOURCES})

if(MSVC)

endif()

