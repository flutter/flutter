// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_H_

#include <memory>

#include "flutter/shell/platform/common/client_wrapper/include/flutter/basic_message_channel.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/windows/task_runner.h"
#include "rapidjson/document.h"

namespace flutter {

// Abstract settings plugin.
//
// Used to look up and notify Flutter of user-configured system settings.
// These are typically set in the control panel.
class SettingsPlugin {
 public:
  explicit SettingsPlugin(BinaryMessenger* messenger, TaskRunner* task_runner);

  virtual ~SettingsPlugin();

  static std::unique_ptr<SettingsPlugin> Create(BinaryMessenger* messenger,
                                                TaskRunner* task_runner);

  // Sends settings (e.g., platform brightness) to the engine.
  void SendSettings();

  // Start watching settings changes and notify the engine of the update.
  virtual void StartWatching() = 0;

  // Stop watching settings change. The `SettingsPlugin` destructor will call
  // this automatically.
  virtual void StopWatching() = 0;

 protected:
  enum struct PlatformBrightness { kDark, kLight };

  // Returns `true` if the user uses 24 hour time.
  virtual bool GetAlwaysUse24HourFormat() = 0;

  // Returns the user-preferred text scale factor.
  virtual float GetTextScaleFactor() = 0;

  // Returns the user-preferred brightness.
  virtual PlatformBrightness GetPreferredBrightness() = 0;

  TaskRunner* task_runner_;

 private:
  std::unique_ptr<BasicMessageChannel<rapidjson::Document>> channel_;

  SettingsPlugin(const SettingsPlugin&) = delete;
  SettingsPlugin& operator=(const SettingsPlugin&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_SETTINGS_PLUGIN_H_
