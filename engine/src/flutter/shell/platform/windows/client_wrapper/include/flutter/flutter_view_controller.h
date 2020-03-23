// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_VIEW_CONTROLLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_VIEW_CONTROLLER_H_

#include <flutter_windows.h>

#include <chrono>
#include <string>
#include <vector>

#include "dart_project.h"
#include "flutter_view.h"
#include "plugin_registrar.h"
#include "plugin_registry.h"

namespace flutter {

// A controller for a view displaying Flutter content.
//
// This is the primary wrapper class for the desktop C API.
// If you use this class, you should not call any of the setup or teardown
// methods in the C API directly, as this class will do that internally.
class FlutterViewController : public PluginRegistry {
 public:
  // Creates a FlutterView that can be parented into a Windows View hierarchy
  // either using HWNDs or in the future into a CoreWindow, or using compositor.
  //
  // |dart_project| will be used to configure the engine backing this view.
  explicit FlutterViewController(int width,
                                 int height,
                                 const DartProject& project);

  // DEPRECATED. Will be removed soon; use the version above.
  explicit FlutterViewController(const std::string& icu_data_path,
                                 int width,
                                 int height,
                                 const std::string& assets_path,
                                 const std::vector<std::string>& arguments);

  virtual ~FlutterViewController();

  // Prevent copying.
  FlutterViewController(FlutterViewController const&) = delete;
  FlutterViewController& operator=(FlutterViewController const&) = delete;

  FlutterView* view() { return view_.get(); }

  // Processes any pending events in the Flutter engine, and returns the
  // nanosecond delay until the next scheduled event (or  max, if none).
  //
  // This should be called on every run of the application-level runloop, and
  // a wait for native events in the runloop should never be longer than the
  // last return value from this function.
  std::chrono::nanoseconds ProcessMessages();

  // flutter::PluginRegistry:
  FlutterDesktopPluginRegistrarRef GetRegistrarForPlugin(
      const std::string& plugin_name) override;

 private:
  // Handle for interacting with the C API's view controller, if any.
  FlutterDesktopViewControllerRef controller_ = nullptr;

  // The owned FlutterView.
  std::unique_ptr<FlutterView> view_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_FLUTTER_VIEW_CONTROLLER_H_
