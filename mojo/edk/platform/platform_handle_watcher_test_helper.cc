// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/platform_handle_watcher_test_helper.h"

#include <unistd.h>

#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_handle_watcher.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "testing/gtest/include/gtest/gtest.h"

// A poor man's copy of the one from //base/posix/eintr_wrapper.h (avoiding the
// //base dependency).
#define HANDLE_EINTR(x) ({ \
  decltype(x) eintr_wrapper_result; \
  do { \
    eintr_wrapper_result = (x); \
  } while (eintr_wrapper_result == -1 && errno == EINTR); \
  eintr_wrapper_result; \
})

namespace mojo {
namespace platform {
namespace test {

void PlatformHandleWatcherTestHelper(
    MessageLoop* message_loop,
    PlatformHandleWatcher* platform_handle_watcher) {
  const char kHello[] = "hello";

  // TODO(vtl): This is an extremely cursory test. We should test more carefully
  // (e.g., we should test that the watch callbacks aren't called spuriously,
  // that the "persist" flag works correctly, and that cancellation works).
  int pipe_fds[2] = {};
  ASSERT_EQ(pipe(pipe_fds), 0);
  // The read end.
  ScopedPlatformHandle h0((PlatformHandle(pipe_fds[0])));
  ASSERT_TRUE(h0.is_valid());
  // The write end.
  ScopedPlatformHandle h1((PlatformHandle(pipe_fds[1])));
  ASSERT_TRUE(h1.is_valid());

  // Watch for read on |h1|; it should never trigger.
  std::unique_ptr<PlatformHandleWatcher::WatchToken> watch1 =
      platform_handle_watcher->Watch(
          h1.get(), false, []() { EXPECT_TRUE(false); },
          [&h1, &kHello]() {
            EXPECT_EQ(static_cast<ssize_t>(sizeof(kHello)),
                      HANDLE_EINTR(write(h1.get().fd, kHello, sizeof(kHello))));
          });
  unsigned h0_read_count = 0u;
  std::unique_ptr<PlatformHandleWatcher::WatchToken> watch0 =
      platform_handle_watcher->Watch(
          h0.get(), true, [&h0_read_count, &h0, &kHello, message_loop]() {
            char buf[100] = {};
            h0_read_count++;
            EXPECT_EQ(static_cast<ssize_t>(sizeof(kHello)),
                      HANDLE_EINTR(read(h0.get().fd, buf, sizeof(buf))));
            EXPECT_STREQ(kHello, buf);
            message_loop->QuitWhenIdle();
          }, nullptr);
  message_loop->Run();
  EXPECT_EQ(1u, h0_read_count);
}

}  // namespace test
}  // namespace platform
}  // namespace mojo
