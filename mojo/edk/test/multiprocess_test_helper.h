// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_TEST_MULTIPROCESS_TEST_HELPER_H_
#define MOJO_EDK_TEST_MULTIPROCESS_TEST_HELPER_H_

#include <memory>
#include <string>

#include "base/process/process.h"
#include "base/test/multiprocess_test.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/multiprocess_func_list.h"

namespace mojo {

namespace platform {
class PlatformPipe;
}

namespace test {

class MultiprocessTestHelper final {
 public:
  MultiprocessTestHelper();
  ~MultiprocessTestHelper();

  // Start a child process and run the "main" function "named" |test_child_name|
  // declared using |MOJO_MULTIPROCESS_TEST_CHILD_MAIN()| or
  // |MOJO_MULTIPROCESS_TEST_CHILD_TEST()| (below).
  void StartChild(const std::string& test_child_name);
  // Like |StartChild()|, but appends an extra switch (with ASCII value) to the
  // command line. (The switch must not already be present in the default
  // command line.)
  void StartChildWithExtraSwitch(const std::string& test_child_name,
                                 const std::string& switch_string,
                                 const std::string& switch_value);
  // Wait for the child process to terminate.
  // Returns the exit code of the child process. Note that, though it's declared
  // to be an |int|, the exit code is subject to mangling by the OS. E.g., we
  // usually return -1 on error in the child (e.g., if |test_child_name| was not
  // found), but this is mangled to 255 on Linux. You should only rely on codes
  // 0-127 being preserved, and -1 being outside the range 0-127.
  int WaitForChildShutdown();

  // Like |WaitForChildShutdown()|, but returns true on success (exit code of 0)
  // and false otherwise. You probably want to do something like
  // |EXPECT_TRUE(WaitForChildTestShutdown());|. Mainly for use with
  // |MOJO_MULTIPROCESS_TEST_CHILD_TEST()|.
  bool WaitForChildTestShutdown();

  // For use by |MOJO_MULTIPROCESS_TEST_CHILD_MAIN()| only:
  static void ChildSetup();

  // For use in the main process:
  platform::ScopedPlatformHandle server_platform_handle;

  // For use (and only valid) in the child process:
  static platform::ScopedPlatformHandle client_platform_handle;

 private:
  std::unique_ptr<platform::PlatformPipe> platform_pipe_;

  // Valid after |StartChild()| and before |WaitForChildShutdown()|.
  base::Process test_child_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MultiprocessTestHelper);
};

// Use this to declare the child process's "main()" function for tests using
// |MultiprocessTestHelper|. It returns an |int|, which will be the process's
// exit code (but see the comment about |WaitForChildShutdown()|).
#define MOJO_MULTIPROCESS_TEST_CHILD_MAIN(test_child_name) \
  MULTIPROCESS_TEST_MAIN_WITH_SETUP(                       \
      test_child_name##TestChildMain,                      \
      ::mojo::test::MultiprocessTestHelper::ChildSetup)

// Use this (and |WaitForChildTestShutdown()|) for the child process's "main()",
// if you want to use |EXPECT_...()| or |ASSERT_...()|; it has a |void| return
// type. (Note that while an |ASSERT_...()| failure will abort the test in the
// child, it will not abort the test in the parent.)
#define MOJO_MULTIPROCESS_TEST_CHILD_TEST(test_child_name) \
  void test_child_name##TestChildTest();                   \
  MOJO_MULTIPROCESS_TEST_CHILD_MAIN(test_child_name) {     \
    test_child_name##TestChildTest();                      \
    return (::testing::Test::HasFatalFailure() ||          \
            ::testing::Test::HasNonfatalFailure())         \
               ? 1                                         \
               : 0;                                        \
  }                                                        \
  void test_child_name##TestChildTest()

}  // namespace test
}  // namespace mojo

#endif  // MOJO_EDK_TEST_MULTIPROCESS_TEST_HELPER_H_
