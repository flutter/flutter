// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/command_buffer.h"

#include <memory>
#include <vector>

#include "flutter/lib/gpu/device_buffer.h"
#include "flutter/lib/gpu/render_pass.h"
#include "flutter/lib/gpu/texture.h"
#include "fml/memory/ref_ptr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"
#include "third_party/abseil-cpp/absl/status/status.h"

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
  CommandBuffer command_buffer(context);

  std::vector<impeller::CommandBuffer::Status> statuses;

  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));

  EXPECT_CALL(*context, CreateCommandBuffer)
      .WillOnce(Return(impeller_command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _))
      .WillOnce(DoAll(
          [](const std::vector<std::shared_ptr<impeller::CommandBuffer>>&
                 buffers,
             const impeller::CommandQueue::CompletionCallback& callback) {
            EXPECT_EQ(buffers.size(), 1u);
            callback(impeller::CommandBuffer::Status::kCompleted);
          },
          Return(absl::OkStatus())));

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
  CommandBuffer command_buffer(context);

  EXPECT_CALL(*context, CreateCommandBuffer)
      .WillOnce(Return(impeller_command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _)).WillOnce(Return(absl::OkStatus()));

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
  CommandBuffer command_buffer(context);

  std::vector<impeller::CommandBuffer::Status> statuses;

  EXPECT_TRUE(command_buffer.AddCompletionCallback(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));

  EXPECT_CALL(*context, CreateCommandBuffer)
      .WillOnce(Return(impeller_command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _))
      .WillOnce(Return(absl::Status(absl::StatusCode::kInternal,
                                    "Command queue submit failed.")));

  EXPECT_FALSE(command_buffer.Submit());
  EXPECT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

// The pass lifecycle tests heap-allocate the command buffer, since it is
// ref-counted and asserts in debug builds when destroyed without a reference.
// With no replay queue, a pass is encoded on this thread as soon as it ends.
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
    ON_CALL(*context_, CreateCommandBuffer)
        .WillByDefault(Return(impeller_command_buffer_));
    command_buffer_ = fml::MakeRefCounted<CommandBuffer>(context_);

    impeller::TextureDescriptor texture_desc;
    texture_desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    texture_desc.size = impeller::ISize(4, 4);
    texture_desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    auto texture = std::make_shared<NiceMock<MockTexture>>(texture_desc);
    ON_CALL(*texture, IsValid).WillByDefault(Return(true));
    ON_CALL(*texture, GetSize).WillByDefault(Return(impeller::ISize(4, 4)));
    texture_ = fml::MakeRefCounted<Texture>(texture);
  }

  // Default actions can form a cycle through the context.
  void TearDown() override { ::testing::Mock::VerifyAndClear(context_.get()); }

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

  // A pass rendering into `texture_`.
  fml::RefPtr<RenderPass> MakePass() {
    impeller::ColorAttachment color;
    color.texture = texture_->GetTexture();
    color.load_action = impeller::LoadAction::kClear;
    color.store_action = impeller::StoreAction::kStore;
    auto pass = fml::MakeRefCounted<RenderPass>();
    pass->GetRenderTarget().SetColorAttachment(color, 0);
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
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(absl::OkStatus()));
  }

  EXPECT_TRUE(Copy());
  auto pass_a = MakePass();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  auto pass_b = MakePass();
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));
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
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(absl::OkStatus()));
  }

  auto pass = MakePass();
  ASSERT_TRUE(pass->Begin(*command_buffer_));
  pass->End();
  pass->End();
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
    // pass_b stays open until Submit, so its encoding comes after this.
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_b));
    EXPECT_CALL(*render_b, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(absl::OkStatus()));
  }

  auto pass_a = MakePass();
  auto pass_b = MakePass();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));
  // pass_b is still open, so this must not end it.
  pass_a->End();
  EXPECT_NE(pass_b->GetRecordingForTesting(), nullptr);
  EXPECT_TRUE(command_buffer_->Submit());
}

// OpenGL ES encoding hands the reactor raw pointers into the recordings, which
// only a submitted command buffer keeps alive.
TEST_F(FlutterGpuPassLifecycleTest, OpenGLESDefersEncodingToSubmit) {
  ON_CALL(*context_, GetBackendType)
      .WillByDefault(Return(impeller::Context::BackendType::kOpenGLES));
  auto render_a = MakeRenderPass();
  auto blit_a = MakeBlitPass();
  auto render_b = MakeRenderPass();
  {
    InSequence sequence;
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_a));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateBlitPass)
        .WillOnce(Return(blit_a));
    EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
        .WillOnce(Return(render_b));
    // Encoded in creation order, once submitted.
    EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*blit_a, EncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*render_b, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*command_queue_, Submit).WillOnce(Return(absl::OkStatus()));
  }

  auto pass_a = MakePass();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  EXPECT_TRUE(Copy());
  EXPECT_TRUE(Copy());
  auto pass_b = MakePass();
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));
  pass_b->End();
  EXPECT_TRUE(command_buffer_->Submit());
}

