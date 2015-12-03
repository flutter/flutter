// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(vtl): Maybe this test should actually be in //mojo/edk/platform?

#include "mojo/edk/platform/test_message_loops.h"

#include <memory>

#include "mojo/edk/base_edk/message_loop_test_helper.h"
#include "mojo/edk/platform/message_loop.h"
#include "mojo/edk/platform/message_loop_for_io.h"
#include "mojo/edk/platform/test_message_loops.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::MessageLoop;
using mojo::platform::MessageLoopForIO;

namespace {

TEST(TestMessageLoopsTest, CreateTestMessageLoop) {
  std::unique_ptr<MessageLoop> message_loop =
      mojo::platform::test::CreateTestMessageLoop();
  base_edk::test::MessageLoopTestHelper(message_loop.get());
}

TEST(TestMessageLoopsTest, CreateTestMessageLoopForIO) {
  std::unique_ptr<MessageLoopForIO> message_loop_for_io =
      mojo::platform::test::CreateTestMessageLoopForIO();
  base_edk::test::MessageLoopTestHelper(message_loop_for_io.get());
}

}  // namespace
