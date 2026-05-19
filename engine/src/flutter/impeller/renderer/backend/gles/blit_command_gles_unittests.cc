// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/blit_command_gles.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/texture_gles.h"

namespace impeller {
namespace testing {

using ::testing::_;
using ::testing::Return;

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

// This test makes sure we bind to GL_FRAMEBUFFER so that it's compatible for
// OpenGLES 2 and OpenGLES 3.
TEST(BlitCommandGLESTest, BlitCopyTextureToBufferCommandGLESBindsFramebuffer) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;

  EXPECT_CALL(mock_gles_impl_ref, GenFramebuffers(1, _))
      .WillOnce(::testing::SetArgPointee<1>(3));
  EXPECT_CALL(mock_gles_impl_ref, GenTextures(1, _))
      .WillOnce(::testing::SetArgPointee<1>(1));
  EXPECT_CALL(mock_gles_impl_ref, BindFramebuffer(GL_FRAMEBUFFER, 3)).Times(1);
  EXPECT_CALL(mock_gles_impl_ref, CheckFramebufferStatus(GL_FRAMEBUFFER))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE));
  EXPECT_CALL(mock_gles_impl_ref, ReadPixels(_, _, _, _, _, _, _)).Times(1);
  EXPECT_CALL(mock_gles_impl_ref, BindFramebuffer(GL_FRAMEBUFFER, 0)).Times(1);

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  // Create source texture.
  TextureDescriptor src_tex_desc;
  src_tex_desc.format = PixelFormat::kR8G8B8A8UNormInt;
  src_tex_desc.size = {10, 10};
  src_tex_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto source_texture = std::make_shared<TextureGLES>(reactor, src_tex_desc);
  // Avoids the flip which would crash.
  source_texture->SetCoordinateSystem(TextureCoordinateSystem::kUploadFromHost);

  // Create destination buffer.
  DeviceBufferDescriptor dest_buffer_desc;
  dest_buffer_desc.size = 10 * 10 * 4;
  dest_buffer_desc.storage_mode = StorageMode::kHostVisible;
  auto allocation = std::make_shared<Allocation>();
  ASSERT_TRUE(allocation->Truncate(Bytes(dest_buffer_desc.size)));
  auto dest_buffer =
      std::make_shared<DeviceBufferGLES>(dest_buffer_desc, reactor, allocation);

  ASSERT_TRUE(reactor->React());

  BlitCopyTextureToBufferCommandGLES command;
  command.source = source_texture;
  command.destination = dest_buffer;
  command.source_region =
      IRect::MakeSize(source_texture->GetTextureDescriptor().size);
  command.label = "TestBlit";

  EXPECT_TRUE(command.Encode(*reactor));

  source_texture.reset();
  dest_buffer.reset();

  ASSERT_TRUE(reactor->React());
}

}  // namespace testing
}  // namespace impeller
