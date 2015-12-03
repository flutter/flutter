// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/test_io_thread.h"

#include <utility>

#include "mojo/edk/util/waitable_event.h"

using mojo::util::AutoResetWaitableEvent;
using mojo::util::MakeRefCounted;

namespace mojo {
namespace system {
namespace test {

TestIOThread::TestIOThread(StartMode start_mode)
    : io_thread_("test_io_thread"), io_thread_started_(false) {
  switch (start_mode) {
    case StartMode::AUTO:
      Start();
      return;
    case StartMode::MANUAL:
      return;
  }
  CHECK(false) << "Invalid mode";
}

TestIOThread::~TestIOThread() {
  Stop();
}

void TestIOThread::Start() {
  CHECK(!io_thread_started_);
  io_thread_started_ = true;
  CHECK(io_thread_.StartWithOptions(
      base::Thread::Options(base::MessageLoop::TYPE_IO, 0)));
  io_task_runner_ = MakeRefCounted<base_edk::PlatformTaskRunnerImpl>(
      message_loop()->task_runner());
}

void TestIOThread::Stop() {
  // Note: It's okay to call |Stop()| even if the thread isn't running.
  io_thread_.Stop();
  io_thread_started_ = false;
}

bool TestIOThread::IsCurrentAndRunning() const {
  return base::MessageLoop::current() == io_thread_.message_loop() &&
         io_thread_.message_loop()->is_running();
}

void TestIOThread::PostTask(std::function<void()>&& task) {
  io_task_runner_->PostTask(std::move(task));
}

void TestIOThread::PostTask(const base::Closure& task) {
  io_task_runner_->PostTask(task);
}

void TestIOThread::PostTaskAndWait(std::function<void()>&& task) {
  AutoResetWaitableEvent event;
  io_task_runner_->PostTask([&task, &event]() {
    task();
    event.Signal();
  });
  event.Wait();
}

void TestIOThread::PostTaskAndWait(const base::Closure& task) {
  PostTaskAndWait([&task]() { task.Run(); });
}

}  // namespace test
}  // namespace system
}  // namespace mojo
