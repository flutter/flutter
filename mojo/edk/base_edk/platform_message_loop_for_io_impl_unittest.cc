// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_message_loop_for_io_impl.h"

#include "base/message_loop/message_loop.h"
#include "mojo/edk/base_edk/message_loop_test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;

namespace base_edk {
namespace {

TEST(PlatformMessageLoopForIOImplTest, Basic) {
  PlatformMessageLoopForIOImpl message_loop_for_io;
  EXPECT_EQ(base::MessageLoop::TYPE_IO,
            message_loop_for_io.base_message_loop_for_io().type());
  test::MessageLoopTestHelper(&message_loop_for_io);
}

}  // namespace
}  // namespace base_edk
