// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/test_io_thread.h"

#include "base/bind.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/synchronization/waitable_event.h"

namespace mojo {
namespace system {
namespace test {

namespace {

void PostTaskAndWaitHelper(base::WaitableEvent* event,
                           const base::Closure& task) {
  task.Run();
  event->Signal();
}

}  // namespace

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
}

void TestIOThread::Stop() {
  // Note: It's okay to call |Stop()| even if the thread isn't running.
  io_thread_.Stop();
  io_thread_started_ = false;
}

void TestIOThread::PostTask(const base::Closure& task) {
  task_runner()->PostTask(tracked_objects::Location(), task);
}

void TestIOThread::PostTaskAndWait(const base::Closure& task) {
  base::WaitableEvent event(false, false);
  task_runner()->PostTask(tracked_objects::Location(),
                          base::Bind(&PostTaskAndWaitHelper, &event, task));
  event.Wait();
}

}  // namespace test
}  // namespace system
}  // namespace mojo