TEST_F(FlutterGpuPassLifecycleTest, FailingToEncodeAnEndedPassFailsSubmit) {
  auto render_a = MakeRenderPass();
  EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
      .WillOnce(Return(render_a));
  EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(false));
  EXPECT_CALL(*command_queue_, Submit).Times(0);

  auto pass = MakePass();
  ASSERT_TRUE(pass->Begin(*command_buffer_));
  pass->End();

  std::vector<impeller::CommandBuffer::Status> statuses;
  EXPECT_FALSE(command_buffer_->Submit(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  ASSERT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

// A pass already handed to the reactor points into the recordings, so they can
// only be recycled once the reactor has run it, which the queue guarantees.
TEST_F(FlutterGpuPassLifecycleTest,
       OpenGLESFailuresStillFlushPassesTheReactorHolds) {
  ON_CALL(*context_, GetBackendType)
      .WillByDefault(Return(impeller::Context::BackendType::kOpenGLES));
  auto render_a = MakeRenderPass();
  auto render_b = MakeRenderPass();
  EXPECT_CALL(*impeller_command_buffer_, OnCreateRenderPass)
      .WillOnce(Return(render_a))
      .WillOnce(Return(render_b));
  {
    InSequence sequence;
    EXPECT_CALL(*render_a, OnEncodeCommands).WillOnce(Return(true));
    EXPECT_CALL(*render_b, OnEncodeCommands).WillOnce(Return(false));
    EXPECT_CALL(*command_queue_, Submit(_, _))
        .WillOnce(DoAll(
            [](const std::vector<std::shared_ptr<impeller::CommandBuffer>>&,
               const impeller::CommandQueue::CompletionCallback& callback) {
              callback(impeller::CommandBuffer::Status::kCompleted);
            },
            Return(absl::OkStatus())));
  }

  auto pass_a = MakePass();
  ASSERT_TRUE(pass_a->Begin(*command_buffer_));
  auto pass_b = MakePass();
  ASSERT_TRUE(pass_b->Begin(*command_buffer_));

  std::vector<impeller::CommandBuffer::Status> statuses;
  EXPECT_FALSE(command_buffer_->Submit(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  ASSERT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

TEST_F(FlutterGpuPassLifecycleTest, CopiesMustFitTheSourceBuffer) {
  impeller::DeviceBufferDescriptor desc;
  desc.size = 64;
  auto buffer = fml::MakeRefCounted<DeviceBuffer>(
      std::make_shared<NiceMock<::impeller::testing::MockDeviceBuffer>>(desc));
  EXPECT_FALSE(command_buffer_->CopyBufferToTexture(
      *buffer, 32, 64, *texture_, impeller::IRect::MakeXYWH(0, 0, 1, 1), 0, 0));
  EXPECT_FALSE(command_buffer_->CopyBufferToTexture(
      *buffer, 128, 0, *texture_, impeller::IRect::MakeXYWH(0, 0, 1, 1), 0, 0));
}

// Backends report kError themselves for some failed submissions before
// returning failure. The completion must still run only once, since the Dart
// callback wrapper is consumed by its first run.
TEST(FlutterGpuCommandBufferTest, RunsCompletionOnceWhenTheBackendAlsoReports) {
  auto context = std::make_shared<MockImpellerContext>();
  auto impeller_command_buffer = std::make_shared<MockCommandBuffer>(context);
  auto command_queue = std::make_shared<MockCommandQueue>();
  CommandBuffer command_buffer(context);

  std::vector<impeller::CommandBuffer::Status> statuses;

  EXPECT_CALL(*context, CreateCommandBuffer)
      .WillOnce(Return(impeller_command_buffer));
  EXPECT_CALL(*context, GetCommandQueue).WillOnce(Return(command_queue));
  EXPECT_CALL(*command_queue, Submit(_, _))
      .WillOnce(DoAll(
          [](const std::vector<std::shared_ptr<impeller::CommandBuffer>>&
                 buffers,
             const impeller::CommandQueue::CompletionCallback& callback) {
            callback(impeller::CommandBuffer::Status::kError);
          },
          Return(absl::Status(absl::StatusCode::kInternal,
                              "Command queue submit failed."))));

  EXPECT_FALSE(command_buffer.Submit(
      [&statuses](impeller::CommandBuffer::Status status) {
        statuses.push_back(status);
      }));
  ASSERT_EQ(statuses.size(), 1u);
  EXPECT_EQ(statuses[0], impeller::CommandBuffer::Status::kError);
}

}  // namespace
}  // namespace flutter::gpu
