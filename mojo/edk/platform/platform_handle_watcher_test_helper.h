// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_HELPER_H_
#define MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_HELPER_H_

namespace mojo {
namespace platform {

class MessageLoop;
class PlatformHandleWatcher;

namespace test {

// This does a basic, generic test of the given platform handle watcher using
// the given message loop.
void PlatformHandleWatcherTestHelper(
    MessageLoop* message_loop,
    PlatformHandleWatcher* platform_handle_watcher);

}  // namespace test
}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_HANDLE_WATCHER_HELPER_H_
