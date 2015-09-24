// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_TEST_TEST_IO_THREAD_H_
#define MOJO_EDK_TEST_TEST_IO_THREAD_H_

#include "base/callback_forward.h"
#include "base/memory/ref_counted.h"
#include "base/task_runner.h"
#include "base/threading/thread.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace test {

// Class to help create/run threads with I/O |MessageLoop|s in tests.
class TestIOThread {
 public:
  enum Mode { kAutoStart, kManualStart };
  explicit TestIOThread(Mode mode);
  // Stops the I/O thread if necessary.
  ~TestIOThread();

  // |Start()|/|Stop()| should only be called from the main (creation) thread.
  // After |Stop()|, |Start()| may be called again to start a new I/O thread.
  // |Stop()| may be called even when the I/O thread is not started.
  void Start();
  void Stop();

  // Post |task| to the IO thread.
  void PostTask(const tracked_objects::Location& from_here,
                const base::Closure& task);
  // Posts |task| to the IO-thread with an WaitableEvent associated blocks on
  // it until the posted |task| is executed, then returns.
  void PostTaskAndWait(const tracked_objects::Location& from_here,
                       const base::Closure& task);

  base::MessageLoopForIO* message_loop() {
    return static_cast<base::MessageLoopForIO*>(io_thread_.message_loop());
  }

  scoped_refptr<base::SingleThreadTaskRunner> task_runner() {
    return message_loop()->task_runner();
  }

 private:
  base::Thread io_thread_;
  bool io_thread_started_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestIOThread);
};

}  // namespace test
}  // namespace mojo

#endif  // MOJO_EDK_TEST_TEST_IO_THREAD_H_
