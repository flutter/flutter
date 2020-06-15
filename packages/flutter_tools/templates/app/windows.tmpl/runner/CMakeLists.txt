cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME}
  "flutter_window.cpp"
  "main.cpp"
  "run_loop.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "window_configuration.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)
apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
add_dependencies(${BINARY_NAME} flutter_assemble)
