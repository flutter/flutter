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

#include "third_party/benchmark/include/benchmark/benchmark_api.h"

#include "flutter/fml/icu_util.h"
#include "lib/fxl/logging.h"
#include "utils.h"

// We will use a custom main to allow custom font directories for consistency.
int main(int argc, char** argv) {
  ::benchmark::Initialize(&argc, argv);
  fxl::CommandLine cmd = fxl::CommandLineFromArgcArgv(argc, argv);
  txt::SetCommandLine(cmd);
  std::string dir = txt::GetCommandLineForProcess().GetOptionValueWithDefault(
      "font-directory", "");
  txt::SetFontDir(dir);
  if (txt::GetFontDir().length() <= 0) {
    FXL_LOG(ERROR) << "Font directory must be specified with "
                      "--font-directoy=\"<directoy>\" to run this test.";
    return EXIT_FAILURE;
  }
  FXL_DCHECK(txt::GetFontDir().length() > 0);

  fml::icu::InitializeICU();

  ::benchmark::RunSpecifiedBenchmarks();
}
