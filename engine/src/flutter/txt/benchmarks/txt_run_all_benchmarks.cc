// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/command_line.h"
#include "flutter/fml/icu_util.h"
#include "flutter/fml/logging.h"
#include "flutter/testing/testing.h"
#include "flutter/txt/tests/txt_test_utils.h"
#include "third_party/benchmark/include/benchmark/benchmark.h"

// We will use a custom main to allow custom font directories for consistency.
int main(int argc, char** argv) {
  ::benchmark::Initialize(&argc, argv);
  fml::CommandLine cmd = fml::CommandLineFromPlatformOrArgcArgv(argc, argv);
  txt::SetFontDir(flutter::testing::GetFixturesPath());
  if (txt::GetFontDir().length() <= 0) {
    FML_LOG(ERROR) << "Font directory not set via txt::SetFontDir.";
    return EXIT_FAILURE;
  }
  FML_DCHECK(txt::GetFontDir().length() > 0);

  std::string icudtl_path =
      cmd.GetOptionValueWithDefault("icu-data-file-path", "icudtl.dat");
  fml::icu::InitializeICU(icudtl_path);

  ::benchmark::RunSpecifiedBenchmarks();
}
