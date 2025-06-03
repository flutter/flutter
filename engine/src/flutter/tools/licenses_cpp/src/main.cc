// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/third_party/abseil-cpp/absl/flags/flag.h"
#include "flutter/third_party/abseil-cpp/absl/flags/parse.h"
#include "flutter/third_party/abseil-cpp/absl/flags/usage.h"
#include "flutter/third_party/abseil-cpp/absl/log/globals.h"
#include "flutter/third_party/abseil-cpp/absl/strings/str_cat.h"
#include "flutter/tools/licenses_cpp/src/license_checker.h"

ABSL_FLAG(std::optional<std::string>,
          working_dir,
          std::nullopt,
          "[REQUIRED] The directory to scan.");
ABSL_FLAG(std::optional<std::string>,
          data_dir,
          std::nullopt,
          "[REQUIRED] The directory with the licenses.");
ABSL_FLAG(int, v, 0, "Set the verbosity of logs.");

int main(int argc, char** argv) {
  absl::SetProgramUsageMessage(
      absl::StrCat("Sample usage:\n", argv[0],
                   " --working_dir=<directory> --data_dir=<directory>"));

  std::vector<char*> args = absl::ParseCommandLine(argc, argv);
  absl::SetGlobalVLogLevel(absl::GetFlag(FLAGS_v));

  std::optional<std::string> working_dir = absl::GetFlag(FLAGS_working_dir);
  std::optional<std::string> data_dir = absl::GetFlag(FLAGS_working_dir);
  if (working_dir.has_value() && data_dir.has_value()) {
    return LicenseChecker::Run(working_dir.value(), data_dir.value());
  }

  if (!working_dir.has_value()) {
    std::cerr << "Expected --working_dir flag." << std::endl;
  }

  if (!data_dir.has_value()) {
    std::cerr << "Expected --data_dir flag." << std::endl;
  }

  return 1;
}
