// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_handle_watcher_impl.h"

#include "base/logging.h"
#include "base/macros.h"
#include "mojo/edk/util/make_unique.h"

using mojo::platform::PlatformHandle;
using mojo::platform::PlatformHandleWatcher;
using mojo::util::MakeUnique;

namespace base_edk {

namespace {

class WatchTokenImpl : public PlatformHandleWatcher::WatchToken,
                       public base::MessageLoopForIO::Watcher {
 public:
  WatchTokenImpl(std::function<void()>&& read_callback,
                 std::function<void()>&& write_callback)
      : read_callback_(std::move(read_callback)),
        write_callback_(std::move(write_callback)) {}
  ~WatchTokenImpl() override {}

  base::MessageLoopForIO::FileDescriptorWatcher* base_fd_watcher() {
    return &base_fd_watcher_;
  }

 private:
  // |base::MessageLoopForIO::Watcher| implementation:
  void OnFileCanReadWithoutBlocking(int /*fd*/) override {
    DCHECK(read_callback_);
    read_callback_();
  }

  void OnFileCanWriteWithoutBlocking(int /*fd*/) override {
    DCHECK(write_callback_);
    write_callback_();
  }

  const std::function<void()> read_callback_;
  const std::function<void()> write_callback_;

  base::MessageLoopForIO::FileDescriptorWatcher base_fd_watcher_;

  DISALLOW_COPY_AND_ASSIGN(WatchTokenImpl);
};

}  // namespace

PlatformHandleWatcherImpl::PlatformHandleWatcherImpl(
    base::MessageLoopForIO* base_message_loop_for_io)
    : base_message_loop_for_io_(base_message_loop_for_io) {}

PlatformHandleWatcherImpl::~PlatformHandleWatcherImpl() {}

std::unique_ptr<PlatformHandleWatcher::WatchToken>
PlatformHandleWatcherImpl::Watch(PlatformHandle platform_handle,
                                 bool persistent,
                                 std::function<void()>&& read_callback,
                                 std::function<void()>&& write_callback) {
  DCHECK(platform_handle.is_valid());
  DCHECK(read_callback || write_callback);

  base::MessageLoopForIO::Mode mode;
  if (read_callback && write_callback) {
    mode = base::MessageLoopForIO::WATCH_READ_WRITE;
  } else if (read_callback) {
    mode = base::MessageLoopForIO::WATCH_READ;
  } else {
    DCHECK(write_callback);
    mode = base::MessageLoopForIO::WATCH_WRITE;
  }
  auto rv = MakeUnique<WatchTokenImpl>(std::move(read_callback),
                                       std::move(write_callback));
  CHECK(base_message_loop_for_io_->WatchFileDescriptor(
      platform_handle.fd, persistent, mode, rv->base_fd_watcher(), rv.get()));
  return std::move(rv);
}

}  // namespace base_edk
