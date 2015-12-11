// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(vtl): Maybe this test should actually be in //mojo/edk/platform?

#include "mojo/edk/platform/test_message_loops.h"

#include <memory>

#include "mojo/edk/base_edk/message_loop_test_helper.h"
#include "mojo/edk/base_edk/platform_handle_watcher_test_helper.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::PlatformHandleWatcher;

namespace {

TEST(TestMessageLoopsTest, CreateTestMessageLoop) {
  std::unique_ptr<MessageLoop> message_loop =
      mojo::platform::test::CreateTestMessageLoop();
  base_edk::test::MessageLoopTestHelper(message_loop.get());
}

TEST(TestMessageLoopsTest, CreateTestMessageLoopForIO) {
  PlatformHandleWatcher* platform_handle_watcher = nullptr;
  std::unique_ptr<MessageLoop> message_loop =
      mojo::platform::test::CreateTestMessageLoopForIO(
          &platform_handle_watcher);
  EXPECT_TRUE(platform_handle_watcher);

  base_edk::test::MessageLoopTestHelper(message_loop.get());
  base_edk::test::PlatformHandleWatcherTestHelper(message_loop.get(),
                                                  platform_handle_watcher);
}

}  // namespace
