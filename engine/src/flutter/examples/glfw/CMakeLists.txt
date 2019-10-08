cmake_minimum_required(VERSION 3.15)
project(FlutterEmbedderGLFW)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11" )

add_executable(flutter_glfw FlutterEmbedderGLFW.cc)

############################################################
# GLFW
############################################################
find_path(GLFW_INCLUDE_PATH "glfw3.h"
    /usr/local/Cellar/glfw/3.3/include/GLFW/
    /usr/local/include/include/GLFW/
    /usr/include/GLFW)
include_directories(${GLFW_INCLUDE_PATH})
find_library(GLFW_LIB glfw /usr/local/Cellar/glfw/3.3/lib)
target_link_libraries(flutter_glfw ${GLFW_LIB})

############################################################
# Flutter Engine
############################################################
# This is assuming you've built a local version of the Flutter Engine.  If you
# downloaded yours is from the internet you'll have to change this.
include_directories(${CMAKE_SOURCE_DIR}/../../shell/platform/embedder)
find_library(FLUTTER_LIB flutter_engine PATHS ${CMAKE_SOURCE_DIR}/../../../out/host_debug_unopt)
target_link_libraries(flutter_glfw ${FLUTTER_LIB})

# Copy the flutter library here since the shared library
# name is `./libflutter_engine.dylib`.
add_custom_command(
        TARGET flutter_glfw POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
                ${FLUTTER_LIB}
                ${CMAKE_CURRENT_BINARY_DIR})
