// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file declares factory functions (which must be implemented by the
// embedder) for message loops to be used in tests.

#ifndef MOJO_EDK_PLATFORM_TEST_MESSAGE_LOOPS_H_
#define MOJO_EDK_PLATFORM_TEST_MESSAGE_LOOPS_H_

#include <memory>

namespace mojo {
namespace platform {

class MessageLoop;
class PlatformHandleWatcher;

namespace test {

// Creates a basic |MessageLoop|, to be used by tests. This must be implemented
// by the embedder (if building tests that require it).
std::unique_ptr<MessageLoop> CreateTestMessageLoop();

// Creates a basic |MessageLoop| that supports watching |PlatformHandle|s, to be
// used by tests. This must be implemented by the embedder (if building tests
// that require it). The "out" |PlatformHandleWatcher| is valid while the
// returned |MessageLoop| is alive (and will watch handles while it is running).
std::unique_ptr<MessageLoop> CreateTestMessageLoopForIO(
    PlatformHandleWatcher** platform_handle_watcher);

}  // namespace test
}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_TEST_MESSAGE_LOOPS_H_
