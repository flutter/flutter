// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/settings.h"
#include "flutter/fml/command_line.h"
#include "flutter/shell/common/switches.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(SwitchesTest, SkiaTraceAllowlistFlag) {
  fml::CommandLine command_line =
      fml::CommandLineFromInitializerList({"command"});
  Settings settings = SettingsFromCommandLine(command_line);
#if !FLUTTER_RELEASE
  EXPECT_TRUE(settings.trace_skia);
  EXPECT_TRUE(settings.trace_skia_allowlist.has_value());
  EXPECT_EQ(settings.trace_skia_allowlist->size(), 1ul);
#else
  EXPECT_FALSE(settings.trace_skia);
#endif

  command_line =
      fml::CommandLineFromInitializerList({"command", "--trace-skia"});
  settings = SettingsFromCommandLine(command_line);
#if !FLUTTER_RELEASE
  EXPECT_TRUE(settings.trace_skia);
  EXPECT_FALSE(settings.trace_skia_allowlist.has_value());
#else
  EXPECT_FALSE(settings.trace_skia);
#endif

  command_line = fml::CommandLineFromInitializerList(
      {"command", "--trace-skia-allowlist=aaa,bbb,ccc"});
  settings = SettingsFromCommandLine(command_line);
#if !FLUTTER_RELEASE
  EXPECT_TRUE(settings.trace_skia);
  EXPECT_TRUE(settings.trace_skia_allowlist.has_value());
  EXPECT_EQ(settings.trace_skia_allowlist->size(), 3ul);
  EXPECT_EQ(settings.trace_skia_allowlist->back(), "ccc");
#else
  EXPECT_FALSE(settings.trace_skia);
#endif
}

}  // namespace testing
}  // namespace flutter
