cmake_minimum_required(VERSION 3.15)
project(pseudoconsole_host LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(pseudoconsole_host pseudoconsole_host.cpp)

target_compile_definitions(pseudoconsole_host PRIVATE UNICODE _UNICODE)
target_link_libraries(pseudoconsole_host PRIVATE kernel32)
