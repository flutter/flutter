// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WINUWP_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WINUWP_H_

#include "flutter/shell/platform/windows/settings_plugin.h"

#include <memory>
#include <optional>

#include "third_party/cppwinrt/generated/winrt/Windows.Foundation.h"
#include "third_party/cppwinrt/generated/winrt/Windows.UI.ViewManagement.h"

namespace flutter {

// A settings plugin implementation for UWP.
class SettingsPluginWinUwp : public SettingsPlugin {
 public:
  explicit SettingsPluginWinUwp(BinaryMessenger* messenger,
                                TaskRunner* task_runner);

  virtual ~SettingsPluginWinUwp();

  // |SettingsPlugin|
  void StartWatching() override;

  // |SettingsPlugin|
  void StopWatching() override;

 protected:
  // |SettingsPlugin|
  bool GetAlwaysUse24HourFormat() override;

  // |SettingsPlugin|
  float GetTextScaleFactor() override;

  // |SettingsPlugin|
  PlatformBrightness GetPreferredBrightness() override;

 private:
  void OnColorValuesChanged(winrt::Windows::Foundation::IInspectable const&,
                            winrt::Windows::Foundation::IInspectable const&);

  winrt::Windows::UI::ViewManagement::UISettings ui_settings_;

  std::optional<winrt::event_token> color_values_changed_ = std::nullopt;

  SettingsPluginWinUwp(const SettingsPluginWinUwp&) = delete;
  SettingsPluginWinUwp& operator=(const SettingsPluginWinUwp&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WINUWP_H_
