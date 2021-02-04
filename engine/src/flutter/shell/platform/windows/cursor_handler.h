// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CURSOR_HANDLER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CURSOR_HANDLER_H_

#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/encodable_value.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_channel.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/window_binding_handler.h"

namespace flutter {

// Handler for the cursor system channel.
class CursorHandler {
 public:
  explicit CursorHandler(flutter::BinaryMessenger* messenger,
                         WindowBindingHandler* delegate);

 private:
  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;

  // The delegate for cursor updates.
  WindowBindingHandler* delegate_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CURSOR_HANDLER_H_
