project(test)

set(SOURCES foo.c)
set(BINNAME main)

foreach(f ${SOURCES})
        set_source_files_properties(${f} PROPERTIES LANGUAGE CXX)
endforeach()

add_executable(${BINNAME}
	main.c
	${SOURCES})

if(MSVC)
	target_compile_definitions(${BINNAME} PRIVATE MSpc)
    	target_compile_options(${BINNAME} PRIVATE /Bd /w /MT /F2000000)
    	target_link_options(${BINNAME} PRIVATE ws2_32.lib libcmt.lib advapi32.lib wsock32.lib /link /LARGEADDRESSAWARE)
endif()

