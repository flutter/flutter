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

// A public interface for ScopedClipboard, so that it can be injected into
// PlatformHandlerWin32.
class ScopedClipboardInterface {
 public:
  virtual ~ScopedClipboardInterface(){};

  // Attempts to open the clipboard for the given window, returning the error
  // code in the case of failure and 0 otherwise.
  virtual int Open(HWND window) = 0;

  // Returns true if there is string data available to get.
  virtual bool HasString() = 0;

  // Returns string data from the clipboard.
  //
  // If getting a string fails, returns the error code.
  //
  // Open(...) must have succeeded to call this method.
  virtual std::variant<std::wstring, int> GetString() = 0;

  // Sets the string content of the clipboard, returning the error code on
  // failure and 0 otherwise.
  //
  // Open(...) must have succeeded to call this method.
  virtual int SetString(const std::wstring string) = 0;
};

// Win32 implementation of PlatformHandler.
class PlatformHandlerWin32 : public PlatformHandler {
 public:
  explicit PlatformHandlerWin32(
      BinaryMessenger* messenger,
      FlutterWindowsView* view,
      std::optional<std::function<std::unique_ptr<ScopedClipboardInterface>()>>
          scoped_clipboard_provider = std::nullopt);

  virtual ~PlatformHandlerWin32();

 protected:
  // |PlatformHandler|
  void GetPlainText(std::unique_ptr<MethodResult<rapidjson::Document>> result,
                    std::string_view key) override;

  // |PlatformHandler|
  void GetHasStrings(
      std::unique_ptr<MethodResult<rapidjson::Document>> result) override;

  // |PlatformHandler|
  void SetPlainText(
      const std::string& text,
      std::unique_ptr<MethodResult<rapidjson::Document>> result) override;

  // |PlatformHandler|
  void SystemSoundPlay(
      const std::string& sound_type,
      std::unique_ptr<MethodResult<rapidjson::Document>> result) override;

 private:
  // A reference to the Flutter view.
  FlutterWindowsView* view_;
  // A scoped clipboard provider that can be passed in for mocking in tests.
  // Use this to acquire clipboard in each operation to avoid blocking clipboard
  // unnecessarily. See flutter/flutter#103205.
  std::function<std::unique_ptr<ScopedClipboardInterface>()>
      scoped_clipboard_provider_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PLATFORM_HANDLER_WIN32_H_
