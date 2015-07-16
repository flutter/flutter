// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/thread_task_runner_handle.h"

#include "base/lazy_instance.h"
#include "base/single_thread_task_runner.h"
#include "base/threading/thread_local.h"

namespace base {

namespace {

base::LazyInstance<base::ThreadLocalPointer<ThreadTaskRunnerHandle> >
    lazy_tls_ptr = LAZY_INSTANCE_INITIALIZER;

}  // namespace

// static
scoped_refptr<SingleThreadTaskRunner> ThreadTaskRunnerHandle::Get() {
  ThreadTaskRunnerHandle* current = lazy_tls_ptr.Pointer()->Get();
  DCHECK(current);
  return current->task_runner_;
}

// static
bool ThreadTaskRunnerHandle::IsSet() {
  return lazy_tls_ptr.Pointer()->Get() != NULL;
}

ThreadTaskRunnerHandle::ThreadTaskRunnerHandle(
    const scoped_refptr<SingleThreadTaskRunner>& task_runner)
    : task_runner_(task_runner) {
  DCHECK(task_runner_->BelongsToCurrentThread());
  DCHECK(!lazy_tls_ptr.Pointer()->Get());
  lazy_tls_ptr.Pointer()->Set(this);
}

ThreadTaskRunnerHandle::~ThreadTaskRunnerHandle() {
  DCHECK(task_runner_->BelongsToCurrentThread());
  DCHECK_EQ(lazy_tls_ptr.Pointer()->Get(), this);
  lazy_tls_ptr.Pointer()->Set(NULL);
}

}  // namespace base
