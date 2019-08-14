// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_CONTROLLER_H_

#include <flutter_windows.h>

#include <string>
#include <vector>

#include "flutter_window.h"
#include "plugin_registrar.h"

namespace flutter {

// A controller for a window displaying Flutter content.
//
// This is the primary wrapper class for the desktop C API.
// If you use this class, you should not call any of the setup or teardown
// methods in the C API directly, as this class will do that internally.
//
// Note: This is an early implementation which
// requires control of the application's event loop, and is thus useful
// primarily for building a simple one-window shell hosting a Flutter
// application. The final implementation and API will be very different.
class FlutterWindowController {
 public:
  // There must be only one instance of this class in an application at any
  // given time, as Flutter does not support multiple engines in one process,
  // or multiple views in one engine.
  explicit FlutterWindowController(const std::string& icu_data_path);

  ~FlutterWindowController();

  // Prevent copying.
  FlutterWindowController(FlutterWindowController const&) = delete;
  FlutterWindowController& operator=(FlutterWindowController const&) = delete;

  // Creates and displays a window for displaying Flutter content.
  //
  // The |assets_path| is the path to the flutter_assets folder for the Flutter
  // application to be run. |icu_data_path| is the path to the icudtl.dat file
  // for the version of Flutter you are using.
  //
  // The |arguments| are passed to the Flutter engine. See:
  // https://github.com/flutter/engine/blob/master/shell/common/switches.h for
  // for details. Not all arguments will apply to desktop.
  //
  // Only one Flutter window can exist at a time; see constructor comment.
  bool CreateWindow(int width,
                    int height,
                    const std::string& title,
                    const std::string& assets_path,
                    const std::vector<std::string>& arguments);

  // Returns the FlutterDesktopPluginRegistrarRef to register a plugin with the
  // given name.
  //
  // The name must be unique across the application.
  FlutterDesktopPluginRegistrarRef GetRegistrarForPlugin(
      const std::string& plugin_name);

  // The FlutterWindow managed by this controller, if any. Returns nullptr
  // before CreateWindow is called, and after RunEventLoop returns;
  FlutterWindow* window() { return window_.get(); }

  // Loops on Flutter window events until the window closes.
  void RunEventLoop();

 private:
  // The path to the ICU data file. Set at creation time since it is the same
  // for any window created.
  std::string icu_data_path_;

  // Whether or not FlutterDesktopInit succeeded at creation time.
  bool init_succeeded_ = false;

  // The owned FlutterWindow, if any.
  std::unique_ptr<FlutterWindow> window_;

  // Handle for interacting with the C API's window controller, if any.
  FlutterDesktopWindowControllerRef controller_ = nullptr;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_WINDOW_CONTROLLER_H_
