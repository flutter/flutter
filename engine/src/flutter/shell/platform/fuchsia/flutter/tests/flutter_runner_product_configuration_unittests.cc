// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtest/gtest.h>

#include "flutter/fml/time/time_delta.h"
#include "flutter/shell/platform/fuchsia/flutter/flutter_runner_product_configuration.h"

using namespace flutter_runner;

namespace flutter_runner_test {

class FlutterRunnerProductConfigurationTest : public testing::Test {};

TEST_F(FlutterRunnerProductConfigurationTest, ValidVsyncOffset) {
  const std::string json_string = "{ \"vsync_offset_in_us\" : 9000 } ";
  const fml::TimeDelta expected_offset = fml::TimeDelta::FromMicroseconds(9000);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

TEST_F(FlutterRunnerProductConfigurationTest, InvalidJsonString) {
  const std::string json_string = "{ \"invalid json string\" }}} ";
  const fml::TimeDelta expected_offset = fml::TimeDelta::FromMicroseconds(0);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

TEST_F(FlutterRunnerProductConfigurationTest, EmptyJsonString) {
  const std::string json_string = "";
  const fml::TimeDelta expected_offset = fml::TimeDelta::FromMicroseconds(0);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

TEST_F(FlutterRunnerProductConfigurationTest, EmptyVsyncOffset) {
  const std::string json_string = "{ \"vsync_offset_in_us\" : } ";
  const fml::TimeDelta expected_offset = fml::TimeDelta::FromMicroseconds(0);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

TEST_F(FlutterRunnerProductConfigurationTest, NegativeVsyncOffset) {
  const std::string json_string = "{ \"vsync_offset_in_us\" : -15410 } ";
  const fml::TimeDelta expected_offset =
      fml::TimeDelta::FromMicroseconds(-15410);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

TEST_F(FlutterRunnerProductConfigurationTest, NonIntegerVsyncOffset) {
  const std::string json_string = "{ \"vsync_offset_in_us\" : 3.14159 } ";
  const fml::TimeDelta expected_offset = fml::TimeDelta::FromMicroseconds(0);

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_vsync_offset(), expected_offset);
}

}  // namespace flutter_runner_test
