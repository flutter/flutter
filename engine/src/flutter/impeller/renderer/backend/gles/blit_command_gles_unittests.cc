// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/core/formats.h"
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

namespace {

std::shared_ptr<TextureGLES> CreateSourceTexture(
    std::shared_ptr<ReactorGLES> reactor,
    PixelFormat format) {
  TextureDescriptor src_tex_desc;
  src_tex_desc.format = format;
  src_tex_desc.size = {10, 10};
  src_tex_desc.usage =
      static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto source_texture = std::make_shared<TextureGLES>(reactor, src_tex_desc);
  // Avoids the flip which would crash.
  source_texture->SetCoordinateSystem(TextureCoordinateSystem::kUploadFromHost);
  return source_texture;
}

std::shared_ptr<DeviceBufferGLES> CreateDestBuffer(
    std::shared_ptr<ReactorGLES> reactor) {
  DeviceBufferDescriptor dest_buffer_desc;
  dest_buffer_desc.size = 10 * 10 * 4;
  dest_buffer_desc.storage_mode = StorageMode::kHostVisible;
  auto allocation = std::make_shared<Allocation>();
  FML_CHECK(allocation->Truncate(Bytes(dest_buffer_desc.size)));
  auto dest_buffer =
      std::make_shared<DeviceBufferGLES>(dest_buffer_desc, reactor, allocation);
  return dest_buffer;
}

BlitCopyTextureToBufferCommandGLES CreateCopyTextureToBufferCommand(
    const std::shared_ptr<TextureGLES>& source,
    const std::shared_ptr<DeviceBufferGLES>& dest) {
  BlitCopyTextureToBufferCommandGLES command;
  command.source = source;
  command.destination = dest;
  command.source_region = IRect::MakeSize(source->GetTextureDescriptor().size);
  command.label = "TestBlit";
  return command;
}

}  // namespace

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

  std::shared_ptr<TextureGLES> source_texture =
      CreateSourceTexture(reactor, PixelFormat::kR8G8B8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateDestBuffer(reactor);

  ASSERT_TRUE(reactor->React());

  BlitCopyTextureToBufferCommandGLES command =
      CreateCopyTextureToBufferCommand(source_texture, dest_buffer);

  EXPECT_TRUE(command.Encode(*reactor));

  source_texture.reset();
  dest_buffer.reset();

  ASSERT_TRUE(reactor->React());
}

TEST(BlitCommandGLESTest, BlitCopyTextureToBufferCommandGLESRGBA) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  // Source texture with RGBA format.
  std::shared_ptr<TextureGLES> source_texture =
      CreateSourceTexture(reactor, PixelFormat::kR8G8B8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateDestBuffer(reactor);
  BlitCopyTextureToBufferCommandGLES command =
      CreateCopyTextureToBufferCommand(source_texture, dest_buffer);

  EXPECT_CALL(mock_gles_impl_ref, CheckFramebufferStatus(_))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE));
  // Expect gl ReadPixels with GL_RGBA.
  EXPECT_CALL(mock_gles_impl_ref, ReadPixels(_, _, _, _, GL_RGBA, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

TEST(BlitCommandGLESTest, BlitCopyTextureToBufferCommandGLESBGRA) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;

  // Mock gl to support BGRA.
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(
      std::move(mock_gles_impl),
      std::vector<const char*>{"GL_EXT_texture_format_BGRA8888"});
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  // Source texture with BGRA format.
  std::shared_ptr<TextureGLES> source_texture =
      CreateSourceTexture(reactor, PixelFormat::kB8G8R8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateDestBuffer(reactor);
  BlitCopyTextureToBufferCommandGLES command =
      CreateCopyTextureToBufferCommand(source_texture, dest_buffer);

  EXPECT_CALL(mock_gles_impl_ref, CheckFramebufferStatus(_))
      .WillOnce(Return(GL_FRAMEBUFFER_COMPLETE));
  // Expect gl ReadPixels with GL_BGRA_EXT.
  EXPECT_CALL(mock_gles_impl_ref, ReadPixels(_, _, _, _, GL_BGRA_EXT, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

TEST(BlitCommandGLESTest,
     BlitCopyTextureToBufferCommandGLESUnsupportedPixelFormats) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateDestBuffer(reactor);

  std::shared_ptr<TextureGLES> source_texture_bgra =
      CreateSourceTexture(reactor, PixelFormat::kB8G8R8A8UNormInt);
  BlitCopyTextureToBufferCommandGLES command_for_bgra =
      CreateCopyTextureToBufferCommand(source_texture_bgra, dest_buffer);

  std::shared_ptr<TextureGLES> source_texture_rgba16 =
      CreateSourceTexture(reactor, PixelFormat::kR16G16B16A16Float);
  BlitCopyTextureToBufferCommandGLES command_for_rgba16 =
      CreateCopyTextureToBufferCommand(source_texture_rgba16, dest_buffer);

  // GL does not support texture with bgra pixel format.
  EXPECT_FALSE(command_for_bgra.Encode(*reactor));

  // GL does not support texture with another unsupported pixel format.
  EXPECT_FALSE(command_for_rgba16.Encode(*reactor));
}

}  // namespace testing
}  // namespace impeller
