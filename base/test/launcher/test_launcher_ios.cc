// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/launcher/test_launcher.h"

#include "base/at_exit.h"
#include "base/base_paths.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/files/scoped_temp_dir.h"
#include "base/format_macros.h"
#include "base/message_loop/message_loop.h"
#include "base/path_service.h"
#include "base/process/launch.h"
#include "base/strings/string_util.h"
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_switches.h"
#include "base/test/test_timeouts.h"

namespace {

const char kHelpFlag[] = "help";

void PrintUsage() {
  fprintf(stdout,
          "Runs tests using the gtest framework, each batch of tests being\n"
          "run in their own process. Supported command-line flags:\n"
          "\n"
          " Common flags:\n"
          "  --gtest_filter=...\n"
          "    Runs a subset of tests (see --gtest_help for more info).\n"
          "\n"
          "  --help\n"
          "    Shows this message.\n"
          "\n"
          " Other flags:\n"
          "  --test-launcher-retry-limit=N\n"
          "    Sets the limit of test retries on failures to N.\n"
          "\n"
          "  --test-launcher-summary-output=PATH\n"
          "    Saves a JSON machine-readable summary of the run.\n"
          "\n"
          "  --test-launcher-print-test-stdio=auto|always|never\n"
          "    Controls when full test output is printed.\n"
          "    auto means to print it when the test failed.\n"
          "\n"
          "  --test-launcher-total-shards=N\n"
          "    Sets the total number of shards to N.\n"
          "\n"
          "  --test-launcher-shard-index=N\n"
          "    Sets the shard index to run to N (from 0 to TOTAL - 1).\n");
  fflush(stdout);
}

class IOSUnitTestPlatformDelegate : public base::UnitTestPlatformDelegate {
 public:
  IOSUnitTestPlatformDelegate() {
  }

  bool Init() WARN_UNUSED_RESULT {
    if (!PathService::Get(base::DIR_EXE, &dir_exe_)) {
      LOG(ERROR) << "Failed to get directory of current executable.";
      return false;
    }

    base::CommandLine* command_line = base::CommandLine::ForCurrentProcess();
    std::vector<std::string> args(command_line->GetArgs());
    if (args.size() < 1) {
      LOG(ERROR) << "Arguments expected.";
      return false;
    }
    test_name_ = args[0];

    base::CommandLine cmd_line(dir_exe_.AppendASCII(test_name_ + ".app"));
    cmd_line.AppendSwitch(switches::kTestLauncherPrintWritablePath);
    cmd_line.PrependWrapper(dir_exe_.AppendASCII("iossim").value());

    std::string raw_output;
    if (!base::GetAppOutput(cmd_line, &raw_output)) {
      LOG(ERROR) << "GetAppOutput failed.";
      return false;
    }
    writable_path_ = base::FilePath(raw_output);

    return true;
  }

  bool GetTests(std::vector<base::SplitTestName>* output) override {
    base::ScopedTempDir temp_dir;
    if (!temp_dir.CreateUniqueTempDirUnderPath(writable_path_))
      return false;
    base::FilePath test_list_path(
        temp_dir.path().AppendASCII("test_list.json"));

    base::CommandLine cmd_line(dir_exe_.AppendASCII(test_name_ + ".app"));
    cmd_line.AppendSwitchPath(switches::kTestLauncherListTests, test_list_path);
    cmd_line.PrependWrapper(dir_exe_.AppendASCII("iossim").value());

    base::LaunchOptions launch_options;
    launch_options.wait = true;

    if (!base::LaunchProcess(cmd_line, launch_options).IsValid())
      return false;

    return base::ReadTestNamesFromFile(test_list_path, output);
  }

  bool CreateTemporaryFile(base::FilePath* path) override {
    if (!CreateTemporaryDirInDir(writable_path_, std::string(), path))
      return false;
    *path = path->AppendASCII("test_results.xml");
    return true;
  }

  base::CommandLine GetCommandLineForChildGTestProcess(
      const std::vector<std::string>& test_names,
      const base::FilePath& output_file) override {
    base::CommandLine cmd_line(dir_exe_.AppendASCII(test_name_ + ".app"));
    cmd_line.AppendSwitchPath(switches::kTestLauncherOutput, output_file);
    cmd_line.AppendSwitchASCII(base::kGTestFilterFlag,
                               base::JoinString(test_names, ":"));
    return cmd_line;
  }

  std::string GetWrapperForChildGTestProcess() override {
    return dir_exe_.AppendASCII("iossim").value();
  }

  void RelaunchTests(base::TestLauncher* test_launcher,
                     const std::vector<std::string>& test_names,
                     int launch_flags) override {
    // Relaunch all tests in one big batch, since overhead of smaller batches
    // is too big for serialized runs inside ios simulator.
    RunUnitTestsBatch(test_launcher, this, test_names, launch_flags);
  }

 private:
  // Directory containing test launcher's executable.
  base::FilePath dir_exe_;

  // Name of the test executable to run.
  std::string test_name_;

  // Path that launched test binary can write to.
  base::FilePath writable_path_;

  DISALLOW_COPY_AND_ASSIGN(IOSUnitTestPlatformDelegate);
};

}  // namespace

int main(int argc, char** argv) {
  base::AtExitManager at_exit;

  base::CommandLine::Init(argc, argv);

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(kHelpFlag)) {
    PrintUsage();
    return 0;
  }

  base::TimeTicks start_time(base::TimeTicks::Now());

  TestTimeouts::Initialize();

  base::MessageLoopForIO message_loop;

  IOSUnitTestPlatformDelegate platform_delegate;
  if (!platform_delegate.Init()) {
    fprintf(stderr, "Failed to intialize test launcher platform delegate.\n");
    fflush(stderr);
    return 1;
  }
  base::UnitTestLauncherDelegate delegate(&platform_delegate, 0, false);
  // Force one job since we can't run multiple simulators in parallel.
  base::TestLauncher launcher(&delegate, 1);
  bool success = launcher.Run();

  fprintf(stdout, "Tests took %" PRId64 " seconds.\n",
          (base::TimeTicks::Now() - start_time).InSeconds());
  fflush(stdout);

  return (success ? 0 : 1);
}
