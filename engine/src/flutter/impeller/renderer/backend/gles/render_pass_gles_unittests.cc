// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/device_buffer.h"
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
std::shared_ptr<ContextGLES> CreateFakeGLESContext(
    ProcTableGLES::Resolver resolver = kMockResolverGLES,
    Flags flags = Flags{}) {
  auto dummy_gl_procs = std::make_unique<ProcTableGLES>(std::move(resolver));
  auto dummy_shader_library = std::vector<std::shared_ptr<fml::Mapping>>{};
  return ContextGLES::Create(flags, std::move(dummy_gl_procs),
                             dummy_shader_library, false);
}

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

class RenderPassGLESCommandTest : public ::testing::Test {
 protected:
  // Builds a mock OpenGL ES context with a render pass and a minimal
  // pipeline. The [resolver] controls which GL entry points the backend can
  // see, which is how a caller selects the hardware or emulated instancing
  // path.
  static RenderPassGLESContext CreateRenderPassGLESContext(
      ProcTableGLES::Resolver resolver = kMockResolverGLES,
      Flags flags = Flags{}) {
    std::unique_ptr<NiceMock<MockGLESImpl>> mock_gl_impl =
        std::make_unique<NiceMock<MockGLESImpl>>();
    testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = *mock_gl_impl;
    std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gl_impl));

    std::shared_ptr<ContextGLES> context =
        CreateFakeGLESContext(std::move(resolver), flags);
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

  static std::shared_ptr<PipelineGLES> CreatePipelineWithDescriptor(
      const std::shared_ptr<ReactorGLES>& reactor,
      const PipelineDescriptor& desc,
      std::shared_ptr<UniqueHandleGLES> shared_handle = nullptr,
      GLint y_flip_uniform_location = -1) {
    if (!shared_handle) {
      HandleGLES pipeline_handle = reactor->CreateHandle(HandleType::kProgram);
      shared_handle =
          std::make_shared<UniqueHandleGLES>(reactor, pipeline_handle);
    }
    std::shared_ptr<PipelineGLES> pipeline = std::shared_ptr<PipelineGLES>(
        new PipelineGLES(reactor, std::weak_ptr<PipelineLibrary>(), desc,
                         std::move(shared_handle)));
    pipeline->buffer_bindings_ = std::make_unique<BufferBindingsGLES>();
    pipeline->y_flip_uniform_location_ = y_flip_uniform_location;
    return pipeline;
  }
};

