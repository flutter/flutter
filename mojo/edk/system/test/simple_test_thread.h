// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_SIMPLE_TEST_THREAD_
#define MOJO_EDK_SYSTEM_TEST_SIMPLE_TEST_THREAD_

#include <thread>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

// Class to help simple threads (with no message loops) in tests.
class SimpleTestThread {
 public:
  virtual ~SimpleTestThread();

  // Starts the thread.
  void Start();

  // Joins the thread; this must be called if the thread was started.
  void Join();

 protected:
  SimpleTestThread();

  // Code to run in the thread.
  virtual void Run() = 0;

 private:
  std::thread thread_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SimpleTestThread);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_TEST_SYSTEM_SIMPLE_TEST_THREAD_
