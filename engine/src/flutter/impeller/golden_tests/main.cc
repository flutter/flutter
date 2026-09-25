// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <wordexp.h>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/logging.h"
#include "flutter/impeller/base/validation.h"
#include "flutter/impeller/entity/contents/content_context.h"
#include "flutter/impeller/golden_tests/golden_digest.h"
#include "flutter/impeller/golden_tests/working_directory.h"
#include "flutter/impeller/playground/pipeline_variant_recorder.h"
#include "gtest/gtest.h"

namespace {
/// Prints which pipeline variants were warmed by a `ContentContext` but never
/// drawn with, and how the same pipelines were drawn instead.
constexpr const char* kShaderReportFlag = "shader-report";

/// Fails the run if a `ContentContext` created a pipeline for a shader that no
/// test drew with, with any options, on any backend.
constexpr const char* kFailOnUnusedShadersFlag = "fail-on-unused-shaders";

void print_usage() {
  std::cout << "usage: impeller_golden_tests --working_dir=<working_dir> "
               "[--shader-report] [--fail-on-unused-shaders]"
            << std::endl
            << std::endl;
  std::cout << "flags:" << std::endl;
  std::cout << "  working_dir: Where the golden images will be generated and "
               "uploaded to Skia Gold from."
            << std::endl;
  std::cout << "  shader-report: Print the pipeline variants that were warmed "
               "but never drawn with. Debug builds only."
            << std::endl;
  std::cout << "  fail-on-unused-shaders: Fail if a shader was never drawn "
               "with on any backend. Debug builds only."
            << std::endl;
}
}  // namespace

namespace impeller {
TEST(ValidationTest, IsFatal) {
  EXPECT_TRUE(ImpellerValidationErrorsAreFatal());
}
}  // namespace impeller

int main(int argc, char** argv) {
  impeller::ImpellerValidationErrorsSetFatal(true);
  fml::InstallCrashHandler();
  testing::InitGoogleTest(&argc, argv);
  fml::CommandLine cmd = fml::CommandLineFromPlatformOrArgcArgv(argc, argv);

  std::optional<std::string> working_dir;
  for (const auto& option : cmd.options()) {
    if (option.name == "working_dir") {
      wordexp_t wordexp_result;
      int code = wordexp(option.value.c_str(), &wordexp_result, 0);
      FML_CHECK(code == 0);
      FML_CHECK(wordexp_result.we_wordc != 0);
      working_dir = wordexp_result.we_wordv[0];
      wordfree(&wordexp_result);
    }
  }
  if (!working_dir) {
    std::cout << "required argument \"working_dir\" is missing." << std::endl
              << std::endl;
    print_usage();
    return 1;
  }

  const bool shader_report = cmd.HasOption(kShaderReportFlag);
  const bool fail_on_unused_shaders = cmd.HasOption(kFailOnUnusedShadersFlag);
  if (shader_report || fail_on_unused_shaders) {
    // Failing here, rather than quietly reporting nothing, keeps a check that
    // was asked for from passing without having run.
    if (!impeller::ContentContext::IsPipelineVariantRecordingSupported()) {
      std::cout << "--" << kShaderReportFlag << " and --"
                << kFailOnUnusedShadersFlag
                << " need pipeline variant recording, which is only compiled "
                   "into debug builds."
                << std::endl;
      return 1;
    }
    impeller::PipelineVariantRecorder::InstallForProcess();
  }

  impeller::testing::WorkingDirectory::Instance()->SetPath(working_dir.value());
  std::cout << "working directory: "
            << impeller::testing::WorkingDirectory::Instance()->GetPath()
            << std::endl;

  int return_code = RUN_ALL_TESTS();

  const impeller::PipelineVariantRecorder& recorder =
      impeller::PipelineVariantRecorder::GetInstance();
  if (shader_report) {
    const ::testing::UnitTest& unit_test = *::testing::UnitTest::GetInstance();
    recorder.PrintReport(std::cout,
                         {.gtest_filter = GTEST_FLAG_GET(filter),
                          .tests_run = unit_test.test_to_run_count(),
                          .tests_skipped = unit_test.skipped_test_count(),
                          .tests_failed = unit_test.failed_test_count()});
  }
  // An unused shader fails the run just like a failed test, including not
  // writing the digest, so that nothing is uploaded from the run.
  if (fail_on_unused_shaders && recorder.PrintUnusedShaders(std::cout) > 0u &&
      return_code == 0) {
    return_code = 1;
  }
  std::cout.flush();

  if (0 == return_code) {
    impeller::testing::GoldenDigest::Instance()->Write(
        impeller::testing::WorkingDirectory::Instance());
  }
  return return_code;
}
