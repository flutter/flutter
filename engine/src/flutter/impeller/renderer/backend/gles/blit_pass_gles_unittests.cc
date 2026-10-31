// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::SetArgPointee;

namespace {

class ReactingWorker final : public ReactorGLES::Worker {
 public:
  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

std::shared_ptr<ContextGLES> CreateFakeGLESContext() {
  auto gl_procs = std::make_unique<ProcTableGLES>(kMockResolverGLES);
  auto shader_library = std::vector<std::shared_ptr<fml::Mapping>>{};
  return ContextGLES::Create(Flags{}, std::move(gl_procs), shader_library,
                             false);
}

}  // namespace

// Some drivers report an incomplete framebuffer for the texture a readback
// reads from (https://github.com/flutter/flutter/issues/195319). The copy then
// fails, and the process must keep running.
TEST(BlitPassGLESTest, ReadbackRefusedByTheDriverDoesNotAbort) {
  auto mock_gl_impl = std::make_unique<NiceMock<MockGLESImpl>>();
  auto& mock_gl_impl_ref = *mock_gl_impl;
  auto mock_gl = MockGLES::Init(std::move(mock_gl_impl));

  ON_CALL(mock_gl_impl_ref, GenTextures(1, _))
      .WillByDefault(SetArgPointee<1>(1));
  ON_CALL(mock_gl_impl_ref, GenFramebuffers(1, _))
      .WillByDefault(SetArgPointee<1>(2));
  EXPECT_CALL(mock_gl_impl_ref, CheckFramebufferStatus(GL_FRAMEBUFFER))
      .WillOnce(Return(GL_FRAMEBUFFER_UNSUPPORTED));
  EXPECT_CALL(mock_gl_impl_ref, ReadPixels(_, _, _, _, _, _, _)).Times(0);

  auto context = CreateFakeGLESContext();
  ASSERT_TRUE(context);
  context->AddReactorWorker(std::make_shared<ReactingWorker>());
  auto reactor = context->GetReactor();

  auto texture = std::make_shared<TextureGLES>(
      reactor, TextureDescriptor{.format = PixelFormat::kR8G8B8A8UNormInt,
                                 .size = {10, 10},
                                 .usage = TextureUsage::kRenderTarget});
  auto buffer =
      context->GetResourceAllocator()->CreateBuffer(DeviceBufferDescriptor{
          .storage_mode = StorageMode::kHostVisible, .size = 10 * 10 * 4});
  ASSERT_TRUE(buffer);
  ASSERT_TRUE(reactor->React());

  auto blit_pass = std::static_pointer_cast<Context>(context)
                       ->CreateCommandBuffer()
                       ->CreateBlitPass();
  ASSERT_TRUE(blit_pass);
  ASSERT_TRUE(blit_pass->AddCopy(texture, buffer));
  ASSERT_TRUE(blit_pass->EncodeCommands());

  // The refused framebuffer is reported as a validation error.
  ScopedValidationDisable disable_validation;
  EXPECT_TRUE(reactor->React());
}

}  // namespace testing
}  // namespace impeller
