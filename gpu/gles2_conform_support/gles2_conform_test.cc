// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/gles2_conform_support/gles2_conform_test.h"

#include <string>

#include "base/at_exit.h"
#include "base/base_paths.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#endif
#include "base/path_service.h"
#include "base/process/launch.h"
#include "base/strings/string_util.h"
#include "gpu/config/gpu_test_config.h"
#include "gpu/config/gpu_test_expectations_parser.h"
#include "testing/gtest/include/gtest/gtest.h"

bool RunGLES2ConformTest(const char* path) {
  // Load test expectations, and return early if a test is marked as FAIL.
  base::FilePath src_path;
  PathService::Get(base::DIR_SOURCE_ROOT, &src_path);
  base::FilePath test_expectations_path =
      src_path.Append(FILE_PATH_LITERAL("gpu")).
      Append(FILE_PATH_LITERAL("gles2_conform_support")).
      Append(FILE_PATH_LITERAL("gles2_conform_test_expectations.txt"));
  if (!base::PathExists(test_expectations_path)) {
    LOG(ERROR) << "Fail to locate gles2_conform_test_expectations.txt";
    return false;
  }
  gpu::GPUTestExpectationsParser test_expectations;
  if (!test_expectations.LoadTestExpectations(test_expectations_path)) {
    LOG(ERROR) << "Fail to load gles2_conform_test_expectations.txt";
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
  std::string path_string(path);
  std::string test_name;
  base::ReplaceChars(path_string, "\\/.", "_", &test_name);
  int32 expectation =
    test_expectations.GetTestExpectation(test_name, bot_config);
  if (expectation != gpu::GPUTestExpectationsParser::kGpuTestPass) {
    LOG(WARNING) << "Test " << test_name << " is bypassed";
    return true;
  }

  base::FilePath test_path;
  PathService::Get(base::DIR_EXE, &test_path);
  base::FilePath program(test_path.Append(FILE_PATH_LITERAL(
      "gles2_conform_test_windowless")));

  base::CommandLine* currentCmdLine = base::CommandLine::ForCurrentProcess();
  base::CommandLine cmdline(program);
  cmdline.AppendArguments(*currentCmdLine, false);
  cmdline.AppendSwitch(std::string("--"));
  cmdline.AppendArg(std::string("-run=") + path);

  std::string output;
  bool success = base::GetAppOutput(cmdline, &output);
  if (success) {
    size_t success_index = output.find("Conformance PASSED all");
    size_t failed_index = output.find("FAILED");
    success = (success_index != std::string::npos) &&
              (failed_index == std::string::npos);
  }
  if (!success) {
    LOG(ERROR) << output;
  }
  return success;
}

int main(int argc, char** argv) {
  base::AtExitManager exit_manager;
  base::CommandLine::Init(argc, argv);
#if defined(OS_MACOSX)
  base::mac::ScopedNSAutoreleasePool pool;
#endif
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}



