// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_HELPER_H_
#define MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_HELPER_H_

namespace mojo {
namespace platform {
class MessageLoop;
class PlatformHandleWatcher;
}  // namespace platform
}  // namespace mojo

namespace base_edk {
namespace test {

void PlatformHandleWatcherTestHelper(
    mojo::platform::MessageLoop* message_loop,
    mojo::platform::PlatformHandleWatcher* platform_handle_watcher);

}  // namespace test
}  // namespace base_edk

#endif  // MOJO_EDK_BASE_EDK_PLATFORM_HANDLE_WATCHER_HELPER_H_
