// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/launcher/unit_test_launcher.h"

#include "base/command_line.h"
#include "base/files/file_util.h"
#include "base/test/gtest_util.h"
#include "base/test/gtest_xml_unittest_result_printer.h"
#include "base/test/test_switches.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

int LaunchUnitTests(int argc,
                    char** argv,
                    const RunTestSuiteCallback& run_test_suite) {
  CHECK(CommandLine::InitializedForCurrentProcess() ||
        CommandLine::Init(argc, argv));
  const CommandLine* command_line = CommandLine::ForCurrentProcess();
  if (command_line->HasSwitch(switches::kTestLauncherListTests)) {
    // Dump all test list into a file.
    FilePath list_path(
        command_line->GetSwitchValuePath(switches::kTestLauncherListTests));
    if (!WriteCompiledInTestsToFile(list_path)) {
      LOG(ERROR) << "Failed to write list of tests.";
      return 1;
    }

    // Successfully done.
    return 0;
  }

  // Register XML output printer, if --test-launcher-output flag is set.
  if (command_line->HasSwitch(switches::kTestLauncherOutput)) {
    FilePath output_path = command_line->GetSwitchValuePath(
        switches::kTestLauncherOutput);
    if (PathExists(output_path)) {
      LOG(WARNING) << "Test launcher output path exists. Do not override";
    } else {
      XmlUnitTestResultPrinter* printer = new XmlUnitTestResultPrinter;
      CHECK(printer->Initialize(output_path));
      testing::UnitTest::GetInstance()->listeners().Append(printer);
    }
  }

  return run_test_suite.Run();
}

}  // namespace base
