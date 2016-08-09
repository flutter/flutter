// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_message_loop_for_io_impl.h"

#include "base/logging.h"
#include "base/macros.h"
#include "mojo/edk/base_edk/platform_task_runner_impl.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::TaskRunner;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace base_edk {

PlatformMessageLoopForIOImpl::PlatformMessageLoopForIOImpl()
    : task_runner_(MakeRefCounted<PlatformTaskRunnerImpl>(
          base_message_loop_for_io_.task_runner())),
      platform_handle_watcher_(&base_message_loop_for_io_) {}

PlatformMessageLoopForIOImpl::~PlatformMessageLoopForIOImpl() {}

void PlatformMessageLoopForIOImpl::Run() {
  base_message_loop_for_io_.Run();
}

void PlatformMessageLoopForIOImpl::RunUntilIdle() {
  base_message_loop_for_io_.RunUntilIdle();
}

void PlatformMessageLoopForIOImpl::QuitWhenIdle() {
  base_message_loop_for_io_.QuitWhenIdle();
}

void PlatformMessageLoopForIOImpl::QuitNow() {
  base_message_loop_for_io_.QuitNow();
}

const RefPtr<TaskRunner>& PlatformMessageLoopForIOImpl::GetTaskRunner() const {
  return task_runner_;
}

bool PlatformMessageLoopForIOImpl::IsRunningOnCurrentThread() const {
  return base::MessageLoop::current() == &base_message_loop_for_io_ &&
         base_message_loop_for_io_.is_running();
}

}  // namespace base_edk
