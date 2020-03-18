#include <flutter/flutter_window_controller.h>
#include <linux/limits.h>
#include <unistd.h>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "window_configuration.h"

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  char buffer[PATH_MAX + 1];
  ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer));
  if (length > PATH_MAX) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer, length);
  size_t last_separator_position = executable_path.find_last_of('/');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

int main(int argc, char **argv) {
  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "/data";
  std::string assets_path = data_directory + "/flutter_assets";
  std::string icu_data_path = data_directory + "/icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;

  flutter::FlutterWindowController flutter_controller(icu_data_path);
  flutter::WindowProperties window_properties = {};
  window_properties.title = kFlutterWindowTitle;
  window_properties.width = kFlutterWindowWidth;
  window_properties.height = kFlutterWindowHeight;

  // Start the engine.
  if (!flutter_controller.CreateWindow(window_properties, assets_path,
                                       arguments)) {
    return EXIT_FAILURE;
  }
  RegisterPlugins(&flutter_controller);

  // Run until the window is closed.
  while (flutter_controller.RunEventLoopWithTimeout(
      std::chrono::milliseconds::max())) {
  }
  return EXIT_SUCCESS;
}
