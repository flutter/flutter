// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_WIN32_H_

#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_channel.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/platform_handler.h"
#include "rapidjson/document.h"

namespace flutter {

class FlutterWindowsView;

// Win32 implementation of PlatformHandler.
class PlatformHandlerWin32 : public PlatformHandler {
 public:
  explicit PlatformHandlerWin32(BinaryMessenger* messenger,
                                FlutterWindowsView* view);

  virtual ~PlatformHandlerWin32();

 protected:
  // |PlatformHandler|
  void GetPlainText(std::unique_ptr<MethodResult<rapidjson::Document>> result,
                    std::string_view key) override;

  // |PlatformHandler|
  void SetPlainText(
      const std::string& text,
      std::unique_ptr<MethodResult<rapidjson::Document>> result) override;

 private:
  // A reference to the Flutter view.
  FlutterWindowsView* view_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_WIN32_H_
