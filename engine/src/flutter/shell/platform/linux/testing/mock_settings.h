// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_SETTINGS_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_SETTINGS_H_

#include "flutter/shell/platform/linux/fl_settings.h"

#include "gmock/gmock.h"

namespace flutter {
namespace testing {

// Mock for FlSettings.
class MockSettings {
 public:
  MockSettings();
  ~MockSettings();

  operator FlSettings*();

  MOCK_METHOD1(fl_settings_get_clock_format,
               FlClockFormat(FlSettings* settings));

  MOCK_METHOD1(fl_settings_get_color_scheme,
               FlColorScheme(FlSettings* settings));

  MOCK_METHOD1(fl_settings_get_enable_animations, bool(FlSettings* settings));

  MOCK_METHOD1(fl_settings_get_high_contrast, bool(FlSettings* settings));

  MOCK_METHOD1(fl_settings_get_text_scaling_factor,
               gdouble(FlSettings* settings));

 private:
  FlSettings* instance_ = nullptr;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_SETTINGS_H_
