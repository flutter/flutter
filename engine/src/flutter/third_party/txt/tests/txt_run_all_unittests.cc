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

#include "flutter/fml/command_line.h"
#include "flutter/fml/icu_util.h"
#include "flutter/fml/logging.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/core/SkGraphics.h"
#include "txt_test_utils.h"

#include <cassert>

int main(int argc, char** argv) {
  fml::CommandLine cmd = fml::CommandLineFromArgcArgv(argc, argv);
  txt::SetCommandLine(cmd);
  txt::SetFontDir(flutter::testing::GetFixturesPath());
  if (txt::GetFontDir().length() <= 0) {
    FML_LOG(ERROR) << "Font directory not set via txt::SetFontDir.";
    return EXIT_FAILURE;
  }
  FML_DCHECK(txt::GetFontDir().length() > 0);
#if defined(OS_FUCHSIA)
  fml::icu::InitializeICU("/pkg/data/icudtl.dat");
#else
  fml::icu::InitializeICU("icudtl.dat");
#endif
  SkGraphics::Init();
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
