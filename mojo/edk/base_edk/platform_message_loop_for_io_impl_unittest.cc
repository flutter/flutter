// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_message_loop_for_io_impl.h"

#include "base/message_loop/message_loop.h"
#include "mojo/edk/platform/message_loop_test_helper.h"
#include "mojo/edk/platform/platform_handle_watcher_test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::test::MessageLoopTestHelper;
using mojo::platform::test::PlatformHandleWatcherTestHelper;

namespace base_edk {
namespace {

TEST(PlatformMessageLoopForIOImplTest, Basic) {
  PlatformMessageLoopForIOImpl message_loop_for_io;
  EXPECT_EQ(base::MessageLoop::TYPE_IO,
            message_loop_for_io.base_message_loop_for_io().type());
  MessageLoopTestHelper(&message_loop_for_io);
}

TEST(PlatformMessageLoopForIOImplTest, Watch) {
  PlatformMessageLoopForIOImpl message_loop_for_io;
  PlatformHandleWatcherTestHelper(
      &message_loop_for_io, &message_loop_for_io.platform_handle_watcher());
}

}  // namespace
}  // namespace base_edk
