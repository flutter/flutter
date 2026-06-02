// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include <memory>
#include <vector>

#include "fml/status.h"
#include "impeller/renderer/testing/mocks.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter::gpu {
namespace {

using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockCommandQueue;
using ::impeller::testing::MockImpellerContext;
using ::testing::_;
using ::testing::DoAll;
using ::testing::Invoke;
using ::testing::Return;

TEST(FlutterGpuCommandBufferTest,
     InvokesRegisteredCompletionCallbacksOnSubmit) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto command_queue = std::make_shared<MockCommandQueue>();
  CommandBuffer command_buffer(context, impeller_command_buffer);

  std::vector<impeller::CommandBuffer::Status> statuses;

  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));

  EXPECT_CALL(*context, GetBackendType)
      .WillOnce(Return(impeller::Context::BackendType::kMetal));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _, _))
      .WillOnce(DoAll(
          Invoke([](const std::vector<std::shared_ptr<
                        impeller::CommandBuffer>>& buffers,
                    const impeller::CommandQueue::CompletionCallback& callback,
                    bool block_on_schedule) {
            EXPECT_EQ(buffers.size(), 1u);
            EXPECT_FALSE(block_on_schedule);
            callback(impeller::CommandBuffer::Status::kCompleted);
          }),
          Return(fml::Status())));

  EXPECT_TRUE(command_buffer.Submit(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  EXPECT_EQ(statuses.size(), 3u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kCompleted);
  EXPECT_EQ(statuses[1], impeller::CommandBuffer::Status::kCompleted);
  EXPECT_EQ(statuses[2], impeller::CommandBuffer::Status::kCompleted);
}

TEST(FlutterGpuCommandBufferTest,
     RejectsCompletionCallbacksAfterSubmit) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto command_queue = std::make_shared<MockCommandQueue>();
  CommandBuffer command_buffer(context, impeller_command_buffer);

  EXPECT_CALL(*context, GetBackendType)
      .WillOnce(Return(impeller::Context::BackendType::kMetal));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _, _))
      .WillOnce(Return(fml::Status()));

  EXPECT_TRUE(command_buffer.Submit());
  EXPECT_FALSE(command_buffer.AddCompletionCallback(
      [](impeller::CommandBuffer::Status status) { (void)status; }));
  EXPECT_FALSE(command_buffer.Submit());
}

TEST(FlutterGpuCommandBufferTest,
     InvokesRegisteredCompletionCallbacksWhenSubmitFails) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto command_queue = std::make_shared<MockCommandQueue>();
  CommandBuffer command_buffer(context, impeller_command_buffer);

  std::vector<impeller::CommandBuffer::Status> statuses;

  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));

  EXPECT_CALL(*context, GetBackendType)
      .WillOnce(Return(impeller::Context::BackendType::kMetal));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _, _))
      .WillOnce(Return(fml::Status(fml::StatusCode::kInternal,
                                   "Command queue submit failed.")));

  EXPECT_FALSE(command_buffer.Submit());
  EXPECT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

}  // namespace
}  // namespace flutter::gpu
