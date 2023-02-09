// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_FLUTTER_WINDOWS_ENGINE_BUILDER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_FLUTTER_WINDOWS_ENGINE_BUILDER_H_

#include <memory>

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/keyboard_key_embedder_handler.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/testing/windows_test_context.h"

namespace flutter {
namespace testing {

class FlutterWindowsEngineBuilder {
 public:
  explicit FlutterWindowsEngineBuilder(WindowsTestContext& context);
  ~FlutterWindowsEngineBuilder();

  void SetDartEntrypoint(std::string entrypoint);

  void AddDartEntrypointArgument(std::string arg);

  void SetCreateKeyboardHandlerCallbacks(
      KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state,
      KeyboardKeyEmbedderHandler::MapVirtualKeyToScanCode map_vk_to_scan);

  std::unique_ptr<FlutterWindowsEngine> Build();

  // Prevent copying.
  FlutterWindowsEngineBuilder(FlutterWindowsEngineBuilder const&) = delete;
  FlutterWindowsEngineBuilder& operator=(FlutterWindowsEngineBuilder const&) =
      delete;

 private:
  WindowsTestContext& context_;
  FlutterDesktopEngineProperties properties_ = {};
  std::string dart_entrypoint_;
  std::vector<std::string> dart_entrypoint_arguments_;
  KeyboardKeyEmbedderHandler::GetKeyStateHandler get_key_state_;
  KeyboardKeyEmbedderHandler::MapVirtualKeyToScanCode map_vk_to_scan_;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_FLUTTER_WINDOWS_ENGINE_BUILDER_H_
