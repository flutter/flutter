// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WIN32_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WIN32_H_

#include "flutter/shell/platform/windows/settings_plugin.h"

#include <Windows.h>

#include "flutter/shell/platform/windows/event_watcher_win32.h"

namespace flutter {

// A settings plugin implementation for win32.
class SettingsPluginWin32 : public SettingsPlugin {
 public:
  explicit SettingsPluginWin32(BinaryMessenger* messenger,
                               TaskRunner* task_runner);

  virtual ~SettingsPluginWin32();

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
  void WatchPreferredBrightnessChanged();
  void WatchTextScaleFactorChanged();

  HKEY preferred_brightness_reg_hkey_ = nullptr;
  HKEY text_scale_factor_reg_hkey_ = nullptr;

  std::unique_ptr<EventWatcherWin32> preferred_brightness_changed_watcher_;
  std::unique_ptr<EventWatcherWin32> text_scale_factor_changed_watcher_;

  SettingsPluginWin32(const SettingsPluginWin32&) = delete;
  SettingsPluginWin32& operator=(const SettingsPluginWin32&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_WIN32_H_
