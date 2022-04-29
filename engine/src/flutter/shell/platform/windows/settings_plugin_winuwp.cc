// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/settings_plugin_winuwp.h"

#include "flutter/shell/platform/windows/system_utils.h"

#include "third_party/cppwinrt/generated/winrt/base.h"

namespace flutter {

// static
std::unique_ptr<SettingsPlugin> SettingsPlugin::Create(
    BinaryMessenger* messenger,
    TaskRunner* task_runner) {
  return std::make_unique<SettingsPluginWinUwp>(messenger, task_runner);
}

SettingsPluginWinUwp::SettingsPluginWinUwp(BinaryMessenger* messenger,
                                           TaskRunner* task_runner)
    : SettingsPlugin(messenger, task_runner) {}

SettingsPluginWinUwp::~SettingsPluginWinUwp() {
  StopWatching();
}

void SettingsPluginWinUwp::StartWatching() {
  color_values_changed_ = ui_settings_.ColorValuesChanged(
      {this, &SettingsPluginWinUwp::OnColorValuesChanged});
}

void SettingsPluginWinUwp::StopWatching() {
  if (color_values_changed_.has_value()) {
    ui_settings_.ColorValuesChanged(color_values_changed_.value());
    color_values_changed_ = std::nullopt;
  }
}

bool SettingsPluginWinUwp::GetAlwaysUse24HourFormat() {
  return Prefer24HourTime(GetUserTimeFormat());
}

float SettingsPluginWinUwp::GetTextScaleFactor() {
  return 1.0;
}

SettingsPlugin::PlatformBrightness
SettingsPluginWinUwp::GetPreferredBrightness() {
  winrt::Windows::UI::ViewManagement::UISettings ui_settings;
  auto background_color = ui_settings_.GetColorValue(
      winrt::Windows::UI::ViewManagement::UIColorType::Background);
  // Assuming that Windows return `Colors::Black` when being dark theme.
  if (background_color == winrt::Windows::UI::Colors::Black()) {
    return SettingsPlugin::PlatformBrightness::kDark;
  } else {
    return SettingsPlugin::PlatformBrightness::kLight;
  }
}

void SettingsPluginWinUwp::OnColorValuesChanged(
    winrt::Windows::Foundation::IInspectable const&,
    winrt::Windows::Foundation::IInspectable const&) {
  task_runner_->RunNowOrPostTask([this]() { SendSettings(); });
}

}  // namespace flutter
