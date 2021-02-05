project(test)

set(SOURCES 
	foo.c
	bar.c)

set(BINNAME main)

foreach(f ${SOURCES})
        set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
endforeach()

add_executable(${BINNAME}
	main.c
	${SOURCES})
