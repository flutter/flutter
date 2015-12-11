// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the factory function declared in
// //mojo/edk/platform/io_thread.h.

#include "mojo/edk/platform/io_thread.h"

#include <memory>
#include <utility>

#include "base/logging.h"
#include "base/macros.h"
#include "base/threading/thread.h"
#include "mojo/edk/base_edk/platform_handle_watcher_impl.h"
#include "mojo/edk/base_edk/platform_task_runner_impl.h"
#include "mojo/edk/platform/thread.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/ref_ptr.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::TaskRunner;
using mojo::platform::Thread;
using mojo::util::MakeRefCounted;
using mojo::util::MakeUnique;
using mojo::util::RefPtr;

namespace base_edk {
namespace {

class IOThreadImpl : public Thread {
 public:
  IOThreadImpl() : base_thread_("EDK I/O thread") {
    // We need to start the thread in the constructor, so that the thread's
    // message loop is available. :-/
    CHECK(base_thread_.StartWithOptions(
        base::Thread::Options(base::MessageLoop::TYPE_IO, 0u)));
    DCHECK(base_thread_.message_loop());
    DCHECK_EQ(base_thread_.message_loop()->type(), base::MessageLoop::TYPE_IO);
    base::MessageLoopForIO* base_message_loop_for_io =
        static_cast<base::MessageLoopForIO*>(base_thread_.message_loop());
    task_runner_ = MakeRefCounted<PlatformTaskRunnerImpl>(
        base_message_loop_for_io->task_runner());
    platform_handle_watcher_ =
        MakeUnique<PlatformHandleWatcherImpl>(base_message_loop_for_io);
  }

  ~IOThreadImpl() override { DCHECK(stopped_); }

  // |Thread| implementation:
  void Stop() override {
    DCHECK(!stopped_);
    stopped_ = true;
    base_thread_.Stop();
  }

  const RefPtr<TaskRunner>& task_runner() const { return task_runner_; }

  PlatformHandleWatcher* platform_handle_watcher() const {
    return platform_handle_watcher_.get();
  }

 private:
  base::Thread base_thread_;
  RefPtr<TaskRunner> task_runner_;
  std::unique_ptr<PlatformHandleWatcher> platform_handle_watcher_;

  bool stopped_ = false;

  DISALLOW_COPY_AND_ASSIGN(IOThreadImpl);
};

}  // namespace
}  // namespace base_edk

namespace mojo {
namespace platform {

std::unique_ptr<Thread> CreateAndStartIOThread(
    util::RefPtr<TaskRunner>* task_runner,
    PlatformHandleWatcher** platform_handle_watcher) {
  auto rv = MakeUnique<base_edk::IOThreadImpl>();
  *task_runner = rv->task_runner();
  *platform_handle_watcher = rv->platform_handle_watcher();
  return std::move(rv);
}

}  // namespace platform
}  // namespace mojo