TEST_F(RenderPassGLESCommandTest, ViewportCachedAcrossCommands) {
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
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 0, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

TEST_F(RenderPassGLESCommandTest,
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
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 0, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// Sibling regression guard for the bug fixed alongside this test on the
// Vulkan backend. The GLES backend has always honored the X offset; this
// asserts that explicitly so a future change can't silently regress it.
TEST_F(RenderPassGLESCommandTest, ViewportWithNonZeroXOffsetReachesGL) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(25, 0, 50, 100), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref, Viewport(_, _, _, _)).Times(0);
  EXPECT_CALL(mock_gl_impl_ref, Viewport(25, 0, 50, 100)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// When the driver exposes the hardware instancing entry points, a
// non-indexed instanced command issues a single glDrawArraysInstanced call
// that carries the instance count.
TEST_F(RenderPassGLESCommandTest, HardwareInstancedArrayDraw) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetInstanceCount(4);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref,
              DrawArraysInstanced(/*mode=*/_, /*first=*/0, /*count=*/3,
                                  /*instancecount=*/4))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DrawArrays(_, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// The indexed counterpart: a hardware instanced indexed command issues a
// single glDrawElementsInstanced call.
TEST_F(RenderPassGLESCommandTest, HardwareInstancedElementsDraw) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  DeviceBufferDescriptor index_desc;
  index_desc.size = 6 * sizeof(uint16_t);
  index_desc.storage_mode = StorageMode::kHostVisible;
  auto index_buffer = std::static_pointer_cast<Context>(ctx.context)
                          ->GetResourceAllocator()
                          ->CreateBuffer(index_desc);
  ASSERT_TRUE(index_buffer);

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(6);
  ASSERT_TRUE(render_pass->SetIndexBuffer(
      DeviceBuffer::AsBufferView(index_buffer), IndexType::k16bit));
  render_pass->SetInstanceCount(4);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref,
              DrawElementsInstanced(/*mode=*/_, /*count=*/6, /*type=*/_,
                                    /*indices=*/_, /*instancecount=*/4))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DrawElements(_, _, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// When the hardware instancing entry points are missing, a non-indexed
// instanced command is emulated by repeating the plain draw once per
// instance.
TEST_F(RenderPassGLESCommandTest, EmulatedInstancedArrayDraw) {
  auto ctx = CreateRenderPassGLESContext(kMockResolverGLESWithoutInstancing);
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetInstanceCount(4);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref,
              DrawArrays(/*mode=*/_, /*first=*/0, /*count=*/3))
      .Times(4);
  EXPECT_CALL(mock_gl_impl_ref, DrawArraysInstanced(_, _, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// The indexed counterpart of the emulation path: the plain indexed draw is
// repeated once per instance.
TEST_F(RenderPassGLESCommandTest, EmulatedInstancedElementsDraw) {
  auto ctx = CreateRenderPassGLESContext(kMockResolverGLESWithoutInstancing);
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  DeviceBufferDescriptor index_desc;
  index_desc.size = 6 * sizeof(uint16_t);
  index_desc.storage_mode = StorageMode::kHostVisible;
  auto index_buffer = std::static_pointer_cast<Context>(ctx.context)
                          ->GetResourceAllocator()
                          ->CreateBuffer(index_desc);
  ASSERT_TRUE(index_buffer);

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(6);
  ASSERT_TRUE(render_pass->SetIndexBuffer(
      DeviceBuffer::AsBufferView(index_buffer), IndexType::k16bit));
  render_pass->SetInstanceCount(4);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref,
              DrawElements(/*mode=*/_, /*count=*/6, /*type=*/_, /*indices=*/_))
      .Times(4);
  EXPECT_CALL(mock_gl_impl_ref, DrawElementsInstanced(_, _, _, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// Regression guard: a command with no instance count set draws a single
// instance through the plain, non-instanced entry point.
TEST_F(RenderPassGLESCommandTest, NonInstancedDrawIssuesSingleDrawArrays) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref,
              DrawArrays(/*mode=*/_, /*first=*/0, /*count=*/3))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DrawArraysInstanced(_, _, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// A command with an explicit instance count of zero draws nothing, matching
// the Metal and Vulkan backends.
TEST_F(RenderPassGLESCommandTest, ZeroInstanceCountIssuesNoDraw) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetInstanceCount(0);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref, DrawArrays(_, _, _)).Times(0);
  EXPECT_CALL(mock_gl_impl_ref, DrawArraysInstanced(_, _, _, _)).Times(0);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

namespace {
// Builds a render pass targeting a wrapped (embedder supplied) framebuffer,
// which is the case whose orientation depends on the default framebuffer's
// origin.
std::shared_ptr<RenderPass> CreateWrappedFBORenderPass(
    const std::shared_ptr<ContextGLES>& context,
    const std::shared_ptr<ReactorGLES>& reactor,
    const std::shared_ptr<CommandBuffer>& command_buffer) {
  TextureDescriptor tex_desc;
  tex_desc.size = {100, 100};
  tex_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  // A framebuffer that gets presented is never transient, and attaching a
  // transient texture with a kStore store action fails validation.
  tex_desc.storage_mode = StorageMode::kDevicePrivate;

  RenderTarget target;
  ColorAttachment color0;
  color0.texture = TextureGLES::WrapFBO(reactor, tex_desc, /*fbo=*/1u);
  color0.store_action = StoreAction::kStore;
  color0.load_action = LoadAction::kClear;
  target.SetColorAttachment(color0, 0);

  return command_buffer->CreateRenderPass(target);
}
}  // namespace

// By default the default framebuffer uses OpenGL's bottom-left origin, so a
// wrapped FBO keeps the top-down to bottom-up viewport conversion.
TEST_F(RenderPassGLESCommandTest, WrappedFBOConvertsViewportByDefault) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  std::shared_ptr<RenderPass> render_pass =
      CreateWrappedFBORenderPass(ctx.context, reactor, ctx.command_buffer);

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(0, 0, 50, 50), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  // flip_y = false, so y is converted: 100 - 0 - 50 == 50.
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 50, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

TEST_F(RenderPassGLESCommandTest,
       DeduplicatesPipelineAndScissorStateAcrossCommands) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  for (int i = 0; i < 3; ++i) {
    render_pass->SetPipeline(PipelineRef(pipeline));
    render_pass->SetScissor(IRect32::MakeXYWH(10, 10, 40, 40));
    render_pass->SetElementCount(3);
    render_pass->SetIndexBuffer({}, IndexType::kNone);
    EXPECT_TRUE(render_pass->Draw().ok());
  }

  // Draw 4: a command without an explicit SetScissor (command.scissor ==
  // std::nullopt) inherits the active scissor rect from the previous command
  // (see flutter/engine#56494) and does not disable GL_SCISSOR_TEST.
  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  // Draw 5: restoring the scissor to the full render target updates glScissor
  // without re-calling glEnable(GL_SCISSOR_TEST).
  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetScissor(IRect32::MakeXYWH(0, 0, 100, 100));
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  // Five draws: identical pipeline binds program once; first 3 scissored draws
  // enable/set scissor (10, 10, 40, 40) once; Draw 4 preserves the active
  // scissor; Draw 5 updates glScissor to (0, 0, 100, 100) without re-enabling
  // GL_SCISSOR_TEST; ResetGLState defaults (ColorMask,
  // Disable(GL_SCISSOR_TEST/GL_BLEND/GL_DEPTH_TEST/GL_STENCIL_TEST)) are not
  // re-emitted per command.
  EXPECT_CALL(mock_gl_impl_ref, DrawArrays(_, 0, 3)).Times(5);
  EXPECT_CALL(mock_gl_impl_ref, UseProgram(_)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Enable(GL_SCISSOR_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Scissor(10, 10, 40, 40)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Scissor(0, 0, 100, 100)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, ColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_SCISSOR_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_DEPTH_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_STENCIL_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_CULL_FACE)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_BLEND)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Disable(GL_DITHER)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

// When the embedder's default framebuffer has a top-left origin the whole
// pipeline is stored top-down, so a wrapped FBO flips in the vertex shader and
// passes the viewport through unconverted.
TEST_F(RenderPassGLESCommandTest, WrappedFBOPassesViewportThroughWhenTopLeft) {
  Flags flags;
  flags.top_left_default_framebuffer_origin = true;

  auto ctx = CreateRenderPassGLESContext(kMockResolverGLES, flags);
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<PipelineGLES>& pipeline = ctx.pipeline;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  std::shared_ptr<RenderPass> render_pass =
      CreateWrappedFBORenderPass(ctx.context, reactor, ctx.command_buffer);

  render_pass->SetPipeline(PipelineRef(pipeline));
  render_pass->SetElementCount(1);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  render_pass->SetViewport(
      Viewport{Rect::MakeXYWH(0, 0, 50, 50), DepthRange{0.0f, 1.0f}});
  EXPECT_TRUE(render_pass->Draw().ok());

  // flip_y = true, so y is used as-is.
  EXPECT_CALL(mock_gl_impl_ref, Viewport(0, 0, 50, 50)).Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

TEST_F(RenderPassGLESCommandTest,
       DeduplicatesEnabledBlendStencilDepthAndSharedProgramAcrossVariants) {
  auto ctx = CreateRenderPassGLESContext();
  testing::NiceMock<MockGLESImpl>& mock_gl_impl_ref = ctx.mock_gl_impl_ref;
  std::shared_ptr<RenderPass>& render_pass = ctx.render_pass;
  std::shared_ptr<ReactorGLES>& reactor = ctx.reactor;

  PipelineDescriptor desc_a;
  ColorAttachmentDescriptor color0;
  color0.format = PixelFormat::kR8G8B8A8UNormInt;
  color0.blending_enabled = true;
  color0.src_color_blend_factor = BlendFactor::kOne;
  color0.dst_color_blend_factor = BlendFactor::kOneMinusSourceAlpha;
  color0.color_blend_op = BlendOperation::kAdd;
  color0.src_alpha_blend_factor = BlendFactor::kOne;
  color0.dst_alpha_blend_factor = BlendFactor::kOneMinusSourceAlpha;
  color0.alpha_blend_op = BlendOperation::kAdd;
  desc_a.SetColorAttachmentDescriptor(0, color0);

  DepthAttachmentDescriptor depth_desc;
  depth_desc.depth_compare = CompareFunction::kLess;
  depth_desc.depth_write_enabled = false;
  desc_a.SetDepthStencilAttachmentDescriptor(depth_desc);

  StencilAttachmentDescriptor stencil_desc;
  stencil_desc.stencil_compare = CompareFunction::kEqual;
  stencil_desc.depth_stencil_pass = StencilOperation::kIncrementClamp;
  stencil_desc.write_mask = 0x0F;
  desc_a.SetStencilAttachmentDescriptors(stencil_desc);

  auto pipeline_a =
      CreatePipelineWithDescriptor(reactor, desc_a, /*shared_handle=*/nullptr,
                                   /*y_flip_uniform_location=*/7);

  // Create a second PipelineGLES instance that shares the same compiled program
  // handle (UniqueHandleGLES) with identical blend/depth/stencil descriptors.
  auto pipeline_b = CreatePipelineWithDescriptor(reactor, desc_a,
                                                 pipeline_a->GetSharedHandle(),
                                                 /*y_flip_uniform_location=*/7);

  // Draw 1 & Draw 2: two distinct PipelineGLES instances sharing a program
  // handle and stencil_reference = 1.
  render_pass->SetPipeline(PipelineRef(pipeline_a));
  render_pass->SetStencilReference(1);
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  render_pass->SetPipeline(PipelineRef(pipeline_b));
  render_pass->SetStencilReference(1);
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  // Draw 3: same pipeline_b, but stencil_reference changes to 2. Only
  // StencilFuncSeparate should re-fire (not StencilOpSeparate or
  // StencilMaskSeparate).
  render_pass->SetPipeline(PipelineRef(pipeline_b));
  render_pass->SetStencilReference(2);
  render_pass->SetElementCount(3);
  render_pass->SetIndexBuffer({}, IndexType::kNone);
  EXPECT_TRUE(render_pass->Draw().ok());

  EXPECT_CALL(mock_gl_impl_ref, DrawArrays(_, 0, 3)).Times(3);

  // Shared program handle must bind once and upload y_flip uniform once.
  EXPECT_CALL(mock_gl_impl_ref, UseProgram(_)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, Uniform1fv(7, 1, _)).Times(1);

  // Blend enabled once and configured once across all 3 draws.
  EXPECT_CALL(mock_gl_impl_ref, Enable(GL_BLEND)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref,
              BlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE,
                                GL_ONE_MINUS_SRC_ALPHA))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, BlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD))
      .Times(1);

  // Depth enabled once, DepthFunc(GL_LESS) once, DepthMask(GL_FALSE) once (plus
  // DepthMask(GL_TRUE) once in ResetGLState).
  EXPECT_CALL(mock_gl_impl_ref, Enable(GL_DEPTH_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DepthFunc(GL_LESS)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DepthMask(GL_TRUE)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref, DepthMask(GL_FALSE)).Times(1);

  // Stencil enabled once; StencilOpSeparate and StencilMaskSeparate called once
  // for GL_FRONT_AND_BACK across all 3 draws (plus GL_FRONT/GL_BACK defaults in
  // ResetGLState); StencilFuncSeparate called once for ref=1 and once for
  // ref=2.
  EXPECT_CALL(mock_gl_impl_ref, Enable(GL_STENCIL_TEST)).Times(1);
  EXPECT_CALL(mock_gl_impl_ref,
              StencilOpSeparate(GL_FRONT_AND_BACK, GL_KEEP, GL_KEEP, GL_INCR))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, StencilMaskSeparate(GL_FRONT, 0xFFFFFFFF))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, StencilMaskSeparate(GL_BACK, 0xFFFFFFFF))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref, StencilMaskSeparate(GL_FRONT_AND_BACK, 0x0F))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref,
              StencilFuncSeparate(GL_FRONT_AND_BACK, GL_EQUAL, 1, _))
      .Times(1);
  EXPECT_CALL(mock_gl_impl_ref,
              StencilFuncSeparate(GL_FRONT_AND_BACK, GL_EQUAL, 2, _))
      .Times(1);

  EXPECT_TRUE(render_pass->EncodeCommands());
  EXPECT_TRUE(reactor->React());
}

}  // namespace testing
}  // namespace impeller
