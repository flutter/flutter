// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/test_io_thread.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/platform/io_thread.h"
#include "mojo/edk/platform/thread.h"
#include "mojo/edk/util/waitable_event.h"

using mojo::platform::CreateAndStartIOThread;
using mojo::util::AutoResetWaitableEvent;
using mojo::util::MakeRefCounted;

namespace mojo {
namespace system {
namespace test {

TestIOThread::TestIOThread(StartMode start_mode)
    : io_platform_handle_watcher_(nullptr) {
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
  CHECK(!io_thread_);
  io_thread_ =
      CreateAndStartIOThread(&io_task_runner_, &io_platform_handle_watcher_);
}

void TestIOThread::Stop() {
  if (!io_thread_)
    return;  // Nothing to do.

  io_thread_->Stop();
  io_thread_.reset();
  io_task_runner_ = nullptr;
  io_platform_handle_watcher_ = nullptr;
}

bool TestIOThread::IsCurrentAndRunning() const {
  return io_task_runner_->RunsTasksOnCurrentThread();
}

void TestIOThread::PostTask(std::function<void()>&& task) {
  io_task_runner_->PostTask(std::move(task));
}

void TestIOThread::PostTaskAndWait(std::function<void()>&& task) {
  AutoResetWaitableEvent event;
  io_task_runner_->PostTask([&task, &event]() {
    task();
    event.Signal();
  });
  event.Wait();
}

}  // namespace test
}  // namespace system
}  // namespace mojo
