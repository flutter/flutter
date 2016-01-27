// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/base_edk/platform_message_loop_impl.h"

#include "base/message_loop/message_loop.h"
#include "base/message_loop/message_pump_default.h"
#include "mojo/edk/platform/message_loop_test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::test::MessageLoopTestHelper;

namespace base_edk {
namespace {

TEST(PlatformMessageLoopImplTest, TypeDefault) {
  PlatformMessageLoopImpl message_loop;
  EXPECT_EQ(base::MessageLoop::TYPE_DEFAULT,
            message_loop.base_message_loop().type());
  MessageLoopTestHelper(&message_loop);
}

TEST(PlatformMessageLoopImplTest, TypeIO) {
  PlatformMessageLoopImpl message_loop(base::MessageLoop::TYPE_IO);
  EXPECT_EQ(base::MessageLoop::TYPE_IO,
            message_loop.base_message_loop().type());
  MessageLoopTestHelper(&message_loop);
}

TEST(PlatformMessageLoopImplTest, TypeCustom) {
  PlatformMessageLoopImpl message_loop(
      make_scoped_ptr(new base::MessagePumpDefault()));
  EXPECT_EQ(base::MessageLoop::TYPE_CUSTOM,
            message_loop.base_message_loop().type());
  MessageLoopTestHelper(&message_loop);
}

}  // namespace
}  // namespace base_edk
