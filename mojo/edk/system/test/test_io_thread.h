// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_TEST_IO_THREAD_H_
#define MOJO_EDK_SYSTEM_TEST_TEST_IO_THREAD_H_

#include <functional>

#include "base/callback_forward.h"
#include "base/threading/thread.h"
#include "mojo/edk/base_edk/platform_task_runner_impl.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

// Class to help create/run threads with I/O |MessageLoop|s in tests.
class TestIOThread final {
 public:
  enum class StartMode { AUTO, MANUAL };
  explicit TestIOThread(StartMode start_mode);
  // Stops the I/O thread if necessary.
  ~TestIOThread();

  // |Start()|/|Stop()| should only be called from the main (creation) thread.
  // After |Stop()|, |Start()| may be called again to start a new I/O thread.
  // |Stop()| may be called even when the I/O thread is not started.
  void Start();
  void Stop();

  // Returns true if called on the I/O thread with the message loop running.
  // (This may be called on any thread.)
  bool IsCurrentAndRunning() const;

  // Posts |task| to the I/O thread.
  // TODO(vtl): Remove the |base::Closure| version.
  void PostTask(std::function<void()>&& task);
  void PostTask(const base::Closure& task);
  // Posts |task| to the I/O thread, blocking the calling thread until the
  // posted task is executed (note the deadlock risk!).
  // TODO(vtl): Remove the |base::Closure| version.
  void PostTaskAndWait(std::function<void()>&& task);
  void PostTaskAndWait(const base::Closure& task);

  base::MessageLoopForIO* message_loop() {
    return static_cast<base::MessageLoopForIO*>(io_thread_.message_loop());
  }

  const util::RefPtr<platform::TaskRunner>& task_runner() const {
    return io_task_runner_;
  }

 private:
  base::Thread io_thread_;
  bool io_thread_started_;
  util::RefPtr<platform::TaskRunner> io_task_runner_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestIOThread);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_TEST_IO_THREAD_H_
