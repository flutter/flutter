// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include <memory>
#include <vector>

#include "flutter/lib/gpu/render_pass.h"
#include "flutter/lib/gpu/texture.h"
#include "fml/memory/ref_ptr.h"
#include "fml/status.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::impeller::testing::MockBlitPass;
using ::impeller::testing::MockCommandBuffer;
using ::impeller::testing::MockCommandQueue;
using ::impeller::testing::MockImpellerContext;
using ::impeller::testing::MockRenderPass;
using ::impeller::testing::MockTexture;
using ::testing::_;
using ::testing::DoAll;
using ::testing::InSequence;
using ::testing::NiceMock;
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
  EXPECT_CALL(*command_queue, Submit(_, _))
      .WillOnce(DoAll(
          [](const std::vector<std::shared_ptr<impeller::CommandBuffer>>&
                 buffers,
             const impeller::CommandQueue::CompletionCallback& callback) {
            EXPECT_EQ(buffers.size(), 1u);
            callback(impeller::CommandBuffer::Status::kCompleted);
          },
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

TEST(FlutterGpuCommandBufferTest, RejectsCompletionCallbacksAfterSubmit) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto command_queue = std::make_shared<MockCommandQueue>();
  CommandBuffer command_buffer(context, impeller_command_buffer);

  EXPECT_CALL(*context, GetBackendType)
      .WillOnce(Return(impeller::Context::BackendType::kMetal));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _)).WillOnce(Return(fml::Status()));

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
  EXPECT_CALL(*command_queue, Submit(_, _))
      .WillOnce(Return(fml::Status(fml::StatusCode::kInternal,
                                   "Command queue submit failed.")));

  EXPECT_FALSE(command_buffer.Submit());
  EXPECT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

// The pass lifecycle tests heap-allocate the command buffer, since it is
// ref-counted and asserts in debug builds when destroyed without a reference.
class FlutterGpuPassLifecycleTest : public ::testing::Test {
 protected:
  void SetUp() override {
    context_ = std::make_shared<NiceMock<MockImpellerContext>>();
    impeller_command_buffer_ =
        std::make_shared<NiceMock<MockCommandBuffer>>(context_);
    command_queue_ = std::make_shared<NiceMock<MockCommandQueue>>();
    ON_CALL(*context_, GetBackendType)
        .WillByDefault(Return(impeller::Context::BackendType::kMetal));
    ON_CALL(*context_, GetCommandQueue).WillByDefault(Return(command_queue_));
    command_buffer_ =
        fml::MakeRefCounted<CommandBuffer>(context_, impeller_command_buffer_);

    impeller::TextureDescriptor texture_desc;
    texture_desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    texture_desc.size = impeller::ISize(4, 4);
    auto texture = std::make_shared<NiceMock<MockTexture>>(texture_desc);
    ON_CALL(*texture, GetSize).WillByDefault(Return(impeller::ISize(4, 4)));
    texture_ = fml::MakeRefCounted<Texture>(texture);
  }

  std::shared_ptr<MockRenderPass> MakeRenderPass() {
    auto pass = std::make_shared<NiceMock<MockRenderPass>>(
        context_, impeller::RenderTarget());
    ON_CALL(*pass, IsValid).WillByDefault(Return(true));
    return pass;
  }

  std::shared_ptr<MockBlitPass> MakeBlitPass() {
    auto pass = std::make_shared<NiceMock<MockBlitPass>>();
    ON_CALL(*pass, IsValid).WillByDefault(Return(true));
    ON_CALL(*pass, OnCopyTextureToTextureCommand).WillByDefault(Return(true));
    return pass;
  }

  bool Copy() {
    return command_buffer_->CopyTextureToTexture(
        *texture_, *texture_, impeller::IRect::MakeXYWH(0, 0, 1, 1),
        impeller::IPoint(1, 1));
  }

  std::shared_ptr<NiceMock<MockImpellerContext>> context_;
  std::shared_ptr<NiceMock<MockCommandBuffer>> impeller_command_buffer_;
  std::shared_ptr<NiceMock<MockCommandQueue>> command_queue_;
  fml::RefPtr<CommandBuffer> command_buffer_;
  fml::RefPtr<Texture> texture_;
};

