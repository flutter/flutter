// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter_window.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

static constexpr int kBatteryError = -1;
static constexpr int kNoBattery = -2;

static int GetBatteryLevel() {
  SYSTEM_POWER_STATUS status;
  if (GetSystemPowerStatus(&status) == 0) {
    return kBatteryError;
  } else if (status.BatteryFlag == 128) {
    return kNoBattery;
  } else if (status.BatteryLifePercent == 255) {
    return kBatteryError;
  }
  return status.BatteryLifePercent;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {
  if (power_notification_handle_) {
    UnregisterPowerSettingNotification(power_notification_handle_);
  }
}

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

  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "samples.flutter.io/battery",
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<>& call,
         std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "getBatteryLevel") {
          int battery_level = GetBatteryLevel();

          if (battery_level == kBatteryError) {
            result->Error("UNAVAILABLE", "Battery level not available.");
          } else if (battery_level == kNoBattery) {
            result->Error("NO_BATTERY", "Device does not have a battery.");
          } else {
            result->Success(battery_level);
          }
        } else {
          result->NotImplemented();
        }
      });

  flutter::EventChannel<> charging_channel(
      flutter_controller_->engine()->messenger(), "samples.flutter.io/charging",
      &flutter::StandardMethodCodec::GetInstance());
  charging_channel.SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<>>(
          [this](auto arguments, auto events) {
            this->OnStreamListen(std::move(events));
            return nullptr;
          },
          [this](auto arguments) {
            this->OnStreamCancel();
            return nullptr;
          }));

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

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
    case WM_POWERBROADCAST:
      SendBatteryStateEvent();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::OnStreamListen(
    std::unique_ptr<flutter::EventSink<>>&& events) {
  event_sink_ = std::move(events);
  SendBatteryStateEvent();
  power_notification_handle_ =
      RegisterPowerSettingNotification(GetHandle(), &GUID_ACDC_POWER_SOURCE, 0);
}

void FlutterWindow::OnStreamCancel() { event_sink_ = nullptr; }

void FlutterWindow::SendBatteryStateEvent() {
  SYSTEM_POWER_STATUS status;
  if (GetSystemPowerStatus(&status) == 0 || status.ACLineStatus == 255) {
    event_sink_->Error("UNAVAILABLE", "Charging status unavailable");
  } else {
    event_sink_->Success(flutter::EncodableValue(
        status.ACLineStatus == 1 ? "charging" : "discharging"));
  }
}
