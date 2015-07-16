// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_LAUNCHER_TEST_LAUNCHER_H_
#define BASE_TEST_LAUNCHER_TEST_LAUNCHER_H_

#include <set>
#include <string>

#include "base/basictypes.h"
#include "base/callback_forward.h"
#include "base/compiler_specific.h"
#include "base/test/gtest_util.h"
#include "base/test/launcher/test_result.h"
#include "base/test/launcher/test_results_tracker.h"
#include "base/time/time.h"
#include "base/timer/timer.h"

namespace testing {
class TestCase;
class TestInfo;
}

namespace base {

class CommandLine;
struct LaunchOptions;
class SequencedWorkerPoolOwner;
class TestLauncher;

// Constants for GTest command-line flags.
extern const char kGTestFilterFlag[];
extern const char kGTestHelpFlag[];
extern const char kGTestListTestsFlag[];
extern const char kGTestRepeatFlag[];
extern const char kGTestRunDisabledTestsFlag[];
extern const char kGTestOutputFlag[];

// Interface for use with LaunchTests that abstracts away exact details
// which tests and how are run.
class TestLauncherDelegate {
 public:
  // Called to get names of tests available for running. The delegate
  // must put the result in |output| and return true on success.
  virtual bool GetTests(std::vector<SplitTestName>* output) = 0;

  // Called before a test is considered for running. If it returns false,
  // the test is not run. If it returns true, the test will be run provided
  // it is part of the current shard.
  virtual bool ShouldRunTest(const std::string& test_case_name,
                             const std::string& test_name) = 0;

  // Called to make the delegate run the specified tests. The delegate must
  // return the number of actual tests it's going to run (can be smaller,
  // equal to, or larger than size of |test_names|). It must also call
  // |test_launcher|'s OnTestFinished method once per every run test,
  // regardless of its success.
  virtual size_t RunTests(TestLauncher* test_launcher,
                          const std::vector<std::string>& test_names) = 0;

  // Called to make the delegate retry the specified tests. The delegate must
  // return the number of actual tests it's going to retry (can be smaller,
  // equal to, or larger than size of |test_names|). It must also call
  // |test_launcher|'s OnTestFinished method once per every retried test,
  // regardless of its success.
  virtual size_t RetryTests(TestLauncher* test_launcher,
                            const std::vector<std::string>& test_names) = 0;

 protected:
  virtual ~TestLauncherDelegate();
};

// Launches tests using a TestLauncherDelegate.
class TestLauncher {
 public:
  // Flags controlling behavior of LaunchChildGTestProcess.
  enum LaunchChildGTestProcessFlags {
    // Allows usage of job objects on Windows. Helps properly clean up child
    // processes.
    USE_JOB_OBJECTS = (1 << 0),

    // Allows breakaway from job on Windows. May result in some child processes
    // not being properly terminated after launcher dies if these processes
    // fail to cooperate.
    ALLOW_BREAKAWAY_FROM_JOB = (1 << 1),
  };

  // Constructor. |parallel_jobs| is the limit of simultaneous parallel test
  // jobs.
  TestLauncher(TestLauncherDelegate* launcher_delegate, size_t parallel_jobs);
  ~TestLauncher();

  // Runs the launcher. Must be called at most once.
  bool Run() WARN_UNUSED_RESULT;

  // Callback called after a child process finishes. First argument is the exit
  // code, second one is child process elapsed time, third one is true if
  // the child process was terminated because of a timeout, and fourth one
  // contains output of the child (stdout and stderr together).
  typedef Callback<void(int, const TimeDelta&, bool, const std::string&)>
      LaunchChildGTestProcessCallback;

  // Launches a child process (assumed to be gtest-based binary) using
  // |command_line|. If |wrapper| is not empty, it is prepended to the final
  // command line. If the child process is still running after |timeout|, it
  // is terminated. After the child process finishes |callback| is called
  // on the same thread this method was called.
  void LaunchChildGTestProcess(const CommandLine& command_line,
                               const std::string& wrapper,
                               base::TimeDelta timeout,
                               int flags,
                               const LaunchChildGTestProcessCallback& callback);

  // Called when a test has finished running.
  void OnTestFinished(const TestResult& result);

 private:
  bool Init() WARN_UNUSED_RESULT;

  // Runs all tests in current iteration. Uses callbacks to communicate success.
  void RunTests();

  void RunTestIteration();

  // Saves test results summary as JSON if requested from command line.
  void MaybeSaveSummaryAsJSON();

  // Called on a worker thread after a child process finishes.
  void OnLaunchTestProcessFinished(
      const LaunchChildGTestProcessCallback& callback,
      int exit_code,
      const TimeDelta& elapsed_time,
      bool was_timeout,
      const std::string& output);

  // Called when a test iteration is finished.
  void OnTestIterationFinished();

  // Called by the delay timer when no output was made for a while.
  void OnOutputTimeout();

  // Make sure we don't accidentally call the wrong methods e.g. on the worker
  // pool thread. With lots of callbacks used this is non-trivial.
  // Should be the first member so that it's destroyed last: when destroying
  // other members, especially the worker pool, we may check the code is running
  // on the correct thread.
  ThreadChecker thread_checker_;

  TestLauncherDelegate* launcher_delegate_;

  // Support for outer sharding, just like gtest does.
  int32 total_shards_;  // Total number of outer shards, at least one.
  int32 shard_index_;   // Index of shard the launcher is to run.

  int cycles_;  // Number of remaining test itreations, or -1 for infinite.

  // Test filters (empty means no filter).
  std::vector<std::string> positive_test_filter_;
  std::vector<std::string> negative_test_filter_;

  // Tests to use (cached result of TestLauncherDelegate::GetTests).
  std::vector<SplitTestName> tests_;

  // Number of tests started in this iteration.
  size_t test_started_count_;

  // Number of tests finished in this iteration.
  size_t test_finished_count_;

  // Number of tests successfully finished in this iteration.
  size_t test_success_count_;

  // Number of tests either timing out or having an unknown result,
  // likely indicating a more systemic problem if widespread.
  size_t test_broken_count_;

  // Number of retries in this iteration.
  size_t retry_count_;

  // Maximum number of retries per iteration.
  size_t retry_limit_;

  // Tests to retry in this iteration.
  std::set<std::string> tests_to_retry_;

  // Result to be returned from Run.
  bool run_result_;

  TestResultsTracker results_tracker_;

  // Watchdog timer to make sure we do not go without output for too long.
  DelayTimer<TestLauncher> watchdog_timer_;

  // Number of jobs to run in parallel.
  size_t parallel_jobs_;

  // Worker pool used to launch processes in parallel.
  scoped_ptr<SequencedWorkerPoolOwner> worker_pool_owner_;

  DISALLOW_COPY_AND_ASSIGN(TestLauncher);
};

// Extract part from |full_output| that applies to |result|.
std::string GetTestOutputSnippet(const TestResult& result,
                                 const std::string& full_output);

}  // namespace base

#endif  // BASE_TEST_LAUNCHER_TEST_LAUNCHER_H_
