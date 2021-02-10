project(test)

option(FIX "Declare global as extern C and declare functions properly" OFF)

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

if(FIX)
	target_compile_definitions(${BINNAME} 
		PRIVATE  
		-DFIX)
endif()
