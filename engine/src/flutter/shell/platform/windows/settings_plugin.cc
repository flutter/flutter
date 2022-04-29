// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/settings_plugin.h"

#include "flutter/shell/platform/common/json_message_codec.h"

namespace flutter {

namespace {
constexpr char kChannelName[] = "flutter/settings";

constexpr char kAlwaysUse24HourFormat[] = "alwaysUse24HourFormat";
constexpr char kTextScaleFactor[] = "textScaleFactor";
constexpr char kPlatformBrightness[] = "platformBrightness";

constexpr char kPlatformBrightnessDark[] = "dark";
constexpr char kPlatformBrightnessLight[] = "light";
}  // namespace

SettingsPlugin::SettingsPlugin(BinaryMessenger* messenger,
                               TaskRunner* task_runner)
    : channel_(std::make_unique<BasicMessageChannel<rapidjson::Document>>(
          messenger,
          kChannelName,
          &JsonMessageCodec::GetInstance())),
      task_runner_(task_runner) {}

SettingsPlugin::~SettingsPlugin() = default;

void SettingsPlugin::SendSettings() {
  rapidjson::Document settings(rapidjson::kObjectType);
  auto& allocator = settings.GetAllocator();
  settings.AddMember(kAlwaysUse24HourFormat, GetAlwaysUse24HourFormat(),
                     allocator);
  settings.AddMember(kTextScaleFactor, GetTextScaleFactor(), allocator);

  if (GetPreferredBrightness() == PlatformBrightness::kDark) {
    settings.AddMember(kPlatformBrightness, kPlatformBrightnessDark, allocator);
  } else {
    settings.AddMember(kPlatformBrightness, kPlatformBrightnessLight,
                       allocator);
  }
  channel_->Send(settings);
}

}  // namespace flutter
