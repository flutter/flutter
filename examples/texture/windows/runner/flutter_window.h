// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>
#include <flutter/encodable_value.h>

#include <memory>

#include "win32_window.h"

class MyTexture;

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Channel to receive texture requests from Flutter.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> texture_channel_;

  // The texture registrar used to register textures with the Flutter engine.
  flutter::TextureRegistrar* texture_registrar_ = nullptr;

  // Texture we've created.
  std::unique_ptr<flutter::TextureVariant> pixel_buffer_texture_;
  std::unique_ptr<MyTexture> my_texture_;
  int64_t texture_id_ = -1;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
