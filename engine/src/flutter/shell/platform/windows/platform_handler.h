// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_

#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_channel.h"
#include "rapidjson/document.h"

namespace flutter {

class FlutterWindowsView;

// Handler for internal system channels.
class PlatformHandler {
 public:
  explicit PlatformHandler(BinaryMessenger* messenger);

  virtual ~PlatformHandler();

  // Creates a new platform handler using the given messenger and view.
  static std::unique_ptr<PlatformHandler> Create(BinaryMessenger* messenger,
                                                 FlutterWindowsView* view);

 protected:
  // Gets plain text from the clipboard and provides it to |result| as the
  // value in a dictionary with the given |key|.
  virtual void GetPlainText(
      std::unique_ptr<MethodResult<rapidjson::Document>> result,
      std::string_view key) = 0;

  // Provides a boolean to |result| as the value in a dictionary at key
  // "value" representing whether or not the clipboard has a non-empty string.
  virtual void GetHasStrings(
      std::unique_ptr<MethodResult<rapidjson::Document>> result) = 0;

  // Sets the clipboard's plain text to |text|, and reports the result (either
  // an error, or null for success) to |result|.
  virtual void SetPlainText(
      const std::string& text,
      std::unique_ptr<MethodResult<rapidjson::Document>> result) = 0;

  virtual void SystemSoundPlay(
      const std::string& sound_type,
      std::unique_ptr<MethodResult<rapidjson::Document>> result) = 0;

  // A error type to use for error responses.
  static constexpr char kClipboardError[] = "Clipboard error";

  static constexpr char kSoundTypeAlert[] = "SystemSoundType.alert";

 private:
  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const MethodCall<rapidjson::Document>& method_call,
      std::unique_ptr<MethodResult<rapidjson::Document>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<MethodChannel<rapidjson::Document>> channel_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_H_
