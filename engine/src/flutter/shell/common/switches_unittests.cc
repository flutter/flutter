// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <initializer_list>

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

TEST(SwitchesTest, RouteParsedFlag) {
  fml::CommandLine command_line =
      fml::CommandLineFromInitializerList({"command", "--route=/animation"});
  Settings settings = SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.route, "/animation");
  command_line = fml::CommandLineFromInitializerList({"command", "--route"});
  settings = SettingsFromCommandLine(command_line);
  EXPECT_TRUE(settings.route.empty());
}

TEST(SwitchesTest, MsaaSamples) {
  for (int samples : {0, 1, 2, 4, 8, 16}) {
    fml::CommandLine command_line = fml::CommandLineFromInitializerList(
        {"command", ("--msaa-samples=" + std::to_string(samples)).c_str()});
    Settings settings = SettingsFromCommandLine(command_line);
    EXPECT_EQ(settings.msaa_samples, samples);
  }
  fml::CommandLine command_line =
      fml::CommandLineFromInitializerList({"command", "--msaa-samples=3"});
  Settings settings = SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.msaa_samples, 0);

  command_line =
      fml::CommandLineFromInitializerList({"command", "--msaa-samples=foobar"});
  settings = SettingsFromCommandLine(command_line);
  EXPECT_EQ(settings.msaa_samples, 0);
}

TEST(SwitchesTest, EnableEmbedderAPI) {
  {
    // enable
    fml::CommandLine command_line = fml::CommandLineFromInitializerList(
        {"command", "--enable-embedder-api"});
    Settings settings = SettingsFromCommandLine(command_line);
    EXPECT_EQ(settings.enable_embedder_api, true);
  }
  {
    // default
    fml::CommandLine command_line =
        fml::CommandLineFromInitializerList({"command"});
    Settings settings = SettingsFromCommandLine(command_line);
    EXPECT_EQ(settings.enable_embedder_api, false);
  }
}

}  // namespace testing
}  // namespace flutter
