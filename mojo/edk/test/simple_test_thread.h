// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_TEST_SIMPLE_TEST_THREAD_
#define MOJO_EDK_TEST_SIMPLE_TEST_THREAD_

#include "base/threading/simple_thread.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace test {

// Class to help simple threads (with no message loops) in tests.
class SimpleTestThread : public base::DelegateSimpleThread::Delegate {
 public:
  SimpleTestThread();
  ~SimpleTestThread() override;

  // Starts the thread.
  void Start();

  // Joins the thread; this must be called if the thread was started.
  void Join();

  // Note: Subclasses must implement:
  //   virtual void Run() = 0;
  // TODO(vtl): When we stop using |base::DelegateSimpleThread|, this will
  // directly become part of our interface.

 private:
  base::DelegateSimpleThread thread_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SimpleTestThread);
};

}  // namespace test
}  // namespace mojo

#endif  // MOJO_EDK_TEST_SIMPLE_TEST_THREAD_
