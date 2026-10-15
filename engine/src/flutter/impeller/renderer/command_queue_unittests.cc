// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/command_queue.h"

#include "flutter/testing/testing.h"
#include "impeller/renderer/testing/mocks.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::Return;

TEST(CommandQueueTest, BackendWithoutSchedulingReceiptReturnsNullReceipt) {
  auto command_buffer =
      std::make_shared<MockCommandBuffer>(std::weak_ptr<const Context>{});
  EXPECT_CALL(*command_buffer, IsValid()).WillOnce(Return(true));
  EXPECT_CALL(*command_buffer, OnSubmitCommands(_)).WillOnce(Return(true));

  CommandQueue queue;
  CommandQueue::SubmitResult result = queue.SubmitWithReceipt(command_buffer);

  EXPECT_TRUE(result.status.ok());
  EXPECT_EQ(result.scheduling_receipt, nullptr);
}

}  // namespace testing
}  // namespace impeller
