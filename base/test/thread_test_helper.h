// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_THREAD_TEST_HELPER_H_
#define BASE_TEST_THREAD_TEST_HELPER_H_

#include "base/compiler_specific.h"
#include "base/memory/ref_counted.h"
#include "base/single_thread_task_runner.h"
#include "base/synchronization/waitable_event.h"

namespace base {

// Helper class that executes code on a given thread while blocking on the
// invoking thread. To use, derive from this class and overwrite RunTest. An
// alternative use of this class is to use it directly.  It will then block
// until all pending tasks on a given thread have been executed.
class ThreadTestHelper : public RefCountedThreadSafe<ThreadTestHelper> {
 public:
  explicit ThreadTestHelper(
      scoped_refptr<SingleThreadTaskRunner> target_thread);

  // True if RunTest() was successfully executed on the target thread.
  bool Run() WARN_UNUSED_RESULT;

  virtual void RunTest();

 protected:
  friend class RefCountedThreadSafe<ThreadTestHelper>;

  virtual ~ThreadTestHelper();

  // Use this method to store the result of RunTest().
  void set_test_result(bool test_result) { test_result_ = test_result; }

 private:
  void RunInThread();

  bool test_result_;
  scoped_refptr<SingleThreadTaskRunner> target_thread_;
  WaitableEvent done_event_;

  DISALLOW_COPY_AND_ASSIGN(ThreadTestHelper);
};

}  // namespace base

#endif  // BASE_TEST_THREAD_TEST_HELPER_H_
