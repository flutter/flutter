// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/testing/impeller_unittest_suite.h"

#include <iostream>

#include "flutter/fml/logging.h"
#include "flutter/impeller/playground/pipeline_variant_recorder.h"
#include "flutter/impeller/playground/playground_test.h"
#include "flutter/testing/test_args.h"
#include "gtest/gtest.h"

namespace impeller {
namespace testing {

namespace {

/// Reports pipeline variants that were warmed by a `ContentContext` but never
/// drawn with over the test run, and how the same pipelines were drawn instead.
constexpr const char* kShaderReportFlag = "shader-report";

bool IsShaderReportEnabled() {
  return flutter::testing::GetArgsForProcess().HasOption(kShaderReportFlag);
}

}  // namespace

void ImpellerUnittestSetup() {
  ::impeller::PlaygroundTest::SetupTestEnvironment();
  if (IsShaderReportEnabled()) {
    PipelineVariantRecorder::InstallForProcess();
  }
}

void ImpellerUnittestTeardown() {
  if (!IsShaderReportEnabled()) {
    return;
  }
  const ::testing::UnitTest* unit_test = ::testing::UnitTest::GetInstance();
  PipelineVariantRecorder::GetInstance().PrintReport(
      std::cout, {
                     .gtest_filter = GTEST_FLAG_GET(filter),
                     .tests_run = unit_test->test_to_run_count(),
                     .tests_skipped = unit_test->skipped_test_count(),
                     .tests_failed = unit_test->failed_test_count(),
                 });
  std::cout << std::flush;
}

}  // namespace testing
}  // namespace impeller
