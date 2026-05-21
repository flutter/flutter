// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <initializer_list>
#include <tuple>

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

std::shared_ptr<TextureGLES> CreateTexture(
    const std::shared_ptr<ReactorGLES>& reactor,
    PixelFormat format) {
  TextureDescriptor tex_desc;
  tex_desc.format = format;
  tex_desc.size = {10, 10};
  tex_desc.usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto texture = std::make_shared<TextureGLES>(reactor, tex_desc);
  // Avoids the flip which would crash.
  texture->SetCoordinateSystem(TextureCoordinateSystem::kUploadFromHost);
  return texture;
}

std::shared_ptr<DeviceBufferGLES> CreateBuffer(
    const std::shared_ptr<ReactorGLES>& reactor) {
  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = 10 * 10 * 4;
  buffer_desc.storage_mode = StorageMode::kHostVisible;
  auto allocation = std::make_unique<Allocation>();
  FML_CHECK(allocation->Truncate(Bytes(buffer_desc.size)));
  auto buffer = std::make_shared<DeviceBufferGLES>(buffer_desc, reactor,
                                                   std::move(allocation));
  return buffer;
}

BlitCopyBufferToTextureCommandGLES CreateCopyBufferToTextureCommand(
    const std::shared_ptr<DeviceBufferGLES>& source,
    const std::shared_ptr<TextureGLES>& dest) {
  BlitCopyBufferToTextureCommandGLES command;
  command.source = DeviceBuffer::AsBufferView(source);
  command.destination = dest;
  command.destination_region =
      IRect::MakeSize(dest->GetTextureDescriptor().size);
  command.mip_level = 0;
  command.slice = 0;
  command.label = "TestBlit";
  return command;
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

TEST(BlitCommandGLESTest, BlitCopyBufferToTextureCommandGLESRGBA) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  // Dest texture with RGBA format.
  std::shared_ptr<TextureGLES> dest_texture =
      CreateTexture(reactor, PixelFormat::kR8G8B8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> source_buffer = CreateBuffer(reactor);
  BlitCopyBufferToTextureCommandGLES command =
      CreateCopyBufferToTextureCommand(source_buffer, dest_texture);

  // Expect gl TexSubImage2D with GL_RGBA.
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, _, _, _, _, _, GL_RGBA, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

TEST(BlitCommandGLESTest, BlitCopyBufferToTextureCommandGLESBGRA) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;

  // Mock gl to support BGRA.
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(
      std::move(mock_gles_impl),
      std::vector<const char*>{"GL_EXT_texture_format_BGRA8888"});
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  // Dest texture with BGRA format.
  std::shared_ptr<TextureGLES> dest_texture =
      CreateTexture(reactor, PixelFormat::kB8G8R8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> source_buffer = CreateBuffer(reactor);
  BlitCopyBufferToTextureCommandGLES command =
      CreateCopyBufferToTextureCommand(source_buffer, dest_texture);

  // Expect gl TexSubImage2D with GL_BGRA_EXT.
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, _, _, _, _, _, GL_BGRA_EXT, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

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
      CreateTexture(reactor, PixelFormat::kR8G8B8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateBuffer(reactor);

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
      CreateTexture(reactor, PixelFormat::kR8G8B8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateBuffer(reactor);
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
      CreateTexture(reactor, PixelFormat::kB8G8R8A8UNormInt);
  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateBuffer(reactor);
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
  auto& mock_gles_impl_ref = *mock_gles_impl;

  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  std::shared_ptr<DeviceBufferGLES> dest_buffer = CreateBuffer(reactor);

  std::shared_ptr<TextureGLES> source_texture_D32FloatS8Uint =
      CreateTexture(reactor, PixelFormat::kD32FloatS8UInt);
  BlitCopyTextureToBufferCommandGLES command_for_D32FloatS8Uint =
      CreateCopyTextureToBufferCommand(source_texture_D32FloatS8Uint,
                                       dest_buffer);

  std::shared_ptr<TextureGLES> source_texture_R8G8UNormInt =
      CreateTexture(reactor, PixelFormat::kR8G8UNormInt);
  BlitCopyTextureToBufferCommandGLES command_for_R8G8UNormInt =
      CreateCopyTextureToBufferCommand(source_texture_R8G8UNormInt,
                                       dest_buffer);

  EXPECT_CALL(mock_gles_impl_ref, CheckFramebufferStatus(_)).Times(0);

  // GL does not support texture with an unsupported pixel format.
  EXPECT_FALSE(command_for_D32FloatS8Uint.Encode(*reactor));

  // GL does not support texture with another unsupported pixel format.
  EXPECT_FALSE(command_for_R8G8UNormInt.Encode(*reactor));
}

namespace {

std::shared_ptr<TextureGLES> CreateMipTexture(
    const std::shared_ptr<ReactorGLES>& reactor,
    PixelFormat format,
    ISize size,
    size_t mip_count,
    TextureType type = TextureType::kTexture2D) {
  TextureDescriptor tex_desc;
  tex_desc.format = format;
  tex_desc.size = size;
  tex_desc.mip_count = mip_count;
  tex_desc.type = type;
  tex_desc.usage = static_cast<TextureUsageMask>(TextureUsage::kRenderTarget);
  auto texture = std::make_shared<TextureGLES>(reactor, tex_desc);
  // Avoids the flip which would crash.
  texture->SetCoordinateSystem(TextureCoordinateSystem::kUploadFromHost);
  return texture;
}

std::shared_ptr<DeviceBufferGLES> CreateMipBuffer(
    const std::shared_ptr<ReactorGLES>& reactor,
    size_t size_bytes) {
  DeviceBufferDescriptor buffer_desc;
  buffer_desc.size = size_bytes;
  buffer_desc.storage_mode = StorageMode::kHostVisible;
  auto allocation = std::make_unique<Allocation>();
  FML_CHECK(allocation->Truncate(Bytes(buffer_desc.size)));
  return std::make_shared<DeviceBufferGLES>(buffer_desc, reactor,
                                            std::move(allocation));
}

}  // namespace

// An upload to mip 0 of a multi-mip texture should allocate ONLY level 0,
// preserving Impeller's snapshot path (which renders into level 0 and then
// uses glGenerateMipmap to fill the rest).
TEST(BlitCommandGLESTest,
     BlitCopyBufferToTextureCommandAllocatesOnlyTheRequestedBaseMip) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  auto dest = CreateMipTexture(reactor, PixelFormat::kR8G8B8A8UNormInt,
                               ISize{8, 8}, /*mip_count=*/3);
  auto source = CreateMipBuffer(reactor, 8 * 8 * 4);

  BlitCopyBufferToTextureCommandGLES command;
  command.source = DeviceBuffer::AsBufferView(source);
  command.destination = dest;
  command.destination_region = IRect::MakeSize(ISize{8, 8});
  command.mip_level = 0;
  command.slice = 0;
  command.label = "TestBlit";

  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 0, _, 8, 8, _, _, _, nullptr))
      .Times(1);
  // Higher mip levels must NOT be allocated by a level-0 upload.
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 1, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 2, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 0, _, _, 8, 8, _, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

// Regression test for the Flutter GPU multi-mip case: when the very first
// upload targets a non-zero mip, that level must be allocated by a
// glTexImage2D call before glTexSubImage2D, otherwise GLES raises
// GL_INVALID_OPERATION. Only the requested level should be allocated; lower
// or higher levels stay untouched until they're written themselves.
TEST(BlitCommandGLESTest,
     BlitCopyBufferToTextureCommandAllocatesNonZeroMipLevelOnFirstUpload) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  auto dest = CreateMipTexture(reactor, PixelFormat::kR8G8B8A8UNormInt,
                               ISize{8, 8}, /*mip_count=*/3);
  auto source = CreateMipBuffer(reactor, 4 * 4 * 4);

  BlitCopyBufferToTextureCommandGLES command;
  command.source = DeviceBuffer::AsBufferView(source);
  command.destination = dest;
  command.destination_region = IRect::MakeXYWH(0, 0, 4, 4);
  command.mip_level = 1;
  command.slice = 0;
  command.label = "TestBlit";

  // Only level 1 is allocated, and at the halved 4x4 size.
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 1, _, 4, 4, _, _, _, nullptr))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 0, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 2, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 1, _, _, 4, 4, _, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

