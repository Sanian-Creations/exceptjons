# How to build:
# cmake -B build -G "Visual Studio 16 2019"
# cmake --build build --config Release

cmake_minimum_required(VERSION 3.1)
project(jai_catch)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(FATAL_ERROR "This project can only be built on Windows! (for now)")
endif()

if(NOT MSVC)
    message(FATAL_ERROR "Only MSVC is supported (because it is the only compiler that implements Structured Exception Handling)")
endif()

add_library(jai_catch_windows STATIC jai_catch_windows.c)
target_compile_options(jai_catch_windows PRIVATE /W4)

# Set the location for the output file. Override ..._RELEASE specifically.
# If you override it without the ..._RELEASE then it will use that directory for all output
# configurations but wrap everything in an additional directory corresponding to that config, like
# out/Debug/foo.exe and out/Release/foo.exe
set_target_properties(jai_catch_windows PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/lib"
)

