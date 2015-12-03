// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/scoped_ipc_support.h"

#include "base/message_loop/message_loop.h"
#include "mojo/edk/embedder/embedder.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::util::RefPtr;

namespace mojo {
namespace test {

namespace internal {

ScopedIPCSupportHelper::ScopedIPCSupportHelper() {}

ScopedIPCSupportHelper::~ScopedIPCSupportHelper() {
  if (io_thread_task_runner_->RunsTasksOnCurrentThread()) {
    embedder::ShutdownIPCSupportOnIOThread();
  } else {
    embedder::ShutdownIPCSupport();
    event_.Wait();
  }
}

void ScopedIPCSupportHelper::Init(embedder::ProcessType process_type,
                                  embedder::ProcessDelegate* process_delegate,
                                  RefPtr<TaskRunner>&& io_thread_task_runner,
                                  ScopedPlatformHandle platform_handle) {
  io_thread_task_runner_ = std::move(io_thread_task_runner);
  // Note: Run delegate methods on the I/O thread.
  embedder::InitIPCSupport(process_type, io_thread_task_runner_.Clone(),
                           process_delegate, io_thread_task_runner_.Clone(),
                           platform_handle.Pass());
}

void ScopedIPCSupportHelper::OnShutdownCompleteImpl() {
  event_.Signal();
}

}  // namespace internal

ScopedIPCSupport::ScopedIPCSupport(RefPtr<TaskRunner>&& io_thread_task_runner) {
  helper_.Init(embedder::ProcessType::NONE, this,
               std::move(io_thread_task_runner), ScopedPlatformHandle());
}

ScopedIPCSupport::~ScopedIPCSupport() {
}

void ScopedIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

ScopedMasterIPCSupport::ScopedMasterIPCSupport(
    RefPtr<TaskRunner>&& io_thread_task_runner) {
  helper_.Init(embedder::ProcessType::MASTER, this,
               std::move(io_thread_task_runner), ScopedPlatformHandle());
}

ScopedMasterIPCSupport::ScopedMasterIPCSupport(
    RefPtr<TaskRunner>&& io_thread_task_runner,
    base::Callback<void(embedder::SlaveInfo slave_info)> on_slave_disconnect)
    : on_slave_disconnect_(on_slave_disconnect) {
  helper_.Init(embedder::ProcessType::MASTER, this,
               std::move(io_thread_task_runner), ScopedPlatformHandle());
}

ScopedMasterIPCSupport::~ScopedMasterIPCSupport() {
}

void ScopedMasterIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

void ScopedMasterIPCSupport::OnSlaveDisconnect(embedder::SlaveInfo slave_info) {
  if (!on_slave_disconnect_.is_null())
    on_slave_disconnect_.Run(slave_info);
}

ScopedSlaveIPCSupport::ScopedSlaveIPCSupport(
    RefPtr<TaskRunner>&& io_thread_task_runner,
    ScopedPlatformHandle platform_handle) {
  helper_.Init(embedder::ProcessType::SLAVE, this,
               std::move(io_thread_task_runner), platform_handle.Pass());
}

ScopedSlaveIPCSupport::ScopedSlaveIPCSupport(
    RefPtr<TaskRunner>&& io_thread_task_runner,
    ScopedPlatformHandle platform_handle,
    base::Closure on_master_disconnect)
    : on_master_disconnect_(on_master_disconnect) {
  helper_.Init(embedder::ProcessType::SLAVE, this,
               std::move(io_thread_task_runner), platform_handle.Pass());
}

ScopedSlaveIPCSupport::~ScopedSlaveIPCSupport() {
}

void ScopedSlaveIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

void ScopedSlaveIPCSupport::OnMasterDisconnect() {
  if (!on_master_disconnect_.is_null())
    on_master_disconnect_.Run();
}

}  // namespace test
}  // namespace mojo
