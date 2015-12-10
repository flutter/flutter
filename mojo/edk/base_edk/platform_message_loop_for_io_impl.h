// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an implementation of |mojo::platform::MessageLoop| that
// wraps a |base::MessageLoopForIO| and also provides a
// |mojo::platform::PlatformHandleWatcher|.

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_IMPL_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_IMPL_H_

#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/base_edk/platform_handle_watcher_impl.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/task_runner.h"

namespace base_edk {

class PlatformMessageLoopForIOImpl : public mojo::platform::MessageLoop {
 public:
  PlatformMessageLoopForIOImpl();
  ~PlatformMessageLoopForIOImpl() override;

  const base::MessageLoopForIO& base_message_loop_for_io() const {
    return base_message_loop_for_io_;
  }
  base::MessageLoopForIO& base_message_loop_for_io() {
    return base_message_loop_for_io_;
  }

  const mojo::platform::PlatformHandleWatcher& platform_handle_watcher() const {
    return platform_handle_watcher_;
  }
  mojo::platform::PlatformHandleWatcher& platform_handle_watcher() {
    return platform_handle_watcher_;
  }

  // |mojo::platform::MessageLoop| implementation:
  void Run() override;
  void RunUntilIdle() override;
  void QuitWhenIdle() override;
  void QuitNow() override;
  const mojo::util::RefPtr<mojo::platform::TaskRunner>& GetTaskRunner()
      const override;
  bool IsRunningOnCurrentThread() const override;

 private:
  base::MessageLoopForIO base_message_loop_for_io_;
  mojo::util::RefPtr<mojo::platform::TaskRunner> task_runner_;
  PlatformHandleWatcherImpl platform_handle_watcher_;

  DISALLOW_COPY_AND_ASSIGN(PlatformMessageLoopForIOImpl);
};

}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_MESSAGE_LOOP_FOR_IO_IMPL_H_
