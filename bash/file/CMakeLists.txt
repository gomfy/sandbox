project(file) 

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(SOURCES test.c)
set(BINNAME main)

add_executable(${BINNAME}
    ${SOURCES}) 

