// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_TEST_SCOPED_IPC_SUPPORT_H_
#define MOJO_EDK_TEST_SCOPED_IPC_SUPPORT_H_

#include <functional>

#include "mojo/edk/embedder/master_process_delegate.h"
#include "mojo/edk/embedder/process_delegate.h"
#include "mojo/edk/embedder/process_type.h"
#include "mojo/edk/embedder/slave_process_delegate.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace platform {
class PlatformHandleWatcher;
}

namespace test {

namespace internal {

class ScopedIPCSupportHelper final {
 public:
  ScopedIPCSupportHelper();
  ~ScopedIPCSupportHelper();

  void Init(embedder::ProcessType process_type,
            embedder::ProcessDelegate* process_delegate,
            util::RefPtr<platform::TaskRunner>&& io_task_runner,
            platform::PlatformHandleWatcher* io_watcher,
            platform::ScopedPlatformHandle platform_handle);

  void OnShutdownCompleteImpl();

 private:
  util::RefPtr<platform::TaskRunner> io_task_runner_;
  platform::PlatformHandleWatcher* io_watcher_ = nullptr;

  // Set after shut down.
  util::ManualResetWaitableEvent event_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedIPCSupportHelper);
};

}  // namespace internal

// A simple class that calls |mojo::embedder::InitIPCSupport()| (with
// |ProcessType::NONE|) on construction and |ShutdownIPCSupport()| on
// destruction (or |ShutdownIPCSupportOnIOThread()| if destroyed on the I/O
// thread).
class ScopedIPCSupport final : public embedder::ProcessDelegate {
 public:
  ScopedIPCSupport(util::RefPtr<platform::TaskRunner>&& io_task_runner,
                   platform::PlatformHandleWatcher* io_watcher);
  ~ScopedIPCSupport() override;

 private:
  // |ProcessDelegate| implementation:
  // Note: Executed on the I/O thread.
  void OnShutdownComplete() override;

  internal::ScopedIPCSupportHelper helper_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedIPCSupport);
};

// Like |ScopedIPCSupport|, but with |ProcessType::MASTER|. It will (optionally)
// call a callback (on the I/O thread) on receiving |OnSlaveDisconnect()|.
class ScopedMasterIPCSupport final : public embedder::MasterProcessDelegate {
 public:
  ScopedMasterIPCSupport(util::RefPtr<platform::TaskRunner>&& io_task_runner,
                         platform::PlatformHandleWatcher* io_watcher);
  ScopedMasterIPCSupport(util::RefPtr<platform::TaskRunner>&& io_task_runner,
                         platform::PlatformHandleWatcher* io_watcher,
                         std::function<void(embedder::SlaveInfo slave_info)>&&
                             on_slave_disconnect);
  ~ScopedMasterIPCSupport() override;

 private:
  // |MasterProcessDelegate| implementation:
  // Note: Executed on the I/O thread.
  void OnShutdownComplete() override;
  void OnSlaveDisconnect(embedder::SlaveInfo slave_info) override;

  internal::ScopedIPCSupportHelper helper_;
  std::function<void(embedder::SlaveInfo slave_info)> on_slave_disconnect_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedMasterIPCSupport);
};

// Like |ScopedIPCSupport|, but with |ProcessType::SLAVE|. It will (optionally)
// call a callback (on the I/O thread) on receiving |OnMasterDisconnect()|.
class ScopedSlaveIPCSupport final : public embedder::SlaveProcessDelegate {
 public:
  ScopedSlaveIPCSupport(util::RefPtr<platform::TaskRunner>&& io_task_runner,
                        platform::PlatformHandleWatcher* io_watcher,
                        platform::ScopedPlatformHandle platform_handle);
  ScopedSlaveIPCSupport(util::RefPtr<platform::TaskRunner>&& io_task_runner,
                        platform::PlatformHandleWatcher* io_watcher,
                        platform::ScopedPlatformHandle platform_handle,
                        std::function<void()>&& on_master_disconnect);
  ~ScopedSlaveIPCSupport() override;

 private:
  // |SlaveProcessDelegate| implementation:
  // Note: Executed on the I/O thread.
  void OnShutdownComplete() override;
  void OnMasterDisconnect() override;

  internal::ScopedIPCSupportHelper helper_;
  std::function<void()> on_master_disconnect_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedSlaveIPCSupport);
};

}  // namespace test
}  // namespace mojo

#endif  // MOJO_EDK_TEST_SCOPED_IPC_SUPPORT_H_
