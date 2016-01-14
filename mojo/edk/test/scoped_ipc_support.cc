// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/scoped_ipc_support.h"

#include <utility>

#include "mojo/edk/embedder/multiprocess_embedder.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::util::RefPtr;

namespace mojo {
namespace test {

namespace internal {

ScopedIPCSupportHelper::ScopedIPCSupportHelper() {}

ScopedIPCSupportHelper::~ScopedIPCSupportHelper() {
  if (io_task_runner_->RunsTasksOnCurrentThread()) {
    embedder::ShutdownIPCSupportOnIOThread();
  } else {
    embedder::ShutdownIPCSupport();
    event_.Wait();
  }
}

void ScopedIPCSupportHelper::Init(embedder::ProcessType process_type,
                                  embedder::ProcessDelegate* process_delegate,
                                  RefPtr<TaskRunner>&& io_task_runner,
                                  PlatformHandleWatcher* io_watcher,
                                  ScopedPlatformHandle platform_handle) {
  io_task_runner_ = std::move(io_task_runner);
  io_watcher_ = io_watcher;
  // Note: Run delegate methods on the I/O thread.
  embedder::InitIPCSupport(process_type, io_task_runner_.Clone(),
                           process_delegate, io_task_runner_.Clone(),
                           io_watcher_, platform_handle.Pass());
}

void ScopedIPCSupportHelper::OnShutdownCompleteImpl() {
  event_.Signal();
}

}  // namespace internal

ScopedIPCSupport::ScopedIPCSupport(RefPtr<TaskRunner>&& io_task_runner,
                                   PlatformHandleWatcher* io_watcher) {
  helper_.Init(embedder::ProcessType::NONE, this, std::move(io_task_runner),
               io_watcher, ScopedPlatformHandle());
}

ScopedIPCSupport::~ScopedIPCSupport() {
}

void ScopedIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

ScopedMasterIPCSupport::ScopedMasterIPCSupport(
    RefPtr<TaskRunner>&& io_task_runner,
    PlatformHandleWatcher* io_watcher) {
  helper_.Init(embedder::ProcessType::MASTER, this, std::move(io_task_runner),
               io_watcher, ScopedPlatformHandle());
}

ScopedMasterIPCSupport::ScopedMasterIPCSupport(
    RefPtr<TaskRunner>&& io_task_runner,
    PlatformHandleWatcher* io_watcher,
    std::function<void(embedder::SlaveInfo slave_info)>&& on_slave_disconnect)
    : on_slave_disconnect_(std::move(on_slave_disconnect)) {
  helper_.Init(embedder::ProcessType::MASTER, this, std::move(io_task_runner),
               io_watcher, ScopedPlatformHandle());
}

ScopedMasterIPCSupport::~ScopedMasterIPCSupport() {
}

void ScopedMasterIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

void ScopedMasterIPCSupport::OnSlaveDisconnect(embedder::SlaveInfo slave_info) {
  if (on_slave_disconnect_)
    on_slave_disconnect_(slave_info);
}

ScopedSlaveIPCSupport::ScopedSlaveIPCSupport(
    RefPtr<TaskRunner>&& io_task_runner,
    PlatformHandleWatcher* io_watcher,
    ScopedPlatformHandle platform_handle) {
  helper_.Init(embedder::ProcessType::SLAVE, this, std::move(io_task_runner),
               io_watcher, platform_handle.Pass());
}

ScopedSlaveIPCSupport::ScopedSlaveIPCSupport(
    RefPtr<TaskRunner>&& io_task_runner,
    PlatformHandleWatcher* io_watcher,
    ScopedPlatformHandle platform_handle,
    std::function<void()>&& on_master_disconnect)
    : on_master_disconnect_(std::move(on_master_disconnect)) {
  helper_.Init(embedder::ProcessType::SLAVE, this, std::move(io_task_runner),
               io_watcher, platform_handle.Pass());
}

ScopedSlaveIPCSupport::~ScopedSlaveIPCSupport() {
}

void ScopedSlaveIPCSupport::OnShutdownComplete() {
  helper_.OnShutdownCompleteImpl();
}

void ScopedSlaveIPCSupport::OnMasterDisconnect() {
  if (on_master_disconnect_)
    on_master_disconnect_();
}

}  // namespace test
}  // namespace mojo
