#include <flutter/flutter_engine.h>
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

// Runs the application in headless mode, without a window.
void RunHeadless(const std::string& icu_data_path,
                 const std::string& assets_path,
                 const std::vector<std::string>& arguments) {
  flutter::FlutterEngine engine;
  engine.Start(icu_data_path, assets_path, arguments);
  RegisterPlugins(&engine);
  while (true) {
    engine.RunEventLoopWithTimeout();
  }
}

}  // namespace

int main(int argc, char **argv) {
  std::string data_directory = "data";
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
    if (getenv("DISPLAY") == nullptr) {
      std::cout << "No DISPLAY; falling back to headless mode." << std::endl;
      RunHeadless(icu_data_path, assets_path, arguments);
      return EXIT_SUCCESS;
    }
    return EXIT_FAILURE;
  }
  RegisterPlugins(&flutter_controller);

  // Run until the window is closed.
  while (flutter_controller.RunEventLoopWithTimeout()) {
  }
  return EXIT_SUCCESS;
}
