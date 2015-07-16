// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/khronos_glcts_support/khronos_glcts_test.h"

#include <string>

#include "base/at_exit.h"
#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/process/launch.h"
#include "base/strings/string_util.h"
#include "gpu/config/gpu_test_config.h"
#include "gpu/config/gpu_test_expectations_parser.h"
#include "testing/gtest/include/gtest/gtest.h"

base::FilePath g_deqp_log_dir;

bool RunKhronosGLCTSTest(const char* test_name) {
  // Load test expectations, and return early if a test is marked as FAIL.
  base::FilePath src_path;
  PathService::Get(base::DIR_SOURCE_ROOT, &src_path);
  base::FilePath test_expectations_path =
      src_path.Append(FILE_PATH_LITERAL("gpu")).
      Append(FILE_PATH_LITERAL("khronos_glcts_support")).
      Append(FILE_PATH_LITERAL("khronos_glcts_test_expectations.txt"));
  if (!base::PathExists(test_expectations_path)) {
    LOG(ERROR) << "Fail to locate khronos_glcts_test_expectations.txt";
    return false;
  }
  gpu::GPUTestExpectationsParser test_expectations;
  if (!test_expectations.LoadTestExpectations(test_expectations_path)) {
    LOG(ERROR) << "Fail to load khronos_glcts_test_expectations.txt";
    return false;
  }
  gpu::GPUTestBotConfig bot_config;
  if (!bot_config.LoadCurrentConfig(NULL)) {
    LOG(ERROR) << "Fail to load bot configuration";
    return false;
  }
  if (!bot_config.IsValid()) {
    LOG(ERROR) << "Invalid bot configuration";
    return false;
  }

  const ::testing::TestInfo* const test_info =
      ::testing::UnitTest::GetInstance()->current_test_info();
  int32 expectation =
      test_expectations.GetTestExpectation(test_info->name(), bot_config);
  if (expectation != gpu::GPUTestExpectationsParser::kGpuTestPass) {
    LOG(WARNING) << "Test " << test_info->name() << " is bypassed";
    return true;
  }

  base::FilePath test_path;
  PathService::Get(base::DIR_EXE, &test_path);
  base::FilePath archive(test_path.Append(FILE_PATH_LITERAL(
      "khronos_glcts_data")));
  base::FilePath program(test_path.Append(FILE_PATH_LITERAL(
      "khronos_glcts_test_windowless")));
  base::FilePath log =
      g_deqp_log_dir.AppendASCII(test_info->name()).
      AddExtension(FILE_PATH_LITERAL(".log"));

  base::CommandLine cmdline(program);
  cmdline.AppendSwitchPath("--deqp-log-filename", log);
  cmdline.AppendSwitchPath("--deqp-archive-dir", archive);
  cmdline.AppendArg("--deqp-gl-config-id=-1");
  cmdline.AppendArg(std::string("--deqp-case=") + test_name);

  std::string output;
  bool success = base::GetAppOutput(cmdline, &output);
  if (success) {
    size_t success_index = output.find("Pass (Pass)");
    size_t failed_index = output.find("Fail (Fail)");
    success = (success_index != std::string::npos) &&
              (failed_index == std::string::npos);
  }
  if (!success) {
    LOG(ERROR) << output;
  }
  return success;
}

int main(int argc, char *argv[]) {
  base::AtExitManager at_exit;

  ::testing::InitGoogleTest(&argc, argv);

  if (argc == 2) {
    g_deqp_log_dir = base::FilePath::FromUTF8Unsafe(argv[1]);
  }
  else {
    base::GetTempDir(&g_deqp_log_dir);
  }

  return RUN_ALL_TESTS();
}

