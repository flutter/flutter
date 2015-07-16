// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_MULTIPROCESS_TEST_H_
#define BASE_TEST_MULTIPROCESS_TEST_H_

#include <string>

#include "base/basictypes.h"
#include "base/process/launch.h"
#include "base/process/process.h"
#include "build/build_config.h"
#include "testing/platform_test.h"

namespace base {

class CommandLine;

// Helpers to spawn a child for a multiprocess test and execute a designated
// function. Use these when you already have another base class for your test
// fixture, but you want (some) of your tests to be multiprocess (otherwise you
// may just want to derive your fixture from |MultiProcessTest|, below).
//
// Use these helpers as follows:
//
//   TEST_F(MyTest, ATest) {
//     CommandLine command_line(
//         base::GetMultiProcessTestChildBaseCommandLine());
//     // Maybe add our own switches to |command_line|....
//
//     LaunchOptions options;
//     // Maybe set some options (e.g., |start_hidden| on Windows)....
//
//     // Start a child process and run |a_test_func|.
//     base::Process test_child_process =
//         base::SpawnMultiProcessTestChild("a_test_func", command_line,
//                                          options);
//
//     // Do stuff involving |test_child_process| and the child process....
//
//     int rv = -1;
//     ASSERT_TRUE(test_child_process.WaitForExitWithTimeout(
//         TestTimeouts::action_timeout(), &rv));
//     EXPECT_EQ(0, rv);
//   }
//
//   // Note: |MULTIPROCESS_TEST_MAIN()| is defined in
//   // testing/multi_process_function_list.h.
//   MULTIPROCESS_TEST_MAIN(a_test_func) {
//     // Code here runs in a child process....
//     return 0;
//   }

// Spawns a child process and executes the function |procname| declared using
// |MULTIPROCESS_TEST_MAIN()| or |MULTIPROCESS_TEST_MAIN_WITH_SETUP()|.
// |command_line| should be as provided by
// |GetMultiProcessTestChildBaseCommandLine()| (below), possibly with arguments
// added. Note: On Windows, you probably want to set |options.start_hidden|.
Process SpawnMultiProcessTestChild(
    const std::string& procname,
    const CommandLine& command_line,
    const LaunchOptions& options);

// Gets the base command line for |SpawnMultiProcessTestChild()|. To this, you
// may add any flags needed for your child process.
CommandLine GetMultiProcessTestChildBaseCommandLine();

// MultiProcessTest ------------------------------------------------------------

// A MultiProcessTest is a test class which makes it easier to
// write a test which requires code running out of process.
//
// To create a multiprocess test simply follow these steps:
//
// 1) Derive your test from MultiProcessTest. Example:
//
//    class MyTest : public MultiProcessTest {
//    };
//
//    TEST_F(MyTest, TestCaseName) {
//      ...
//    }
//
// 2) Create a mainline function for the child processes and include
//    testing/multiprocess_func_list.h.
//    See the declaration of the MULTIPROCESS_TEST_MAIN macro
//    in that file for an example.
// 3) Call SpawnChild("foo"), where "foo" is the name of
//    the function you wish to run in the child processes.
// That's it!
class MultiProcessTest : public PlatformTest {
 public:
  MultiProcessTest();

 protected:
  // Run a child process.
  // 'procname' is the name of a function which the child will
  // execute.  It must be exported from this library in order to
  // run.
  //
  // Example signature:
  //    extern "C" int __declspec(dllexport) FooBar() {
  //         // do client work here
  //    }
  //
  // Returns the child process.
  Process SpawnChild(const std::string& procname);

  // Run a child process using the given launch options.
  //
  // Note: On Windows, you probably want to set |options.start_hidden|.
  Process SpawnChildWithOptions(const std::string& procname,
                                const LaunchOptions& options);

  // Set up the command line used to spawn the child process.
  // Override this to add things to the command line (calling this first in the
  // override).
  // Note that currently some tests rely on this providing a full command line,
  // which they then use directly with |LaunchProcess()|.
  // TODO(viettrungluu): Remove this and add a virtual
  // |ModifyChildCommandLine()|; make the two divergent uses more sane.
  virtual CommandLine MakeCmdLine(const std::string& procname);

 private:
  DISALLOW_COPY_AND_ASSIGN(MultiProcessTest);
};

}  // namespace base

#endif  // BASE_TEST_MULTIPROCESS_TEST_H_
