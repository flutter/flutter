// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_message_loop_impl.h"

#include <utility>

#include "mojo/edk/base_edk/platform_task_runner_impl.h"

using mojo::platform::TaskRunner;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace base_edk {

PlatformMessageLoopImpl::PlatformMessageLoopImpl(base::MessageLoop::Type type)
    : base_message_loop_(type),
      task_runner_(MakeRefCounted<PlatformTaskRunnerImpl>(
          base_message_loop_.task_runner())) {}

PlatformMessageLoopImpl::PlatformMessageLoopImpl(
    scoped_ptr<base::MessagePump> pump)
    : base_message_loop_(std::move(pump)),
      task_runner_(MakeRefCounted<PlatformTaskRunnerImpl>(
          base_message_loop_.task_runner())) {}

PlatformMessageLoopImpl::~PlatformMessageLoopImpl() {}

void PlatformMessageLoopImpl::Run() {
  base_message_loop_.Run();
}

void PlatformMessageLoopImpl::RunUntilIdle() {
  base_message_loop_.RunUntilIdle();
}

void PlatformMessageLoopImpl::QuitWhenIdle() {
  base_message_loop_.QuitWhenIdle();
}

void PlatformMessageLoopImpl::QuitNow() {
  base_message_loop_.QuitNow();
}

const RefPtr<TaskRunner>& PlatformMessageLoopImpl::GetTaskRunner() const {
  return task_runner_;
}

bool PlatformMessageLoopImpl::IsRunningOnCurrentThread() const {
  return base::MessageLoop::current() == &base_message_loop_ &&
         base_message_loop_.is_running();
}

}  // namespace base_edk
