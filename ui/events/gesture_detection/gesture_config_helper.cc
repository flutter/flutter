// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/gesture_detection/gesture_config_helper.h"

#include "ui/gfx/screen.h"

namespace ui {

GestureProvider::Config DefaultGestureProviderConfig() {
  GestureProvider::Config config;
  config.display = gfx::Screen::GetNativeScreen()->GetPrimaryDisplay();
  return config;
}

}  // namespace ui
