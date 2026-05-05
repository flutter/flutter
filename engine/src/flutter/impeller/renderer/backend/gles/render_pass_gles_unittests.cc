// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/command_buffer_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/backend/gles/unique_handle_gles.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::Args;
using ::testing::ElementsAreArray;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::TestWithParam;

class TestReactorGLES : public ReactorGLES {
 public:
  TestReactorGLES()
      : ReactorGLES(std::make_unique<ProcTableGLES>(kMockResolverGLES)) {}

  ~TestReactorGLES() = default;
};

class MockWorker final : public ReactorGLES::Worker {
 public:
  MockWorker() = default;

  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

struct DiscardFrameBufferParams {
  GLuint frame_buffer_id;
  std::array<GLenum, 3> expected_attachments;
};

class RenderPassGLESWithDiscardFrameBufferExtTest
    : public TestWithParam<DiscardFrameBufferParams> {};

namespace {
std::shared_ptr<ContextGLES> CreateFakeGLESContext() {
  auto dummy_gl_procs = std::make_unique<ProcTableGLES>(kMockResolverGLES);
  auto dummy_shader_library = std::vector<std::shared_ptr<fml::Mapping>>{};
  auto flags = Flags{};
  return ContextGLES::Create(flags, std::move(dummy_gl_procs),
                             dummy_shader_library, false);
}
}  // namespace

TEST_P(RenderPassGLESWithDiscardFrameBufferExtTest, DiscardFramebufferExt) {
  auto mock_gl_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  auto& mock_gl_impl_ref = *mock_gl_impl;
  auto mock_gl =
      MockGLES::Init(std::move(mock_gl_impl), {{"GL_EXT_discard_framebuffer"}},
                     "OpenGL ES 2.0");

  auto context = CreateFakeGLESContext();
  auto dummy_worker = std::make_shared<MockWorker>();
  context->AddReactorWorker(dummy_worker);
  auto reactor = context->GetReactor();

  const auto command_buffer =
      std::static_pointer_cast<Context>(context)->CreateCommandBuffer();
  auto render_target = RenderTarget{};
  const auto description = TextureDescriptor{
      .format = PixelFormat::kR8G8B8A8UNormInt, .size = {10, 10}};

  const auto& test_params = GetParam();
  auto framebuffer_texture =
      TextureGLES::WrapFBO(reactor, description, test_params.frame_buffer_id);

  auto color_attachment = ColorAttachment{Attachment{
      .texture = framebuffer_texture, .store_action = StoreAction::kDontCare}};
  render_target.SetColorAttachment(color_attachment, 0);
  const auto render_pass = command_buffer->CreateRenderPass(render_target);

  EXPECT_CALL(mock_gl_impl_ref, GetIntegerv(GL_FRAMEBUFFER_BINDING, _))
      .WillOnce(SetArgPointee<1>(test_params.frame_buffer_id));

  EXPECT_CALL(mock_gl_impl_ref, DiscardFramebufferEXT(GL_FRAMEBUFFER, _, _))
      .With(Args<2, 1>(ElementsAreArray(test_params.expected_attachments)))
      .Times(1);
  ASSERT_TRUE(render_pass->EncodeCommands());
  ASSERT_TRUE(reactor->React());
}

INSTANTIATE_TEST_SUITE_P(
    FrameBufferObject,
    RenderPassGLESWithDiscardFrameBufferExtTest,
    ::testing::ValuesIn(std::vector<DiscardFrameBufferParams>{
        {.frame_buffer_id = 0,
         .expected_attachments = {GL_COLOR_EXT, GL_DEPTH_EXT, GL_STENCIL_EXT}},
        {.frame_buffer_id = 1,
         .expected_attachments = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT,
                                  GL_STENCIL_ATTACHMENT}}}),
    [](const ::testing::TestParamInfo<DiscardFrameBufferParams>& info) {
      return (info.param.frame_buffer_id == 0) ? "Default" : "NonDefault";
    });

