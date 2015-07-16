cmake_minimum_required(VERSION 2.8.8)
project(ChromeExtras)
enable_testing()

list(APPEND CMAKE_MODULE_PATH "${LLVM_BUILD_DIR}/share/llvm/cmake")

# These tools are built using LLVM's build system, not Chromium's.
# The build script generates a shim CMakeLists.txt in the LLVM source tree,
# which simply forwards to this file.


# Use rpath to find the bundled standard C++ library.
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
if (APPLE)
  set(CMAKE_INSTALL_NAME_DIR "@rpath")
  set(CMAKE_INSTALL_RPATH "@executable_path/../lib")
else(UNIX)
  set(CMAKE_INSTALL_RPATH "\$ORIGIN/../lib")
endif()

include_directories("${CMAKE_SOURCE_DIR}/include"
                    "${CMAKE_SOURCE_DIR}/tools/clang/include"
                    "${CMAKE_BINARY_DIR}/include"
                    "${CMAKE_BINARY_DIR}/tools/clang/include")

link_directories("${CMAKE_SOURCE_DIR}/lib"
                 "${CMAKE_SOURCE_DIR}/tools/clang/lib"
                 "${CMAKE_BINARY_DIR}/lib"
                 "${CMAKE_BINARY_DIR}/tools/clang/lib")

# cr_add_test(
#   name
#   testprog
#   arguments...
#   )
function(cr_add_test name testprog)
  add_test(NAME ${name} COMMAND ${testprog} ${ARGN})
  add_dependencies(cr-check-all ${name})
endfunction(cr_add_test)

# Tests for all enabled tools can be run by building this target.
add_custom_target(cr-check-all COMMAND ${CMAKE_CTEST_COMMAND} -V)

function(cr_install)
  install(${ARGN} COMPONENT chrome-tools OPTIONAL)
endfunction(cr_install)

# Custom install target, so the chrome tools can be installed without installing
# all the other LLVM targets.
add_custom_target(cr-install COMMAND
  ${CMAKE_COMMAND} -D COMPONENT=chrome-tools -P cmake_install.cmake)

foreach(tool ${CHROMIUM_TOOLS})
  add_subdirectory(${tool})
endforeach(tool)
