project(port)

option(CPLUSPLUS "Compile foo.c CPP sources" OFF)
set(CMAKE_C_FLAGS_DEBUG "/Zi /Od /Ob0 /MDd /RTC1")

if(CPLUSPLUS)
	set(CPP_SOURCES main.c foo.c)
	foreach(f ${CPP_SOURCES})
        	set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
	endforeach()
endif()

set(BINNAME ol)
add_library(foolib OBJECT foo.c)
add_executable(${BINNAME}
	$<TARGET_OBJECTS:foolib>
	main.c
	header.h)

set(BINNAME nol)
add_executable(${BINNAME}
	foo.c
	main.c
	header.h)
