/*
 * Copyright 2017 Google, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "flutter/fml/build_config.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

#include "flow_test_utils.h"

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  fml::CommandLine cmd = fml::CommandLineFromArgcArgv(argc, argv);

#if defined(OS_FUCHSIA)
  flutter::SetGoldenDir(cmd.GetOptionValueWithDefault(
      "golden-dir", "/pkg/data/flutter/testing/resources"));
#else
  flutter::SetGoldenDir(
      cmd.GetOptionValueWithDefault("golden-dir", "flutter/testing/resources"));
#endif
  flutter::SetFontFile(cmd.GetOptionValueWithDefault(
      "font-file",
      "flutter/third_party/txt/third_party/fonts/Roboto-Regular.ttf"));
  return RUN_ALL_TESTS();
}
