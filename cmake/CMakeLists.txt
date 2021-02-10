project(test)

option(EXTERNC "Declare global as extern C" OFF)

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

if(EXTERNC)
	target_compile_definitions(${BINNAME} 
		PRIVATE  
		-DEXTERNCDEF)
endif()
