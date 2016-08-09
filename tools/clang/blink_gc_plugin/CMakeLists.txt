set(LIBRARYNAME BlinkGCPlugin)

set(plugin_sources
  BlinkGCPlugin.cpp
  Edge.cpp
  RecordInfo.cpp)

if(WIN32)
  # Clang doesn't support loadable modules on Windows. Unfortunately, building
  # the plugin as a static library and linking clang against it doesn't work.
  # Since clang doesn't reference any symbols in our static library, the linker
  # strips it out completely.
  # Instead, we rely on the fact that the SOURCES property of a target is no
  # read-only after CMake 3.1 and use it to compile the plugin directly into
  # clang...
  cmake_minimum_required(VERSION 3.1)
  # Paths must be absolute, since we're modifying a target in another directory.
  set(absolute_sources "")
  foreach(source ${plugin_sources})
    list(APPEND absolute_sources ${CMAKE_CURRENT_SOURCE_DIR}/${source})
  endforeach()
  set_property(TARGET clang APPEND PROPERTY SOURCES ${absolute_sources})

  cr_add_test(blink_gc_plugin_test
    python
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test.py
    ${CMAKE_BINARY_DIR}/bin/clang
    )
else()
  add_llvm_loadable_module("lib${LIBRARYNAME}" ${plugin_sources})
  add_dependencies("lib${LIBRARYNAME}" clang)

  cr_install(TARGETS "lib${LIBRARYNAME}" LIBRARY DESTINATION lib)

  cr_add_test(blink_gc_plugin_test
    python
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test.py
    ${CMAKE_BINARY_DIR}/bin/clang
    $<TARGET_FILE:lib${LIBRARYNAME}>
    )
endif()