TEST_P(RenderPassGLESWithDiscardFrameBufferExtTest, InvalidateFramebuffer) {
  auto mock_gl_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  auto& mock_gl_impl_ref = *mock_gl_impl;
  auto mock_gl =
      MockGLES::Init(std::move(mock_gl_impl), std::nullopt, "OpenGL ES 3.0");

  auto context = CreateFakeGLESContext();
  auto dummy_worker = std::make_shared<MockWorker>();
  context->AddReactorWorker(dummy_worker);
  auto reactor = context->GetReactor();

  const auto command_buffer =
      std::static_pointer_cast<Context>(context)->CreateCommandBuffer();
  auto render_target = RenderTarget{};
  const auto description = TextureDescriptor{
      .format = PixelFormat::kR8G8B8A8UNormInt, .size = {10, 10}};

  const auto& test_params = GetParam();
  auto framebuffer_texture =
      TextureGLES::WrapFBO(reactor, description, test_params.frame_buffer_id);

  auto color_attachment = ColorAttachment{Attachment{
      .texture = framebuffer_texture, .store_action = StoreAction::kDontCare}};
  render_target.SetColorAttachment(color_attachment, 0);
  const auto render_pass = command_buffer->CreateRenderPass(render_target);

  EXPECT_CALL(mock_gl_impl_ref, GetIntegerv(GL_FRAMEBUFFER_BINDING, _))
      .WillOnce(SetArgPointee<1>(test_params.frame_buffer_id));

  // InvalidateFramebuffer should be called instead of DiscardFramebufferEXT
  EXPECT_CALL(mock_gl_impl_ref, InvalidateFramebuffer(GL_FRAMEBUFFER, _, _))
      .With(Args<2, 1>(ElementsAreArray(test_params.expected_attachments)))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DiscardFramebufferEXT(GL_FRAMEBUFFER, _, _))
      .Times(0);

  ASSERT_TRUE(render_pass->EncodeCommands());
  ASSERT_TRUE(reactor->React());
}

TEST(RenderPassGLESTest, ResolvingMultisampleTextureCachesResolveFBO) {
  auto mock_gl_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  auto& mock_gl_impl_ref = *mock_gl_impl;
  // Make sure implicit resolving isn't supported so we go down explicit path.
  auto mock_gl =
      MockGLES::Init(std::move(mock_gl_impl), std::nullopt, "OpenGL ES 3.0");

  auto context = CreateFakeGLESContext();
  auto dummy_worker = std::make_shared<MockWorker>();
  context->AddReactorWorker(dummy_worker);
  auto reactor = context->GetReactor();

  const auto command_buffer =
      std::static_pointer_cast<Context>(context)->CreateCommandBuffer();

  const auto msaa_desc =
      TextureDescriptor{.type = TextureType::kTexture2DMultisample,
                        .format = PixelFormat::kR8G8B8A8UNormInt,
                        .size = {10, 10},
                        .usage = TextureUsage::kRenderTarget,
                        .sample_count = SampleCount::kCount4};
  const auto resolve_desc =
      TextureDescriptor{.storage_mode = StorageMode::kDevicePrivate,
                        .type = TextureType::kTexture2D,
                        .format = PixelFormat::kR8G8B8A8UNormInt,
                        .size = {10, 10},
                        .usage = TextureUsage::kRenderTarget,
                        .sample_count = SampleCount::kCount1};

  auto msaa_tex = std::make_shared<TextureGLES>(reactor, msaa_desc);
  auto resolve_tex = std::make_shared<TextureGLES>(reactor, resolve_desc);

  auto render_target = RenderTarget{};
  auto color_attachment = ColorAttachment{Attachment{
      .texture = msaa_tex,
      .resolve_texture = resolve_tex,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kMultisampleResolve,
  }};
  color_attachment.clear_color = Color::Black();
  render_target.SetColorAttachment(color_attachment, 0);

  EXPECT_CALL(mock_gl_impl_ref, CheckFramebufferStatus(_))
      .WillRepeatedly(Return(GL_FRAMEBUFFER_COMPLETE));

  // Expect GenFramebuffers is called exactly once for the offscreen FBO,
  // and exactly once for the resolve FBO over two passes.
  EXPECT_CALL(mock_gl_impl_ref, GenFramebuffers(_, _)).Times(2);

  {
    const auto render_pass = command_buffer->CreateRenderPass(render_target);
    ASSERT_TRUE(render_pass->EncodeCommands());
    ASSERT_TRUE(reactor->React());
  }
  {
    const auto render_pass2 = command_buffer->CreateRenderPass(render_target);
    ASSERT_TRUE(render_pass2->EncodeCommands());
    ASSERT_TRUE(reactor->React());
  }
}

