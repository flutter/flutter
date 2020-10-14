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

TEST_F(FlutterRunnerProductConfigurationTest, ValidMaxFramesInFlight) {
  const std::string json_string = "{ \"max_frames_in_flight\" : 5 } ";
  const uint64_t expected_max_frames_in_flight = 5;

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_EQ(product_config.get_max_frames_in_flight(),
            expected_max_frames_in_flight);
}

TEST_F(FlutterRunnerProductConfigurationTest, MissingMaxFramesInFlight) {
  const std::string json_string = "{ \"max_frames_in_flight\" :  } ";
  const uint64_t minimum_reasonable_max_frames_in_flight = 1;

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);
  EXPECT_GE(product_config.get_max_frames_in_flight(),
            minimum_reasonable_max_frames_in_flight);
}

TEST_F(FlutterRunnerProductConfigurationTest, ValidInterceptAllInput) {
  const std::string json_string = "{ \"intercept_all_input\" : true } ";
  const uint64_t expected_intercept_all_input = true;

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);

  EXPECT_EQ(expected_intercept_all_input,
            product_config.get_intercept_all_input());
}

TEST_F(FlutterRunnerProductConfigurationTest, MissingInterceptAllInput) {
  const std::string json_string = "{ \"intercept_all_input\" : } ";
  const uint64_t expected_intercept_all_input = false;

  FlutterRunnerProductConfiguration product_config =
      FlutterRunnerProductConfiguration(json_string);

  EXPECT_EQ(expected_intercept_all_input,
            product_config.get_intercept_all_input());
}

}  // namespace flutter_runner_test
