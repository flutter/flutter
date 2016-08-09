// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/test_message_loops.h"

#include <memory>

#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/message_loop_test_helper.h"
#include "mojo/edk/platform/platform_handle_watcher_test_helper.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace platform {
namespace {

TEST(TestMessageLoopsTest, CreateTestMessageLoop) {
  std::unique_ptr<MessageLoop> message_loop = test::CreateTestMessageLoop();
  test::MessageLoopTestHelper(message_loop.get());
}

TEST(TestMessageLoopsTest, CreateTestMessageLoopForIO) {
  PlatformHandleWatcher* platform_handle_watcher = nullptr;
  std::unique_ptr<MessageLoop> message_loop =
      test::CreateTestMessageLoopForIO(&platform_handle_watcher);
  EXPECT_TRUE(platform_handle_watcher);

  test::MessageLoopTestHelper(message_loop.get());
  test::PlatformHandleWatcherTestHelper(message_loop.get(),
                                        platform_handle_watcher);
}

}  // namespace
}  // namespace platform
}  // namespace mojo
