// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fstream>

#include "flutter/third_party/abseil-cpp/absl/flags/flag.h"
#include "flutter/third_party/abseil-cpp/absl/flags/parse.h"
#include "flutter/third_party/abseil-cpp/absl/flags/usage.h"
#include "flutter/third_party/abseil-cpp/absl/log/globals.h"
#include "flutter/third_party/abseil-cpp/absl/log/initialize.h"
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
ABSL_FLAG(std::optional<std::string>,
          licenses_path,
          std::nullopt,
          "[REQUIRED] The path to write the licenses collection to.");
ABSL_FLAG(std::optional<std::string>,
          include_filter,
          std::nullopt,
          "Regex that overrides the include filter.");
ABSL_FLAG(int, v, 0, "Set the verbosity of logs.");

namespace {
int Run(std::string_view working_dir,
        std::ostream& licenses,
        std::string_view data_dir,
        std::string_view include_filter) {
  absl::StatusOr<Data> data = Data::Open(data_dir);
  if (!data.ok()) {
    std::cerr << "Can't load data at " << data_dir << ": " << data.status()
              << std::endl;
    return 1;
  }
  std::stringstream ss;
  ss << include_filter;

  absl::StatusOr<Filter> filter = Filter::Open(ss);
  if (!filter.ok()) {
    std::cerr << "Invalid include_filter parameter." << std::endl;
    return 1;
  }

  data->include_filter = std::move(filter.value());

  std::vector<absl::Status> errors =
      LicenseChecker::Run(working_dir, licenses, data.value());
  for (const absl::Status& status : errors) {
    std::cerr << status << "\n";
  }

  return errors.empty() ? 0 : 1;
}
}  // namespace

int main(int argc, char** argv) {
  absl::SetProgramUsageMessage(
      absl::StrCat("Sample usage:\n", argv[0],
                   " --working_dir=<directory> --data_dir=<directory>"));

  std::vector<char*> args = absl::ParseCommandLine(argc, argv);
  absl::SetGlobalVLogLevel(absl::GetFlag(FLAGS_v));
  absl::InitializeLog();
  absl::SetStderrThreshold(absl::LogSeverity::kInfo);

  std::optional<std::string> working_dir = absl::GetFlag(FLAGS_working_dir);
  std::optional<std::string> data_dir = absl::GetFlag(FLAGS_data_dir);
  std::optional<std::string> licenses_path = absl::GetFlag(FLAGS_licenses_path);
  std::optional<std::string> include_filter =
      absl::GetFlag(FLAGS_include_filter);
  if (working_dir.has_value() && data_dir.has_value() &&
      licenses_path.has_value()) {
    std::ofstream licenses;
    licenses.open(licenses_path.value());
    if (licenses.bad()) {
      std::cerr << "Unable to write to '" << licenses_path.value() << "'.";
      return 1;
    }
    if (include_filter.has_value()) {
      return Run(working_dir.value(), licenses, data_dir.value(),
                 include_filter.value());
    } else {
      return LicenseChecker::Run(working_dir.value(), licenses,
                                 data_dir.value());
    }
  }

  if (!working_dir.has_value()) {
    std::cerr << "Expected --working_dir flag." << std::endl;
  }

  if (!licenses_path.has_value()) {
    std::cerr << "Expected --licenses_path flag." << std::endl;
  }

  if (!data_dir.has_value()) {
    std::cerr << "Expected --data_dir flag." << std::endl;
  }

  return 1;
}
