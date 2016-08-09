// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an implementation of
// |mojo::platform::PlatformHandleWatcher| that uses a |base::MessageLoopForIO|
// (which it does not own).

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_IMPL_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_IMPL_H_

#include "base/macros.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/platform/platform_handle_watcher.h"

namespace base_edk {

class PlatformHandleWatcherImpl : public mojo::platform::PlatformHandleWatcher {
 public:
  explicit PlatformHandleWatcherImpl(
      base::MessageLoopForIO* base_message_loop_for_io);
  ~PlatformHandleWatcherImpl() override;

  // |mojo::platform::PlatformHandleWatcher| implementation:
  std::unique_ptr<WatchToken> Watch(
      mojo::platform::PlatformHandle platform_handle,
      bool persistent,
      std::function<void()>&& read_callback,
      std::function<void()>&& write_callback) override;

 private:
  base::MessageLoopForIO* const base_message_loop_for_io_;

  DISALLOW_COPY_AND_ASSIGN(PlatformHandleWatcherImpl);
};

}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_IMPL_H_
