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
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
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
      MockGLES::Init(std::move(mock_gl_impl), {{"GL_EXT_discard_framebuffer"}});

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

}  // namespace testing
}  // namespace impeller
