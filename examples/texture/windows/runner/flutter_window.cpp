// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_window.h"

#include <optional>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

class MyTexture {
 public:
  MyTexture(size_t width, size_t height, uint8_t r, uint8_t g, uint8_t b)
      : width_(width), height_(height) {
    buffer_.resize(width * height * 4);
    pixel_buffer_.buffer = buffer_.data();
    pixel_buffer_.width = width;
    pixel_buffer_.height = height;
    pixel_buffer_.release_callback = nullptr;
    pixel_buffer_.release_context = nullptr;
    SetColor(r, g, b);
  }

  ~MyTexture() = default;

  void SetColor(uint8_t r, uint8_t g, uint8_t b) {
    for (size_t y = 0; y < height_; ++y) {
      for (size_t x = 0; x < width_; ++x) {
        size_t index = (y * width_ + x) * 4;
        buffer_[index] = r;
        buffer_[index + 1] = g;
        buffer_[index + 2] = b;
        buffer_[index + 3] = 255;
      }
    }
  }

  const FlutterDesktopPixelBuffer* CopyPixelBuffer(size_t width, size_t height) {
    return &pixel_buffer_;
  }

 private:
  size_t width_;
  size_t height_;
  std::vector<uint8_t> buffer_;
  FlutterDesktopPixelBuffer pixel_buffer_;
};

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  texture_registrar_ = flutter_controller_->engine()->GetPluginRegistrar("TextureTestPlugin")->texture_registrar();

  // Set up texture registration method channel
  flutter::BinaryMessenger* messenger = flutter_controller_->engine()->messenger();
  texture_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "samples.flutter.io/texture",
      &flutter::StandardMethodCodec::GetInstance());

  texture_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();
        if (method == "create") {
          if (my_texture_) {
            result->Error("Error", "texture already created");
            return;
          }

          const auto* args = std::get_if<flutter::EncodableList>(call.arguments());
          if (!args || args->size() != 2) {
            result->Error("Invalid args", "Invalid create args");
            return;
          }

          int64_t width = 0;
          if (std::holds_alternative<int32_t>(args->at(0))) {
            width = std::get<int32_t>(args->at(0));
          } else if (std::holds_alternative<int64_t>(args->at(0))) {
            width = std::get<int64_t>(args->at(0));
          } else {
            result->Error("Invalid args", "Invalid width type");
            return;
          }

          int64_t height = 0;
          if (std::holds_alternative<int32_t>(args->at(1))) {
            height = std::get<int32_t>(args->at(1));
          } else if (std::holds_alternative<int64_t>(args->at(1))) {
            height = std::get<int64_t>(args->at(1));
          } else {
            result->Error("Invalid args", "Invalid height type");
            return;
          }

          my_texture_ = std::make_unique<MyTexture>(width, height, static_cast<uint8_t>(0x05), static_cast<uint8_t>(0x53), static_cast<uint8_t>(0xb1));

          pixel_buffer_texture_ = std::make_unique<flutter::TextureVariant>(
              flutter::PixelBufferTexture([this](size_t width, size_t height) {
                return my_texture_->CopyPixelBuffer(width, height);
              }));
          texture_id_ = texture_registrar_->RegisterTexture(pixel_buffer_texture_.get());
          result->Success(flutter::EncodableValue(texture_id_));

        } else if (method == "setColor") {
          if (!my_texture_) {
            result->Error("Error", "texture not created");
            return;
          }

          const auto* args = std::get_if<flutter::EncodableList>(call.arguments());
          if (!args || args->size() != 3) {
            result->Error("Invalid args", "Invalid setColor args");
            return;
          }

          int r = 0, g = 0, b = 0;
          if (std::holds_alternative<int32_t>(args->at(0))) {
            r = std::get<int32_t>(args->at(0));
          } else if (std::holds_alternative<int64_t>(args->at(0))) {
            r = static_cast<int>(std::get<int64_t>(args->at(0)));
          }

          if (std::holds_alternative<int32_t>(args->at(1))) {
            g = std::get<int32_t>(args->at(1));
          } else if (std::holds_alternative<int64_t>(args->at(1))) {
            g = static_cast<int>(std::get<int64_t>(args->at(1)));
          }

          if (std::holds_alternative<int32_t>(args->at(2))) {
            b = std::get<int32_t>(args->at(2));
          } else if (std::holds_alternative<int64_t>(args->at(2))) {
            b = static_cast<int>(std::get<int64_t>(args->at(2)));
          }

          my_texture_->SetColor(static_cast<uint8_t>(r), static_cast<uint8_t>(g), static_cast<uint8_t>(b));

          texture_registrar_->MarkTextureFrameAvailable(texture_id_);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (my_texture_) {
    texture_registrar_->UnregisterTexture(texture_id_, nullptr);
    pixel_buffer_texture_ = nullptr;
    my_texture_ = nullptr;
  }

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