// Three uploads to mips 0/1/2 of a multi-mip texture each allocate exactly
// their own level. This is the same total GL work as the eager approach, but
// split across the per-level encodes instead of batched on the first one,
// and is the path the new Flutter GPU `Texture.overwrite(mipLevel: ...)` API
// exercises.
TEST(BlitCommandGLESTest,
     BlitCopyBufferToTextureCommandAllocatesEachMipLevelOnFirstWrite) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  auto dest = CreateMipTexture(reactor, PixelFormat::kR8G8B8A8UNormInt,
                               ISize{8, 8}, /*mip_count=*/3);

  // Each level needs its own correctly-sized source buffer.
  auto source0 = CreateMipBuffer(reactor, 8 * 8 * 4);
  auto source1 = CreateMipBuffer(reactor, 4 * 4 * 4);
  auto source2 = CreateMipBuffer(reactor, 2 * 2 * 4);

  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 0, _, 8, 8, _, _, _, nullptr))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 1, _, 4, 4, _, _, _, nullptr))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 2, _, 2, 2, _, _, _, nullptr))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 0, _, _, 8, 8, _, _, _))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 1, _, _, 4, 4, _, _, _))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 2, _, _, 2, 2, _, _, _))
      .Times(1);

  for (const auto& [level, w, source] : std::initializer_list<
           std::tuple<uint32_t, int32_t, std::shared_ptr<DeviceBufferGLES>>>{
           {0, 8, source0}, {1, 4, source1}, {2, 2, source2}}) {
    BlitCopyBufferToTextureCommandGLES command;
    command.source = DeviceBuffer::AsBufferView(source);
    command.destination = dest;
    command.destination_region = IRect::MakeXYWH(0, 0, w, w);
    command.mip_level = level;
    command.slice = 0;
    command.label = "TestBlit";
    EXPECT_TRUE(command.Encode(*reactor));
  }
}

