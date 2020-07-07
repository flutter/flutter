// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/method_channel.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "rapidjson/document.h"

namespace flutter {

class FlutterWindowsView;

// Handler for internal system channels.
class PlatformHandler {
 public:
  explicit PlatformHandler(flutter::BinaryMessenger* messenger,
                           FlutterWindowsView* view);

 private:
  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<rapidjson::Document>& method_call,
      std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<rapidjson::Document>> channel_;

  // A reference to the win32 window.
  FlutterWindowsView* view_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_