TEST_F(FlutterGpuPassLifecycleTest,
       EachCommandEndsTheOpenPassBeforeTheNextPassIsCreated) {
  auto blit_a = MakeBlitPass();
  auto render_a = MakeRenderPass();
  auto render_b = MakeRenderPass();
  auto blit_b = MakeBlitPass();
  {
    InSequence sequence;
    EXPECT_CALL(*impeller_command_buffer_, OnCreateBlitPass)
        .WillOnce(Return(blit_a));
    EXPECT_CALL(*blit_a, OnCopyTextureToTextureCommand);
    // A render pass ends the copies before it.
    EXPECT_CALL(*blit_a, EncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_a));
    // A render pass ends the render pass before it.
    EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_b));
    // A copy ends the render pass before it, and consecutive copies share
    // one blit pass.
    EXPECT_CALL(*render_b, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateBlitPass)
        .WillOnce(Return(blit_b));
    EXPECT_CALL(*blit_b, OnCopyTextureToTextureCommand).Times(2);
    // Submit ends the last pass only.
    EXPECT_CALL(*blit_b, EncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(fml::Status()));
  }

  EXPECT_TRUE(Copy());
  EXPECT_EQ(command_buffer_->CreateRenderPass(impeller::RenderTarget()),
            render_a);
  EXPECT_EQ(command_buffer_->CreateRenderPass(impeller::RenderTarget()),
            render_b);
  EXPECT_TRUE(Copy());
  EXPECT_TRUE(Copy());
  EXPECT_TRUE(command_buffer_->Submit());
}

TEST_F(FlutterGpuPassLifecycleTest, EndEncodesThePassOnce) {
  auto render_a = MakeRenderPass();
  {
    InSequence sequence;
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_a));
    EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(fml::Status()));
  }

  auto pass = fml::MakeRefCounted<RenderPass>();
  ASSERT_TRUE(pass->Begin(*command_buffer_));
  EXPECT_TRUE(pass->End());
  EXPECT_TRUE(pass->End());
  EXPECT_TRUE(command_buffer_->Submit());
}

TEST_F(FlutterGpuPassLifecycleTest,
       EndingAPassEndedByALaterCommandDoesNothing) {
  auto render_a = MakeRenderPass();
  auto render_b = MakeRenderPass();
  {
    InSequence sequence;
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_a));
    EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_b));
    EXPECT_CALL(*render_b, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(fml::Status()));
  }

  auto pass_a = fml::MakeRefCounted<RenderPass>();
  auto pass_b = fml::MakeRefCounted<RenderPass>();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));
  // pass_b is still open, so this must not end it.
  EXPECT_TRUE(pass_a->End());
  EXPECT_TRUE(command_buffer_->Submit());
}

TEST_F(FlutterGpuPassLifecycleTest, OpenGLESDefersEncodingToSubmit) {
  ON_CALL(*context_, GetBackendType)
      .WillByDefault(Return(impeller::Context::BackendType::kOpenGLES));
  auto render_a = MakeRenderPass();
  auto blit_a = MakeBlitPass();
  auto render_b = MakeRenderPass();
  EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
      .WillOnce(Return(render_a))
      .WillOnce(Return(render_b));
  EXPECT_CALL(*impeller_command_buffer_, OnCreateBlitPass)
      .WillOnce(Return(blit_a));
  EXPECT_CALL(*render_a, OnEncodeCommands).Times(0);
  EXPECT_CALL(*blit_a, EncodeCommands).Times(0);
  EXPECT_CALL(*render_b, OnEncodeCommands).Times(0);

  // Submit posts to the raster thread, which needs a running isolate, so
  // this only checks that ending passes does not encode them on GLES.
  auto pass = fml::MakeRefCounted<RenderPass>();
  ASSERT_TRUE(pass->Begin(*command_buffer_));
  EXPECT_TRUE(Copy());
  EXPECT_TRUE(Copy());
  EXPECT_EQ(command_buffer_->CreateRenderPass(impeller::RenderTarget()),
            render_b);
  EXPECT_TRUE(pass->End());
}

TEST_F(FlutterGpuPassLifecycleTest, FailingToEncodeAnEndedPassFailsSubmit) {
  auto render_a = MakeRenderPass();
  EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
      .WillOnce(Return(render_a));
  EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(false));
  EXPECT_CALL(*command_queue_, Submit).Times(0);

  EXPECT_EQ(command_buffer_->CreateRenderPass(impeller::RenderTarget()),
            render_a);
  EXPECT_FALSE(Copy());

  std::vector<impeller::CommandBuffer::Status> statuses;
  EXPECT_FALSE(command_buffer_->Submit(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  ASSERT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

}  // namespace
}  // namespace flutter::gpu