class RenderPassGLESViewportTest : public ::testing::Test {
 protected:
  struct RenderPassGLESContext {
    std::shared_ptr<MockGLES> mock_gl;
    testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref;
    std::shared_ptr<ContextGLES> context;
    std::shared_ptr<MockWorker> dummy_worker;
    std::shared_ptr<ReactorGLES> reactor;
    std::shared_ptr<CommandBuffer> command_buffer;
    std::shared_ptr<RenderPass> render_pass;
    std::shared_ptr<PipelineGLES> pipeline;
  };

  RenderPassGLESContext CreateRenderPassGLESContext() {
    std::unique_ptr<NiceMock<MockGLESImpl>> mock_gl_impl =
        std::make_unique<NiceMock<MockGLESImpl>>();
    testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = *mock_gl_impl;
    std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gl_impl));

    std::shared_ptr<ContextGLES> context = CreateFakeGLESContext();
    std::shared_ptr<MockWorker> dummy_worker = std::make_shared<MockWorker>();
    context->AddReactorWorker(dummy_worker);
    std::shared_ptr<ReactorGLES> reactor = context->GetReactor();

    TextureDescriptor tex_desc;
    tex_desc.size = {100, 100};
    tex_desc.format = PixelFormat::kR8G8B8A8UNormInt;
    auto texture = std::make_shared<TextureGLES>(reactor, tex_desc, false);

    RenderTarget target;
    ColorAttachment color0;
    color0.texture = texture;
    color0.store_action = StoreAction::kDontCare;
    color0.load_action = LoadAction::kClear;
    target.SetColorAttachment(color0, 0);

    std::shared_ptr<CommandBuffer> command_buffer =
        std::static_pointer_cast<Context>(context)->CreateCommandBuffer();
    std::shared_ptr<RenderPass> render_pass =
        command_buffer->CreateRenderPass(target);

    EXPECT_CALL(mock_gl_impl_ref, CheckFramebufferStatus(_))
        .WillRepeatedly(Return(GL_FRAMEBUFFER_COMPLETE));

    PipelineDescriptor desc;
    ColorAttachmentDescriptor color0_desc;
    color0_desc.format = PixelFormat::kR8G8B8A8UNormInt;
    desc.SetColorAttachmentDescriptor(0, color0_desc);

    HandleGLES pipeline_handle = reactor->CreateHandle(HandleType::kProgram);
    std::shared_ptr<PipelineGLES> pipeline =
        std::shared_ptr<PipelineGLES>(new PipelineGLES(
            reactor, std::weak_ptr<PipelineLibrary>(), desc,
            std::make_shared<UniqueHandleGLES>(reactor, pipeline_handle)));
    pipeline->buffer_bindings_ = std::make_unique<BufferBindingsGLES>();

    return {std::move(mock_gl),     mock_gl_impl_ref,
            std::move(context),     std::move(dummy_worker),
            std::move(reactor),     std::move(command_buffer),
            std::move(render_pass), std::move(pipeline)};
  }
};

TEST_F(RenderPassGLESViewportTest, ViewportCachedAcrossCommands) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(0, 0, 50, 50), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(0, 0, 50, 50), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  // Viewport should only be called twice. Once for the fallback, once for the
  // first override. We set a catch-all to 0 to ensure no other calls occur.
  EXPECT_CALL(mock_gl_impl_ref, Viewport(_, _, _, _)).Times(0);
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 0, 100, 100)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 50, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

TEST_F(RenderPassGLESViewportTest,
       CommandsWithoutViewportGetRenderPassViewport) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(0, 0, 50, 50), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref, Viewport(_, _, _, _)).Times(0);
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 0, 100, 100)).Times(2);
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 50, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

}  // namespace testing
}  // namespace impeller