// A second upload to the same `(slice, mip_level)` must not re-issue
// glTexImage2D; the per-(slice, mip) bit in TextureGLES guards it.
TEST(BlitCommandGLESTest,
     BlitCopyBufferToTextureCommandDoesNotReallocateOnSubsequentUpload) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  auto dest = CreateMipTexture(reactor, PixelFormat::kR8G8B8A8UNormInt,
                               ISize{4, 4}, /*mip_count=*/2);
  auto source = CreateMipBuffer(reactor, 4 * 4 * 4);

  BlitCopyBufferToTextureCommandGLES command;
  command.source = DeviceBuffer::AsBufferView(source);
  command.destination = dest;
  command.destination_region = IRect::MakeSize(ISize{4, 4});
  command.mip_level = 0;
  command.slice = 0;
  command.label = "TestBlit";

  // Across both encodes, only the first allocates level 0.
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 0, _, 4, 4, _, _, _, nullptr))
      .Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, 1, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(GL_TEXTURE_2D, 0, _, _, _, _, _, _, _))
      .Times(2);

  EXPECT_TRUE(command.Encode(*reactor));
  EXPECT_TRUE(command.Encode(*reactor));
}

// For a cubemap, allocation must target the per-face cubemap target
// (`GL_TEXTURE_CUBE_MAP_POSITIVE_X + slice`) rather than `GL_TEXTURE_2D`,
// and only the requested `(face, mip_level)` is allocated by a single
// upload.
TEST(BlitCommandGLESTest,
     BlitCopyBufferToTextureCommandUsesCubemapFaceTargetForCubemap) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  auto& mock_gles_impl_ref = *mock_gles_impl;
  std::shared_ptr<MockGLES> mock_gl = MockGLES::Init(std::move(mock_gles_impl));
  auto reactor = std::make_shared<TestReactorGLES>();
  auto worker = std::make_shared<MockWorker>();
  reactor->AddWorker(worker);

  auto dest =
      CreateMipTexture(reactor, PixelFormat::kR8G8B8A8UNormInt, ISize{4, 4},
                       /*mip_count=*/2, TextureType::kTextureCube);
  auto source = CreateMipBuffer(reactor, 4 * 4 * 4);

  BlitCopyBufferToTextureCommandGLES command;
  command.source = DeviceBuffer::AsBufferView(source);
  command.destination = dest;
  command.destination_region = IRect::MakeSize(ISize{4, 4});
  command.mip_level = 0;
  command.slice = 2;  // GL_TEXTURE_CUBE_MAP_POSITIVE_Z
  command.label = "TestBlit";

  const GLenum face_target = GL_TEXTURE_CUBE_MAP_POSITIVE_X + 2;

  // The bind target is the cubemap parent, even though allocation/upload
  // calls use the per-face target.
  EXPECT_CALL(mock_gles_impl_ref, BindTexture(GL_TEXTURE_CUBE_MAP, _)).Times(1);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(face_target, 0, _, 4, 4, _, _, _, nullptr))
      .Times(1);
  // Higher mips for this face are not allocated by a level-0 upload.
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(face_target, 1, _, _, _, _, _, _, nullptr))
      .Times(0);
  // No other face is touched.
  EXPECT_CALL(mock_gles_impl_ref, TexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, _,
                                             _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexImage2D(GL_TEXTURE_2D, _, _, _, _, _, _, _, nullptr))
      .Times(0);
  EXPECT_CALL(mock_gles_impl_ref,
              TexSubImage2D(face_target, 0, _, _, 4, 4, _, _, _))
      .Times(1);

  EXPECT_TRUE(command.Encode(*reactor));
}

}  // namespace testing
}  // namespace impeller
