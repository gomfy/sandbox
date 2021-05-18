project(test-ampl-anomalies)

option(FIX "Declare global as extern C and declare functions properly" OFF)
option(CPLUSPLUS "Compile foo.c and bar.c as CPP sources" OFF)

set(CMAKE_C_FLAGS_DEBUG "/Zi /Od /Ob0 /MDd /RTC1")

set(SOURCES 
	foo.c
	bar.c)

set(BINNAME main)

if(CPLUSPLUS)
	foreach(f ${SOURCES})
        	set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
	endforeach()
endif()

add_executable(${BINNAME}
	main.c
	${SOURCES})

if(FIX)
	target_compile_definitions(${BINNAME} 
		PRIVATE  
		-DFIX)
endif()
