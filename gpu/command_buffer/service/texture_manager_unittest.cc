// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/texture_manager.h"

#include <utility>

#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/error_state_mock.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/framebuffer_manager.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder_mock.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_image_stub.h"
#include "ui/gl/gl_mock.h"

using ::testing::AtLeast;
using ::testing::Pointee;
using ::testing::Return;
using ::testing::SetArgumentPointee;
using ::testing::StrictMock;
using ::testing::_;

namespace gpu {
namespace gles2 {

class TextureTestHelper {
 public:
  static bool IsNPOT(const Texture* texture) {
    return texture->npot();
  }
  static bool IsTextureComplete(const Texture* texture) {
    return texture->texture_complete();
  }
  static bool IsCubeComplete(const Texture* texture) {
    return texture->cube_complete();
  }
};

class TextureManagerTest : public GpuServiceTest {
 public:
  static const GLint kMaxTextureSize = 16;
  static const GLint kMaxCubeMapTextureSize = 8;
  static const GLint kMaxRectangleTextureSize = 16;
  static const GLint kMaxExternalTextureSize = 16;
  static const GLint kMax2dLevels = 5;
  static const GLint kMaxCubeMapLevels = 4;
  static const GLint kMaxExternalLevels = 1;
  static const bool kUseDefaultTextures = false;

  TextureManagerTest() : feature_info_(new FeatureInfo()) {}

  ~TextureManagerTest() override {}

 protected:
  void SetUp() override {
    GpuServiceTest::SetUp();
    manager_.reset(new TextureManager(NULL,
                                      feature_info_.get(),
                                      kMaxTextureSize,
                                      kMaxCubeMapTextureSize,
                                      kMaxRectangleTextureSize,
                                      kUseDefaultTextures));
    TestHelper::SetupTextureManagerInitExpectations(
        gl_.get(), "", kUseDefaultTextures);
    manager_->Initialize();
    error_state_.reset(new ::testing::StrictMock<gles2::MockErrorState>());
  }

  void TearDown() override {
    manager_->Destroy(false);
    manager_.reset();
    GpuServiceTest::TearDown();
  }

  void SetParameter(
      TextureRef* texture_ref, GLenum pname, GLint value, GLenum error) {
    TestHelper::SetTexParameteriWithExpectations(
        gl_.get(), error_state_.get(), manager_.get(),
        texture_ref, pname, value, error);
  }

  scoped_refptr<FeatureInfo> feature_info_;
  scoped_ptr<TextureManager> manager_;
  scoped_ptr<MockErrorState> error_state_;
};

// GCC requires these declarations, but MSVC requires they not be present
#ifndef COMPILER_MSVC
const GLint TextureManagerTest::kMaxTextureSize;
const GLint TextureManagerTest::kMaxCubeMapTextureSize;
const GLint TextureManagerTest::kMaxRectangleTextureSize;
const GLint TextureManagerTest::kMaxExternalTextureSize;
const GLint TextureManagerTest::kMax2dLevels;
const GLint TextureManagerTest::kMaxCubeMapLevels;
const GLint TextureManagerTest::kMaxExternalLevels;
#endif

TEST_F(TextureManagerTest, Basic) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLuint kClient2Id = 2;
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  // Check we can create texture.
  manager_->CreateTexture(kClient1Id, kService1Id);
  // Check texture got created.
  scoped_refptr<TextureRef> texture = manager_->GetTexture(kClient1Id);
  ASSERT_TRUE(texture.get() != NULL);
  EXPECT_EQ(kService1Id, texture->service_id());
  EXPECT_EQ(kClient1Id, texture->client_id());
  EXPECT_EQ(texture->texture(), manager_->GetTextureForServiceId(
      texture->service_id()));
  // Check we get nothing for a non-existent texture.
  EXPECT_TRUE(manager_->GetTexture(kClient2Id) == NULL);
  // Check trying to a remove non-existent textures does not crash.
  manager_->RemoveTexture(kClient2Id);
  // Check that it gets deleted when the last reference is released.
  EXPECT_CALL(*gl_, DeleteTextures(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  // Check we can't get the texture after we remove it.
  manager_->RemoveTexture(kClient1Id);
  EXPECT_TRUE(manager_->GetTexture(kClient1Id) == NULL);
  EXPECT_EQ(0u, texture->client_id());
}

TEST_F(TextureManagerTest, SetParameter) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  // Check we can create texture.
  manager_->CreateTexture(kClient1Id, kService1Id);
  // Check texture got created.
  TextureRef* texture_ref = manager_->GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();
  manager_->SetTarget(texture_ref, GL_TEXTURE_2D);
  SetParameter(texture_ref, GL_TEXTURE_MIN_FILTER, GL_NEAREST, GL_NO_ERROR);
  EXPECT_EQ(static_cast<GLenum>(GL_NEAREST), texture->min_filter());
  SetParameter(texture_ref, GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_NO_ERROR);
  EXPECT_EQ(static_cast<GLenum>(GL_NEAREST), texture->mag_filter());
  SetParameter(texture_ref, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  EXPECT_EQ(static_cast<GLenum>(GL_CLAMP_TO_EDGE), texture->wrap_s());
  SetParameter(texture_ref, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  EXPECT_EQ(static_cast<GLenum>(GL_CLAMP_TO_EDGE), texture->wrap_t());
  SetParameter(texture_ref, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1, GL_NO_ERROR);
  SetParameter(texture_ref, GL_TEXTURE_MAX_ANISOTROPY_EXT, 2, GL_NO_ERROR);
  SetParameter(
      texture_ref, GL_TEXTURE_MIN_FILTER, GL_CLAMP_TO_EDGE, GL_INVALID_ENUM);
  EXPECT_EQ(static_cast<GLenum>(GL_NEAREST), texture->min_filter());
  SetParameter(
      texture_ref, GL_TEXTURE_MAG_FILTER, GL_CLAMP_TO_EDGE, GL_INVALID_ENUM);
  EXPECT_EQ(static_cast<GLenum>(GL_NEAREST), texture->min_filter());
  SetParameter(texture_ref, GL_TEXTURE_WRAP_S, GL_NEAREST, GL_INVALID_ENUM);
  EXPECT_EQ(static_cast<GLenum>(GL_CLAMP_TO_EDGE), texture->wrap_s());
  SetParameter(texture_ref, GL_TEXTURE_WRAP_T, GL_NEAREST, GL_INVALID_ENUM);
  EXPECT_EQ(static_cast<GLenum>(GL_CLAMP_TO_EDGE), texture->wrap_t());
  SetParameter(texture_ref, GL_TEXTURE_MAX_ANISOTROPY_EXT, 0, GL_INVALID_VALUE);
}

TEST_F(TextureManagerTest, UseDefaultTexturesTrue) {
  bool use_default_textures = true;
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());

  TestHelper::SetupTextureManagerInitExpectations(
      gl_.get(), "GL_ANGLE_texture_usage", use_default_textures);
  TextureManager manager(NULL,
                         feature_info_.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         use_default_textures);
  manager.Initialize();

  EXPECT_TRUE(manager.GetDefaultTextureInfo(GL_TEXTURE_2D) != NULL);
  EXPECT_TRUE(manager.GetDefaultTextureInfo(GL_TEXTURE_CUBE_MAP) != NULL);

  // TODO(vmiura): Test GL_TEXTURE_EXTERNAL_OES & GL_TEXTURE_RECTANGLE_ARB.

  manager.Destroy(false);
}

TEST_F(TextureManagerTest, UseDefaultTexturesFalse) {
  bool use_default_textures = false;
  TestHelper::SetupTextureManagerInitExpectations(
      gl_.get(), "GL_ANGLE_texture_usage", use_default_textures);
  TextureManager manager(NULL,
                         feature_info_.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         use_default_textures);
  manager.Initialize();

  EXPECT_TRUE(manager.GetDefaultTextureInfo(GL_TEXTURE_2D) == NULL);
  EXPECT_TRUE(manager.GetDefaultTextureInfo(GL_TEXTURE_CUBE_MAP) == NULL);

  // TODO(vmiura): Test GL_TEXTURE_EXTERNAL_OES & GL_TEXTURE_RECTANGLE_ARB.

  manager.Destroy(false);
}

TEST_F(TextureManagerTest, TextureUsageExt) {
  TestHelper::SetupTextureManagerInitExpectations(
      gl_.get(), "GL_ANGLE_texture_usage", kUseDefaultTextures);
  TextureManager manager(NULL,
                         feature_info_.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.Initialize();
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  // Check we can create texture.
  manager.CreateTexture(kClient1Id, kService1Id);
  // Check texture got created.
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  TestHelper::SetTexParameteriWithExpectations(
      gl_.get(), error_state_.get(), &manager, texture_ref,
      GL_TEXTURE_USAGE_ANGLE, GL_FRAMEBUFFER_ATTACHMENT_ANGLE, GL_NO_ERROR);
  EXPECT_EQ(static_cast<GLenum>(GL_FRAMEBUFFER_ATTACHMENT_ANGLE),
            texture_ref->texture()->usage());
  manager.Destroy(false);
}

TEST_F(TextureManagerTest, Destroy) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  TestHelper::SetupTextureManagerInitExpectations(
      gl_.get(), "", kUseDefaultTextures);
  TextureManager manager(NULL,
                         feature_info_.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.Initialize();
  // Check we can create texture.
  manager.CreateTexture(kClient1Id, kService1Id);
  // Check texture got created.
  TextureRef* texture = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture != NULL);
  EXPECT_CALL(*gl_, DeleteTextures(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  TestHelper::SetupTextureManagerDestructionExpectations(
      gl_.get(), "", kUseDefaultTextures);
  manager.Destroy(true);
  // Check that resources got freed.
  texture = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture == NULL);
}

TEST_F(TextureManagerTest, MaxValues) {
  // Check we get the right values for the max sizes.
  EXPECT_EQ(kMax2dLevels, manager_->MaxLevelsForTarget(GL_TEXTURE_2D));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_X));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_X));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_Y));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_Z));
  EXPECT_EQ(kMaxCubeMapLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z));
  EXPECT_EQ(kMaxExternalLevels,
            manager_->MaxLevelsForTarget(GL_TEXTURE_EXTERNAL_OES));
  EXPECT_EQ(kMaxTextureSize, manager_->MaxSizeForTarget(GL_TEXTURE_2D));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_X));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_X));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_Y));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_POSITIVE_Z));
  EXPECT_EQ(kMaxCubeMapTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z));
  EXPECT_EQ(kMaxRectangleTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_RECTANGLE_ARB));
  EXPECT_EQ(kMaxExternalTextureSize,
            manager_->MaxSizeForTarget(GL_TEXTURE_EXTERNAL_OES));
}

TEST_F(TextureManagerTest, ValidForTarget) {
  // check 2d
  EXPECT_TRUE(manager_->ValidForTarget(
      GL_TEXTURE_2D, 0, kMaxTextureSize, kMaxTextureSize, 1));
  EXPECT_TRUE(manager_->ValidForTarget(
      GL_TEXTURE_2D, kMax2dLevels - 1, 1, 1, 1));
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_2D, kMax2dLevels - 1, 1, 2, 1));
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_2D, kMax2dLevels - 1, 2, 1, 1));
  // check level out of range.
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_2D, kMax2dLevels, kMaxTextureSize, 1, 1));
  // check has depth.
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_2D, kMax2dLevels, kMaxTextureSize, 1, 2));
  // Check NPOT width on level 0
  EXPECT_TRUE(manager_->ValidForTarget(GL_TEXTURE_2D, 0, 5, 2, 1));
  // Check NPOT height on level 0
  EXPECT_TRUE(manager_->ValidForTarget(GL_TEXTURE_2D, 0, 2, 5, 1));
  // Check NPOT width on level 1
  EXPECT_FALSE(manager_->ValidForTarget(GL_TEXTURE_2D, 1, 5, 2, 1));
  // Check NPOT height on level 1
  EXPECT_FALSE(manager_->ValidForTarget(GL_TEXTURE_2D, 1, 2, 5, 1));

  // check cube
  EXPECT_TRUE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, 0,
      kMaxCubeMapTextureSize, kMaxCubeMapTextureSize, 1));
  EXPECT_TRUE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, kMaxCubeMapLevels - 1, 1, 1, 1));
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, kMaxCubeMapLevels - 1, 2, 2, 1));
  // check level out of range.
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, kMaxCubeMapLevels,
      kMaxCubeMapTextureSize, 1, 1));
  // check not square.
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, kMaxCubeMapLevels,
      kMaxCubeMapTextureSize, 1, 1));
  // check has depth.
  EXPECT_FALSE(manager_->ValidForTarget(
      GL_TEXTURE_CUBE_MAP, kMaxCubeMapLevels,
      kMaxCubeMapTextureSize, 1, 2));

  for (GLint level = 0; level < kMax2dLevels; ++level) {
    EXPECT_TRUE(manager_->ValidForTarget(
        GL_TEXTURE_2D, level, kMaxTextureSize >> level, 1, 1));
    EXPECT_TRUE(manager_->ValidForTarget(
        GL_TEXTURE_2D, level, 1, kMaxTextureSize >> level, 1));
    EXPECT_FALSE(manager_->ValidForTarget(
        GL_TEXTURE_2D, level, (kMaxTextureSize >> level) + 1, 1, 1));
    EXPECT_FALSE(manager_->ValidForTarget(
        GL_TEXTURE_2D, level, 1, (kMaxTextureSize >> level) + 1, 1));
  }

  for (GLint level = 0; level < kMaxCubeMapLevels; ++level) {
    EXPECT_TRUE(manager_->ValidForTarget(
        GL_TEXTURE_CUBE_MAP, level,
        kMaxCubeMapTextureSize >> level,
        kMaxCubeMapTextureSize >> level,
        1));
    EXPECT_FALSE(manager_->ValidForTarget(
        GL_TEXTURE_CUBE_MAP, level,
        (kMaxCubeMapTextureSize >> level) * 2,
        (kMaxCubeMapTextureSize >> level) * 2,
        1));
  }
}

TEST_F(TextureManagerTest, ValidForTargetNPOT) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_npot");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  // Check NPOT width on level 0
  EXPECT_TRUE(manager.ValidForTarget(GL_TEXTURE_2D, 0, 5, 2, 1));
  // Check NPOT height on level 0
  EXPECT_TRUE(manager.ValidForTarget(GL_TEXTURE_2D, 0, 2, 5, 1));
  // Check NPOT width on level 1
  EXPECT_TRUE(manager.ValidForTarget(GL_TEXTURE_2D, 1, 5, 2, 1));
  // Check NPOT height on level 1
  EXPECT_TRUE(manager.ValidForTarget(GL_TEXTURE_2D, 1, 2, 5, 1));
  manager.Destroy(false);
}

class TextureTestBase : public GpuServiceTest {
 public:
  static const GLint kMaxTextureSize = 16;
  static const GLint kMaxCubeMapTextureSize = 8;
  static const GLint kMaxRectangleTextureSize = 16;
  static const GLint kMax2dLevels = 5;
  static const GLint kMaxCubeMapLevels = 4;
  static const GLuint kClient1Id = 1;
  static const GLuint kService1Id = 11;
  static const bool kUseDefaultTextures = false;

  TextureTestBase()
      : feature_info_(new FeatureInfo()) {
  }
  ~TextureTestBase() override { texture_ref_ = NULL; }

 protected:
  void SetUpBase(MemoryTracker* memory_tracker, std::string extensions) {
    GpuServiceTest::SetUp();
    if (!extensions.empty()) {
      TestHelper::SetupFeatureInfoInitExpectations(gl_.get(),
                                                   extensions.c_str());
      feature_info_->Initialize();
    }

    manager_.reset(new TextureManager(memory_tracker,
                                      feature_info_.get(),
                                      kMaxTextureSize,
                                      kMaxCubeMapTextureSize,
                                      kMaxRectangleTextureSize,
                                      kUseDefaultTextures));
    decoder_.reset(new ::testing::StrictMock<gles2::MockGLES2Decoder>());
    error_state_.reset(new ::testing::StrictMock<gles2::MockErrorState>());
    manager_->CreateTexture(kClient1Id, kService1Id);
    texture_ref_ = manager_->GetTexture(kClient1Id);
    ASSERT_TRUE(texture_ref_.get() != NULL);
  }

  void TearDown() override {
    if (texture_ref_.get()) {
      // If it's not in the manager then setting texture_ref_ to NULL will
      // delete the texture.
      if (!texture_ref_->client_id()) {
        // Check that it gets deleted when the last reference is released.
        EXPECT_CALL(*gl_,
            DeleteTextures(1, ::testing::Pointee(texture_ref_->service_id())))
            .Times(1)
            .RetiresOnSaturation();
      }
      texture_ref_ = NULL;
    }
    manager_->Destroy(false);
    manager_.reset();
    GpuServiceTest::TearDown();
  }

  void SetParameter(
      TextureRef* texture_ref, GLenum pname, GLint value, GLenum error) {
    TestHelper::SetTexParameteriWithExpectations(
        gl_.get(), error_state_.get(), manager_.get(),
        texture_ref, pname, value, error);
  }

  scoped_ptr<MockGLES2Decoder> decoder_;
  scoped_ptr<MockErrorState> error_state_;
  scoped_refptr<FeatureInfo> feature_info_;
  scoped_ptr<TextureManager> manager_;
  scoped_refptr<TextureRef> texture_ref_;
};

class TextureTest : public TextureTestBase {
 protected:
  void SetUp() override { SetUpBase(NULL, std::string()); }
};

class TextureMemoryTrackerTest : public TextureTestBase {
 protected:
  void SetUp() override {
    mock_memory_tracker_ = new StrictMock<MockMemoryTracker>();
    SetUpBase(mock_memory_tracker_.get(), std::string());
  }

  scoped_refptr<MockMemoryTracker> mock_memory_tracker_;
};

#define EXPECT_MEMORY_ALLOCATION_CHANGE(old_size, new_size, pool)   \
  EXPECT_CALL(*mock_memory_tracker_.get(),                          \
              TrackMemoryAllocatedChange(old_size, new_size, pool)) \
      .Times(1).RetiresOnSaturation()

TEST_F(TextureTest, Basic) {
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(0u, texture->target());
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_EQ(0, texture->num_uncleared_mips());
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(texture->IsImmutable());
  EXPECT_EQ(static_cast<GLenum>(GL_NEAREST_MIPMAP_LINEAR),
            texture->min_filter());
  EXPECT_EQ(static_cast<GLenum>(GL_LINEAR), texture->mag_filter());
  EXPECT_EQ(static_cast<GLenum>(GL_REPEAT), texture->wrap_s());
  EXPECT_EQ(static_cast<GLenum>(GL_REPEAT), texture->wrap_t());
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_EQ(0u, texture->estimated_size());
}

TEST_F(TextureTest, SetTargetTexture2D) {
  Texture* texture = texture_ref_->texture();
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(texture->IsImmutable());
}

TEST_F(TextureTest, SetTargetTextureExternalOES) {
  Texture* texture = texture_ref_->texture();
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_EXTERNAL_OES);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsNPOT(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_TRUE(texture->IsImmutable());
}

TEST_F(TextureTest, ZeroSizeCanNotRender) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         1,
                         1,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         0,
                         0,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
}

TEST_F(TextureTest, EstimatedSize) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_EQ(8u * 4u * 4u, texture_ref_->texture()->estimated_size());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         2,
                         GL_RGBA,
                         8,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_EQ(8u * 4u * 4u * 2u, texture_ref_->texture()->estimated_size());
}

TEST_F(TextureMemoryTrackerTest, EstimatedSize) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 128, MemoryTracker::kUnmanaged);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_MEMORY_ALLOCATION_CHANGE(128, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 256, MemoryTracker::kUnmanaged);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         2,
                         GL_RGBA,
                         8,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  // Add expectation for texture deletion.
  EXPECT_MEMORY_ALLOCATION_CHANGE(256, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kUnmanaged);
}

TEST_F(TextureMemoryTrackerTest, SetParameterPool) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 128, MemoryTracker::kUnmanaged);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_MEMORY_ALLOCATION_CHANGE(128, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 128, MemoryTracker::kManaged);
  SetParameter(texture_ref_.get(),
               GL_TEXTURE_POOL_CHROMIUM,
               GL_TEXTURE_POOL_MANAGED_CHROMIUM,
               GL_NO_ERROR);
  // Add expectation for texture deletion.
  EXPECT_MEMORY_ALLOCATION_CHANGE(128, 0, MemoryTracker::kManaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kManaged);
}

TEST_F(TextureTest, POT2D) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  // Check Setting level 0 to POT
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_EQ(0, texture->num_uncleared_mips());
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  // Set filters to something that will work with a single mip.
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_MIN_FILTER, GL_LINEAR, GL_NO_ERROR);
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Set them back.
  SetParameter(texture_ref_.get(),
               GL_TEXTURE_MIN_FILTER,
               GL_LINEAR_MIPMAP_LINEAR,
               GL_NO_ERROR);
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());

  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  // Make mips.
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Change a mip.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  // Set a level past the number of mips that would get generated.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         3,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  // Make mips.
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
}

TEST_F(TextureMemoryTrackerTest, MarkMipmapsGenerated) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 64, MemoryTracker::kUnmanaged);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_MEMORY_ALLOCATION_CHANGE(64, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 84, MemoryTracker::kUnmanaged);
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_MEMORY_ALLOCATION_CHANGE(84, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kUnmanaged);
}

TEST_F(TextureTest, UnusedMips) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  // Set level zero to large size.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Set level zero to large smaller (levels unused mips)
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Set an unused level to some size
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         4,
                         GL_RGBA,
                         16,
                         16,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
}

TEST_F(TextureTest, NPOT2D) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  // Check Setting level 0 to NPOT
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         5,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_MIN_FILTER, GL_LINEAR, GL_NO_ERROR);
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Change it to POT.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
}

TEST_F(TextureTest, NPOT2DNPOTOK) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_npot");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  Texture* texture = texture_ref->texture();

  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  // Check Setting level 0 to NPOT
  manager.SetLevelInfo(texture_ref,
      GL_TEXTURE_2D, 0, GL_RGBA, 4, 5, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, true);
  EXPECT_TRUE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager.CanGenerateMipmaps(texture_ref));
  EXPECT_FALSE(manager.CanRender(texture_ref));
  EXPECT_TRUE(manager.HaveUnrenderableTextures());
  EXPECT_TRUE(manager.MarkMipmapsGenerated(texture_ref));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(manager.CanRender(texture_ref));
  EXPECT_FALSE(manager.HaveUnrenderableTextures());
  manager.Destroy(false);
}

TEST_F(TextureTest, POTCubeMap) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_CUBE_MAP);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_CUBE_MAP), texture->target());
  // Check Setting level 0 each face to POT
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_POSITIVE_X,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_FALSE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_FALSE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  EXPECT_FALSE(manager_->CanRender(texture_ref_.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());

  // Make mips.
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_TRUE(manager_->CanRender(texture_ref_.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());

  // Change a mip.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
                         1,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(TextureTestHelper::IsNPOT(texture));
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(TextureTestHelper::IsCubeComplete(texture));
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  // Set a level past the number of mips that would get generated.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
                         3,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(manager_->CanGenerateMipmaps(texture_ref_.get()));
  // Make mips.
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_TRUE(TextureTestHelper::IsCubeComplete(texture));
}

TEST_F(TextureTest, GetLevelSize) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         5,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  GLsizei width = -1;
  GLsizei height = -1;
  Texture* texture = texture_ref_->texture();
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, -1, &width, &height));
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 1000, &width, &height));
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 0, &width, &height));
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(4, width);
  EXPECT_EQ(5, height);
  manager_->RemoveTexture(kClient1Id);
  EXPECT_TRUE(texture->GetLevelSize(GL_TEXTURE_2D, 1, &width, &height));
  EXPECT_EQ(4, width);
  EXPECT_EQ(5, height);
}

TEST_F(TextureTest, GetLevelType) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         5,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  GLenum type = 0;
  GLenum format = 0;
  Texture* texture = texture_ref_->texture();
  EXPECT_FALSE(texture->GetLevelType(GL_TEXTURE_2D, -1, &type, &format));
  EXPECT_FALSE(texture->GetLevelType(GL_TEXTURE_2D, 1000, &type, &format));
  EXPECT_FALSE(texture->GetLevelType(GL_TEXTURE_2D, 0, &type, &format));
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &format));
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), format);
  manager_->RemoveTexture(kClient1Id);
  EXPECT_TRUE(texture->GetLevelType(GL_TEXTURE_2D, 1, &type, &format));
  EXPECT_EQ(static_cast<GLenum>(GL_UNSIGNED_BYTE), type);
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA), format);
}

TEST_F(TextureTest, ValidForTexture) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         5,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  // Check bad face.
  Texture* texture = texture_ref_->texture();
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
      1, 0, 0, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad level.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 0, 0, 0, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad xoffset.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, -1, 0, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad xoffset + width > width.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 1, 0, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad yoffset.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, -1, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad yoffset + height > height.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 1, 4, 5, GL_UNSIGNED_BYTE));
  // Check bad width.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 0, 5, 5, GL_UNSIGNED_BYTE));
  // Check bad height.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 0, 4, 6, GL_UNSIGNED_BYTE));
  // Check bad type.
  EXPECT_FALSE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 0, 4, 5, GL_UNSIGNED_SHORT_4_4_4_4));
  // Check valid full size
  EXPECT_TRUE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 0, 4, 5, GL_UNSIGNED_BYTE));
  // Check valid particial size.
  EXPECT_TRUE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 1, 1, 2, 3, GL_UNSIGNED_BYTE));
  manager_->RemoveTexture(kClient1Id);
  EXPECT_TRUE(texture->ValidForTexture(
      GL_TEXTURE_2D, 1, 0, 0, 4, 5, GL_UNSIGNED_BYTE));
}

TEST_F(TextureTest, FloatNotLinear) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_float");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  manager.SetLevelInfo(texture_ref,
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 1, 0, GL_RGBA, GL_FLOAT, true);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  TestHelper::SetTexParameteriWithExpectations(
      gl_.get(), error_state_.get(), &manager,
      texture_ref, GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_NO_ERROR);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  TestHelper::SetTexParameteriWithExpectations(
      gl_.get(), error_state_.get(), &manager, texture_ref,
      GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST, GL_NO_ERROR);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  manager.Destroy(false);
}

TEST_F(TextureTest, FloatLinear) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_float GL_OES_texture_float_linear");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  manager.SetLevelInfo(texture_ref,
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 1, 0, GL_RGBA, GL_FLOAT, true);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  manager.Destroy(false);
}

TEST_F(TextureTest, HalfFloatNotLinear) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_half_float");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  manager.SetLevelInfo(texture_ref,
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 1, 0, GL_RGBA, GL_HALF_FLOAT_OES, true);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  TestHelper::SetTexParameteriWithExpectations(
      gl_.get(), error_state_.get(), &manager,
      texture_ref, GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_NO_ERROR);
  EXPECT_FALSE(TextureTestHelper::IsTextureComplete(texture));
  TestHelper::SetTexParameteriWithExpectations(
      gl_.get(), error_state_.get(), &manager, texture_ref,
      GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST, GL_NO_ERROR);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  manager.Destroy(false);
}

TEST_F(TextureTest, HalfFloatLinear) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_texture_half_float GL_OES_texture_half_float_linear");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  manager.SetLevelInfo(texture_ref,
      GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 1, 0, GL_RGBA, GL_HALF_FLOAT_OES, true);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  manager.Destroy(false);
}

TEST_F(TextureTest, EGLImageExternal) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_OES_EGL_image_external");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_EXTERNAL_OES);
  Texture* texture = texture_ref->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_EXTERNAL_OES), texture->target());
  EXPECT_FALSE(manager.CanGenerateMipmaps(texture_ref));
  manager.Destroy(false);
}

TEST_F(TextureTest, DepthTexture) {
  TestHelper::SetupFeatureInfoInitExpectations(
      gl_.get(), "GL_ANGLE_depth_texture");
  scoped_refptr<FeatureInfo> feature_info(new FeatureInfo());
  feature_info->Initialize();
  TextureManager manager(NULL,
                         feature_info.get(),
                         kMaxTextureSize,
                         kMaxCubeMapTextureSize,
                         kMaxRectangleTextureSize,
                         kUseDefaultTextures);
  manager.CreateTexture(kClient1Id, kService1Id);
  TextureRef* texture_ref = manager.GetTexture(kClient1Id);
  ASSERT_TRUE(texture_ref != NULL);
  manager.SetTarget(texture_ref, GL_TEXTURE_2D);
  manager.SetLevelInfo(
      texture_ref, GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, 4, 4, 1, 0,
      GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, false);
  EXPECT_FALSE(manager.CanGenerateMipmaps(texture_ref));
  manager.Destroy(false);
}

TEST_F(TextureTest, SafeUnsafe) {
  static const GLuint kClient2Id = 2;
  static const GLuint kService2Id = 12;
  static const GLuint kClient3Id = 3;
  static const GLuint kService3Id = 13;
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(0, texture->num_uncleared_mips());
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref_.get(), GL_TEXTURE_2D, 0, true);
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref_.get(), GL_TEXTURE_2D, 1, true);
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(2, texture->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref_.get(), GL_TEXTURE_2D, 0, true);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref_.get(), GL_TEXTURE_2D, 1, true);
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture->num_uncleared_mips());
  manager_->MarkMipmapsGenerated(texture_ref_.get());
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());

  manager_->CreateTexture(kClient2Id, kService2Id);
  scoped_refptr<TextureRef> texture_ref2(
      manager_->GetTexture(kClient2Id));
  ASSERT_TRUE(texture_ref2.get() != NULL);
  manager_->SetTarget(texture_ref2.get(), GL_TEXTURE_2D);
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  Texture* texture2 = texture_ref2->texture();
  EXPECT_EQ(0, texture2->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref2.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture2->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref2.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture2->num_uncleared_mips());

  manager_->CreateTexture(kClient3Id, kService3Id);
  scoped_refptr<TextureRef> texture_ref3(
      manager_->GetTexture(kClient3Id));
  ASSERT_TRUE(texture_ref3.get() != NULL);
  manager_->SetTarget(texture_ref3.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref3.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  Texture* texture3 = texture_ref3->texture();
  EXPECT_EQ(1, texture3->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref2.get(), GL_TEXTURE_2D, 0, true);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture2->num_uncleared_mips());
  manager_->SetLevelCleared(texture_ref3.get(), GL_TEXTURE_2D, 0, true);
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture3->num_uncleared_mips());

  manager_->SetLevelInfo(texture_ref2.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  manager_->SetLevelInfo(texture_ref3.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         8,
                         8,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture2->num_uncleared_mips());
  EXPECT_EQ(1, texture3->num_uncleared_mips());
  manager_->RemoveTexture(kClient3Id);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  manager_->RemoveTexture(kClient2Id);
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_CALL(*gl_, DeleteTextures(1, ::testing::Pointee(kService2Id)))
      .Times(1)
      .RetiresOnSaturation();
  texture_ref2 = NULL;
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_CALL(*gl_, DeleteTextures(1, ::testing::Pointee(kService3Id)))
      .Times(1)
      .RetiresOnSaturation();
  texture_ref3 = NULL;
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
}

TEST_F(TextureTest, ClearTexture) {
  EXPECT_CALL(*decoder_, ClearLevel(_, _, _, _, _, _, _, _, _))
      .WillRepeatedly(Return(true));
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  Texture* texture = texture_ref_->texture();
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(2, texture->num_uncleared_mips());
  manager_->ClearRenderableLevels(decoder_.get(), texture_ref_.get());
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(2, texture->num_uncleared_mips());
  manager_->ClearTextureLevel(
      decoder_.get(), texture_ref_.get(), GL_TEXTURE_2D, 0);
  EXPECT_FALSE(texture->SafeToRenderFrom());
  EXPECT_TRUE(manager_->HaveUnsafeTextures());
  EXPECT_TRUE(manager_->HaveUnclearedMips());
  EXPECT_EQ(1, texture->num_uncleared_mips());
  manager_->ClearTextureLevel(
      decoder_.get(), texture_ref_.get(), GL_TEXTURE_2D, 1);
  EXPECT_TRUE(texture->SafeToRenderFrom());
  EXPECT_FALSE(manager_->HaveUnsafeTextures());
  EXPECT_FALSE(manager_->HaveUnclearedMips());
  EXPECT_EQ(0, texture->num_uncleared_mips());
}

TEST_F(TextureTest, UseDeletedTexture) {
  static const GLuint kClient2Id = 2;
  static const GLuint kService2Id = 12;
  // Make the default texture renderable
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         1,
                         1,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  // Make a new texture
  manager_->CreateTexture(kClient2Id, kService2Id);
  scoped_refptr<TextureRef> texture_ref(
      manager_->GetTexture(kClient2Id));
  manager_->SetTarget(texture_ref.get(), GL_TEXTURE_2D);
  EXPECT_FALSE(manager_->CanRender(texture_ref.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  // Remove it.
  manager_->RemoveTexture(kClient2Id);
  EXPECT_FALSE(manager_->CanRender(texture_ref.get()));
  EXPECT_TRUE(manager_->HaveUnrenderableTextures());
  // Check that we can still manipulate it and it effects the manager.
  manager_->SetLevelInfo(texture_ref.get(),
                         GL_TEXTURE_2D,
                         0,
                         GL_RGBA,
                         1,
                         1,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  EXPECT_TRUE(manager_->CanRender(texture_ref.get()));
  EXPECT_FALSE(manager_->HaveUnrenderableTextures());
  EXPECT_CALL(*gl_, DeleteTextures(1, ::testing::Pointee(kService2Id)))
      .Times(1)
      .RetiresOnSaturation();
  texture_ref = NULL;
}

TEST_F(TextureTest, GetLevelImage) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  Texture* texture = texture_ref_->texture();
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 1) == NULL);
  // Set image.
  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  manager_->SetLevelImage(texture_ref_.get(), GL_TEXTURE_2D, 1, image.get());
  EXPECT_FALSE(texture->GetLevelImage(GL_TEXTURE_2D, 1) == NULL);
  // Remove it.
  manager_->SetLevelImage(texture_ref_.get(), GL_TEXTURE_2D, 1, NULL);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 1) == NULL);
  manager_->SetLevelImage(texture_ref_.get(), GL_TEXTURE_2D, 1, image.get());
  // Image should be reset when SetLevelInfo is called.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  EXPECT_TRUE(texture->GetLevelImage(GL_TEXTURE_2D, 1) == NULL);
}

namespace {

bool InSet(std::set<std::string>* string_set, const std::string& str) {
  std::pair<std::set<std::string>::iterator, bool> result =
      string_set->insert(str);
  return !result.second;
}

}  // anonymous namespace

TEST_F(TextureTest, AddToSignature) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  std::string signature1;
  std::string signature2;
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature1);

  std::set<std::string> string_set;
  EXPECT_FALSE(InSet(&string_set, signature1));

  // check changing 1 thing makes a different signature.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         4,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  // check putting it back makes the same signature.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_EQ(signature1, signature2);

  // Check setting cleared status does not change signature.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_EQ(signature1, signature2);

  // Check changing other settings changes signature.
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         4,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         2,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         1,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGB,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_FLOAT,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  // put it back
  manager_->SetLevelInfo(texture_ref_.get(),
                         GL_TEXTURE_2D,
                         1,
                         GL_RGBA,
                         2,
                         2,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         false);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_EQ(signature1, signature2);

  // check changing parameters changes signature.
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_MIN_FILTER, GL_NEAREST, GL_NO_ERROR);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  SetParameter(texture_ref_.get(),
               GL_TEXTURE_MIN_FILTER,
               GL_NEAREST_MIPMAP_LINEAR,
               GL_NO_ERROR);
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_MAG_FILTER, GL_NEAREST, GL_NO_ERROR);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  SetParameter(
      texture_ref_.get(), GL_TEXTURE_MAG_FILTER, GL_LINEAR, GL_NO_ERROR);
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  SetParameter(texture_ref_.get(), GL_TEXTURE_WRAP_S, GL_REPEAT, GL_NO_ERROR);
  SetParameter(
      texture_ref_.get(), GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE, GL_NO_ERROR);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  // Check putting it back genenerates the same signature
  SetParameter(texture_ref_.get(), GL_TEXTURE_WRAP_T, GL_REPEAT, GL_NO_ERROR);
  signature2.clear();
  manager_->AddToSignature(texture_ref_.get(), GL_TEXTURE_2D, 1, &signature2);
  EXPECT_EQ(signature1, signature2);

  // Check the set was acutally getting different signatures.
  EXPECT_EQ(11u, string_set.size());
}

class ProduceConsumeTextureTest : public TextureTest,
                                  public ::testing::WithParamInterface<GLenum> {
 public:
  void SetUp() override {
    TextureTest::SetUpBase(NULL, "GL_OES_EGL_image_external");
    manager_->CreateTexture(kClient2Id, kService2Id);
    texture2_ = manager_->GetTexture(kClient2Id);

    EXPECT_CALL(*decoder_.get(), GetErrorState())
      .WillRepeatedly(Return(error_state_.get()));
  }

  void TearDown() override {
    if (texture2_.get()) {
      // If it's not in the manager then setting texture2_ to NULL will
      // delete the texture.
      if (!texture2_->client_id()) {
        // Check that it gets deleted when the last reference is released.
        EXPECT_CALL(
            *gl_,
            DeleteTextures(1, ::testing::Pointee(texture2_->service_id())))
            .Times(1).RetiresOnSaturation();
      }
      texture2_ = NULL;
    }
    TextureTest::TearDown();
  }

 protected:
  struct LevelInfo {
    LevelInfo(GLenum target,
              GLenum format,
              GLsizei width,
              GLsizei height,
              GLsizei depth,
              GLint border,
              GLenum type,
              bool cleared)
        : target(target),
          format(format),
          width(width),
          height(height),
          depth(depth),
          border(border),
          type(type),
          cleared(cleared) {}

    LevelInfo()
        : target(0),
          format(0),
          width(-1),
          height(-1),
          depth(1),
          border(0),
          type(0),
          cleared(false) {}

    bool operator==(const LevelInfo& other) const {
      return target == other.target && format == other.format &&
             width == other.width && height == other.height &&
             depth == other.depth && border == other.border &&
             type == other.type && cleared == other.cleared;
    }

    GLenum target;
    GLenum format;
    GLsizei width;
    GLsizei height;
    GLsizei depth;
    GLint border;
    GLenum type;
    bool cleared;
  };

  void SetLevelInfo(TextureRef* texture_ref,
                    GLint level,
                    const LevelInfo& info) {
    manager_->SetLevelInfo(texture_ref,
                           info.target,
                           level,
                           info.format,
                           info.width,
                           info.height,
                           info.depth,
                           info.border,
                           info.format,
                           info.type,
                           info.cleared);
  }

  static LevelInfo GetLevelInfo(const TextureRef* texture_ref,
                                GLint target,
                                GLint level) {
    const Texture* texture = texture_ref->texture();
    LevelInfo info;
    info.target = target;
    EXPECT_TRUE(texture->GetLevelSize(target, level, &info.width,
                                      &info.height));
    EXPECT_TRUE(texture->GetLevelType(target, level, &info.type,
                                      &info.format));
    info.cleared = texture->IsLevelCleared(target, level);
    return info;
  }

  Texture* Produce(TextureRef* texture_ref) {
    Texture* texture = manager_->Produce(texture_ref);
    EXPECT_TRUE(texture != NULL);
    return texture;
  }

  void Consume(GLuint client_id, Texture* texture) {
    EXPECT_TRUE(manager_->Consume(client_id, texture));
  }

  scoped_refptr<TextureRef> texture2_;

 private:
  static const GLuint kClient2Id;
  static const GLuint kService2Id;
};

const GLuint ProduceConsumeTextureTest::kClient2Id = 2;
const GLuint ProduceConsumeTextureTest::kService2Id = 12;

TEST_F(ProduceConsumeTextureTest, ProduceConsume2D) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_2D);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_2D), texture->target());
  LevelInfo level0(
      GL_TEXTURE_2D, GL_RGBA, 4, 4, 1, 0, GL_UNSIGNED_BYTE, true);
  SetLevelInfo(texture_ref_.get(), 0, level0);
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture_ref_.get()));
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  LevelInfo level1 = GetLevelInfo(texture_ref_.get(), GL_TEXTURE_2D, 1);
  LevelInfo level2 = GetLevelInfo(texture_ref_.get(), GL_TEXTURE_2D, 2);
  Texture* produced_texture = Produce(texture_ref_.get());
  EXPECT_EQ(produced_texture, texture);

  // Make this texture bigger with more levels, and make sure they get
  // clobbered correctly during Consume().
  manager_->SetTarget(texture2_.get(), GL_TEXTURE_2D);
  SetLevelInfo(
      texture2_.get(),
      0,
      LevelInfo(GL_TEXTURE_2D, GL_RGBA, 16, 16, 1, 0, GL_UNSIGNED_BYTE, false));
  EXPECT_TRUE(manager_->MarkMipmapsGenerated(texture2_.get()));
  texture = texture2_->texture();
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  EXPECT_EQ(1024U + 256U + 64U + 16U + 4U, texture->estimated_size());

  GLuint client_id = texture2_->client_id();
  manager_->RemoveTexture(client_id);
  Consume(client_id, produced_texture);
  scoped_refptr<TextureRef> restored_texture = manager_->GetTexture(client_id);
  EXPECT_EQ(produced_texture, restored_texture->texture());
  EXPECT_EQ(level0, GetLevelInfo(restored_texture.get(), GL_TEXTURE_2D, 0));
  EXPECT_EQ(level1, GetLevelInfo(restored_texture.get(), GL_TEXTURE_2D, 1));
  EXPECT_EQ(level2, GetLevelInfo(restored_texture.get(), GL_TEXTURE_2D, 2));
  texture = restored_texture->texture();
  EXPECT_EQ(64U + 16U + 4U, texture->estimated_size());
  GLint w, h;
  EXPECT_FALSE(texture->GetLevelSize(GL_TEXTURE_2D, 3, &w, &h));

  // However the old texture ref still exists if it was referenced somewhere.
  EXPECT_EQ(1024U + 256U + 64U + 16U + 4U,
            texture2_->texture()->estimated_size());
}

TEST_F(ProduceConsumeTextureTest, ProduceConsumeClearRectangle) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_RECTANGLE_ARB);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_RECTANGLE_ARB), texture->target());
  LevelInfo level0(
      GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, 1, 1, 1, 0, GL_UNSIGNED_BYTE, false);
  SetLevelInfo(texture_ref_.get(), 0, level0);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  Texture* produced_texture = Produce(texture_ref_.get());
  EXPECT_EQ(produced_texture, texture);
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_RECTANGLE_ARB),
            produced_texture->target());

  GLuint client_id = texture2_->client_id();
  manager_->RemoveTexture(client_id);
  Consume(client_id, produced_texture);
  scoped_refptr<TextureRef> restored_texture = manager_->GetTexture(client_id);
  EXPECT_EQ(produced_texture, restored_texture->texture());

  // See if we can clear the previously uncleared level now.
  EXPECT_EQ(level0,
            GetLevelInfo(restored_texture.get(), GL_TEXTURE_RECTANGLE_ARB, 0));
  EXPECT_CALL(*decoder_, ClearLevel(_, _, _, _, _, _, _, _, _))
      .WillRepeatedly(Return(true));
  EXPECT_TRUE(manager_->ClearTextureLevel(
      decoder_.get(), restored_texture.get(), GL_TEXTURE_RECTANGLE_ARB, 0));
}

TEST_F(ProduceConsumeTextureTest, ProduceConsumeExternal) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_EXTERNAL_OES);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_EXTERNAL_OES), texture->target());
  LevelInfo level0(
      GL_TEXTURE_EXTERNAL_OES, GL_RGBA, 1, 1, 1, 0, GL_UNSIGNED_BYTE, false);
  SetLevelInfo(texture_ref_.get(), 0, level0);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  Texture* produced_texture = Produce(texture_ref_.get());
  EXPECT_EQ(produced_texture, texture);

  GLuint client_id = texture2_->client_id();
  manager_->RemoveTexture(client_id);
  Consume(client_id, produced_texture);
  scoped_refptr<TextureRef> restored_texture = manager_->GetTexture(client_id);
  EXPECT_EQ(produced_texture, restored_texture->texture());
  EXPECT_EQ(level0,
            GetLevelInfo(restored_texture.get(), GL_TEXTURE_EXTERNAL_OES, 0));
}

TEST_P(ProduceConsumeTextureTest, ProduceConsumeTextureWithImage) {
  GLenum target = GetParam();
  manager_->SetTarget(texture_ref_.get(), target);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(target), texture->target());
  scoped_refptr<gfx::GLImage> image(new gfx::GLImageStub);
  manager_->SetLevelInfo(texture_ref_.get(),
                         target,
                         0,
                         GL_RGBA,
                         0,
                         0,
                         1,
                         0,
                         GL_RGBA,
                         GL_UNSIGNED_BYTE,
                         true);
  manager_->SetLevelImage(texture_ref_.get(), target, 0, image.get());
  GLuint service_id = texture->service_id();
  Texture* produced_texture = Produce(texture_ref_.get());

  GLuint client_id = texture2_->client_id();
  manager_->RemoveTexture(client_id);
  Consume(client_id, produced_texture);
  scoped_refptr<TextureRef> restored_texture = manager_->GetTexture(client_id);
  EXPECT_EQ(produced_texture, restored_texture->texture());
  EXPECT_EQ(service_id, restored_texture->service_id());
  EXPECT_EQ(image.get(), restored_texture->texture()->GetLevelImage(target, 0));
}

static const GLenum kTextureTargets[] = {GL_TEXTURE_2D, GL_TEXTURE_EXTERNAL_OES,
                                         GL_TEXTURE_RECTANGLE_ARB, };

INSTANTIATE_TEST_CASE_P(Target,
                        ProduceConsumeTextureTest,
                        ::testing::ValuesIn(kTextureTargets));

TEST_F(ProduceConsumeTextureTest, ProduceConsumeCube) {
  manager_->SetTarget(texture_ref_.get(), GL_TEXTURE_CUBE_MAP);
  Texture* texture = texture_ref_->texture();
  EXPECT_EQ(static_cast<GLenum>(GL_TEXTURE_CUBE_MAP), texture->target());
  LevelInfo face0(GL_TEXTURE_CUBE_MAP_POSITIVE_X,
                  GL_RGBA,
                  1,
                  1,
                  1,
                  0,
                  GL_UNSIGNED_BYTE,
                  true);
  LevelInfo face5(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
                  GL_RGBA,
                  3,
                  3,
                  1,
                  0,
                  GL_UNSIGNED_BYTE,
                  true);
  SetLevelInfo(texture_ref_.get(), 0, face0);
  SetLevelInfo(texture_ref_.get(), 0, face5);
  EXPECT_TRUE(TextureTestHelper::IsTextureComplete(texture));
  Texture* produced_texture = Produce(texture_ref_.get());
  EXPECT_EQ(produced_texture, texture);

  GLuint client_id = texture2_->client_id();
  manager_->RemoveTexture(client_id);
  Consume(client_id, produced_texture);
  scoped_refptr<TextureRef> restored_texture = manager_->GetTexture(client_id);
  EXPECT_EQ(produced_texture, restored_texture->texture());
  EXPECT_EQ(
      face0,
      GetLevelInfo(restored_texture.get(), GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0));
  EXPECT_EQ(
      face5,
      GetLevelInfo(restored_texture.get(), GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0));
}

class CountingMemoryTracker : public MemoryTracker {
 public:
  CountingMemoryTracker() {
    current_size_[0] = 0;
    current_size_[1] = 0;
  }

  void TrackMemoryAllocatedChange(size_t old_size,
                                  size_t new_size,
                                  Pool pool) override {
    DCHECK_LT(static_cast<size_t>(pool), arraysize(current_size_));
    current_size_[pool] += new_size - old_size;
  }

  bool EnsureGPUMemoryAvailable(size_t size_needed) override { return true; }

  size_t GetSize(Pool pool) {
    DCHECK_LT(static_cast<size_t>(pool), arraysize(current_size_));
    return current_size_[pool];
  }

 private:
  ~CountingMemoryTracker() override {}

  size_t current_size_[2];
  DISALLOW_COPY_AND_ASSIGN(CountingMemoryTracker);
};

class SharedTextureTest : public GpuServiceTest {
 public:
  static const bool kUseDefaultTextures = false;

  SharedTextureTest() : feature_info_(new FeatureInfo()) {}

  ~SharedTextureTest() override {}

  void SetUp() override {
    GpuServiceTest::SetUp();
    memory_tracker1_ = new CountingMemoryTracker;
    texture_manager1_.reset(
        new TextureManager(memory_tracker1_.get(),
                           feature_info_.get(),
                           TextureManagerTest::kMaxTextureSize,
                           TextureManagerTest::kMaxCubeMapTextureSize,
                           TextureManagerTest::kMaxRectangleTextureSize,
                           kUseDefaultTextures));
    memory_tracker2_ = new CountingMemoryTracker;
    texture_manager2_.reset(
        new TextureManager(memory_tracker2_.get(),
                           feature_info_.get(),
                           TextureManagerTest::kMaxTextureSize,
                           TextureManagerTest::kMaxCubeMapTextureSize,
                           TextureManagerTest::kMaxRectangleTextureSize,
                           kUseDefaultTextures));
    TestHelper::SetupTextureManagerInitExpectations(
        gl_.get(), "", kUseDefaultTextures);
    texture_manager1_->Initialize();
    TestHelper::SetupTextureManagerInitExpectations(
        gl_.get(), "", kUseDefaultTextures);
    texture_manager2_->Initialize();
  }

  void TearDown() override {
    texture_manager2_->Destroy(false);
    texture_manager2_.reset();
    texture_manager1_->Destroy(false);
    texture_manager1_.reset();
    GpuServiceTest::TearDown();
  }

 protected:
  scoped_refptr<FeatureInfo> feature_info_;
  scoped_refptr<CountingMemoryTracker> memory_tracker1_;
  scoped_ptr<TextureManager> texture_manager1_;
  scoped_refptr<CountingMemoryTracker> memory_tracker2_;
  scoped_ptr<TextureManager> texture_manager2_;
};

TEST_F(SharedTextureTest, DeleteTextures) {
  scoped_refptr<TextureRef> ref1 = texture_manager1_->CreateTexture(10, 10);
  scoped_refptr<TextureRef> ref2 =
      texture_manager2_->Consume(20, ref1->texture());
  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(0);
  ref1 = NULL;
  texture_manager1_->RemoveTexture(10);
  testing::Mock::VerifyAndClearExpectations(gl_.get());

  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(1)
      .RetiresOnSaturation();
  ref2 = NULL;
  texture_manager2_->RemoveTexture(20);
  testing::Mock::VerifyAndClearExpectations(gl_.get());
}

TEST_F(SharedTextureTest, TextureSafetyAccounting) {
  EXPECT_FALSE(texture_manager1_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnclearedMips());
  EXPECT_FALSE(texture_manager2_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnclearedMips());

  // Newly created texture is renderable.
  scoped_refptr<TextureRef> ref1 = texture_manager1_->CreateTexture(10, 10);
  EXPECT_FALSE(texture_manager1_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnclearedMips());

  // Associate new texture ref to other texture manager, should account for it
  // too.
  scoped_refptr<TextureRef> ref2 =
      texture_manager2_->Consume(20, ref1->texture());
  EXPECT_FALSE(texture_manager2_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnclearedMips());

  // Make texture renderable but uncleared on one texture manager, should affect
  // other one.
  texture_manager1_->SetTarget(ref1.get(), GL_TEXTURE_2D);
  EXPECT_TRUE(texture_manager1_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnclearedMips());
  EXPECT_TRUE(texture_manager2_->HaveUnrenderableTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnclearedMips());

  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  0,
                                  GL_RGBA,
                                  1,
                                  1,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  false);
  EXPECT_FALSE(texture_manager1_->HaveUnrenderableTextures());
  EXPECT_TRUE(texture_manager1_->HaveUnsafeTextures());
  EXPECT_TRUE(texture_manager1_->HaveUnclearedMips());
  EXPECT_FALSE(texture_manager2_->HaveUnrenderableTextures());
  EXPECT_TRUE(texture_manager2_->HaveUnsafeTextures());
  EXPECT_TRUE(texture_manager2_->HaveUnclearedMips());

  // Make texture cleared on one texture manager, should affect other one.
  texture_manager1_->SetLevelCleared(ref1.get(), GL_TEXTURE_2D, 0, true);
  EXPECT_FALSE(texture_manager1_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager1_->HaveUnclearedMips());
  EXPECT_FALSE(texture_manager2_->HaveUnsafeTextures());
  EXPECT_FALSE(texture_manager2_->HaveUnclearedMips());

  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(1)
      .RetiresOnSaturation();
  texture_manager1_->RemoveTexture(10);
  texture_manager2_->RemoveTexture(20);
}

TEST_F(SharedTextureTest, FBOCompletenessCheck) {
  const GLenum kCompleteValue = GL_FRAMEBUFFER_COMPLETE;
  FramebufferManager framebuffer_manager1(1, 1);
  texture_manager1_->set_framebuffer_manager(&framebuffer_manager1);
  FramebufferManager framebuffer_manager2(1, 1);
  texture_manager2_->set_framebuffer_manager(&framebuffer_manager2);

  scoped_refptr<TextureRef> ref1 = texture_manager1_->CreateTexture(10, 10);
  framebuffer_manager1.CreateFramebuffer(10, 10);
  scoped_refptr<Framebuffer> framebuffer1 =
      framebuffer_manager1.GetFramebuffer(10);
  framebuffer1->AttachTexture(
      GL_COLOR_ATTACHMENT0, ref1.get(), GL_TEXTURE_2D, 0, 0);
  EXPECT_FALSE(framebuffer_manager1.IsComplete(framebuffer1.get()));
  EXPECT_NE(kCompleteValue, framebuffer1->IsPossiblyComplete());

  // Make FBO complete in manager 1.
  texture_manager1_->SetTarget(ref1.get(), GL_TEXTURE_2D);
  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  0,
                                  GL_RGBA,
                                  1,
                                  1,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  true);
  EXPECT_EQ(kCompleteValue, framebuffer1->IsPossiblyComplete());
  framebuffer_manager1.MarkAsComplete(framebuffer1.get());
  EXPECT_TRUE(framebuffer_manager1.IsComplete(framebuffer1.get()));

  // Share texture with manager 2.
  scoped_refptr<TextureRef> ref2 =
      texture_manager2_->Consume(20, ref1->texture());
  framebuffer_manager2.CreateFramebuffer(20, 20);
  scoped_refptr<Framebuffer> framebuffer2 =
      framebuffer_manager2.GetFramebuffer(20);
  framebuffer2->AttachTexture(
      GL_COLOR_ATTACHMENT0, ref2.get(), GL_TEXTURE_2D, 0, 0);
  EXPECT_FALSE(framebuffer_manager2.IsComplete(framebuffer2.get()));
  EXPECT_EQ(kCompleteValue, framebuffer2->IsPossiblyComplete());
  framebuffer_manager2.MarkAsComplete(framebuffer2.get());
  EXPECT_TRUE(framebuffer_manager2.IsComplete(framebuffer2.get()));

  // Change level for texture, both FBOs should be marked incomplete
  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  0,
                                  GL_RGBA,
                                  1,
                                  1,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  true);
  EXPECT_FALSE(framebuffer_manager1.IsComplete(framebuffer1.get()));
  EXPECT_EQ(kCompleteValue, framebuffer1->IsPossiblyComplete());
  framebuffer_manager1.MarkAsComplete(framebuffer1.get());
  EXPECT_TRUE(framebuffer_manager1.IsComplete(framebuffer1.get()));
  EXPECT_FALSE(framebuffer_manager2.IsComplete(framebuffer2.get()));
  EXPECT_EQ(kCompleteValue, framebuffer2->IsPossiblyComplete());
  framebuffer_manager2.MarkAsComplete(framebuffer2.get());
  EXPECT_TRUE(framebuffer_manager2.IsComplete(framebuffer2.get()));

  EXPECT_CALL(*gl_, DeleteFramebuffersEXT(1, _))
      .Times(2)
      .RetiresOnSaturation();
  framebuffer_manager1.RemoveFramebuffer(10);
  framebuffer_manager2.RemoveFramebuffer(20);
  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(1)
      .RetiresOnSaturation();
  texture_manager1_->RemoveTexture(10);
  texture_manager2_->RemoveTexture(20);
}

TEST_F(SharedTextureTest, Memory) {
  size_t initial_memory1 = memory_tracker1_->GetSize(MemoryTracker::kUnmanaged);
  size_t initial_memory2 = memory_tracker2_->GetSize(MemoryTracker::kUnmanaged);

  // Newly created texture is unrenderable.
  scoped_refptr<TextureRef> ref1 = texture_manager1_->CreateTexture(10, 10);
  texture_manager1_->SetTarget(ref1.get(), GL_TEXTURE_2D);
  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  0,
                                  GL_RGBA,
                                  10,
                                  10,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  false);

  EXPECT_LT(0u, ref1->texture()->estimated_size());
  EXPECT_EQ(initial_memory1 + ref1->texture()->estimated_size(),
            memory_tracker1_->GetSize(MemoryTracker::kUnmanaged));

  // Associate new texture ref to other texture manager, it doesn't account for
  // the texture memory, the first memory tracker still has it.
  scoped_refptr<TextureRef> ref2 =
      texture_manager2_->Consume(20, ref1->texture());
  EXPECT_EQ(initial_memory1 + ref1->texture()->estimated_size(),
            memory_tracker1_->GetSize(MemoryTracker::kUnmanaged));
  EXPECT_EQ(initial_memory2,
            memory_tracker2_->GetSize(MemoryTracker::kUnmanaged));

  // Delete the texture, memory should go to the remaining tracker.
  texture_manager1_->RemoveTexture(10);
  ref1 = NULL;
  EXPECT_EQ(initial_memory1,
            memory_tracker1_->GetSize(MemoryTracker::kUnmanaged));
  EXPECT_EQ(initial_memory2 + ref2->texture()->estimated_size(),
            memory_tracker2_->GetSize(MemoryTracker::kUnmanaged));

  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(1)
      .RetiresOnSaturation();
  ref2 = NULL;
  texture_manager2_->RemoveTexture(20);
  EXPECT_EQ(initial_memory2,
            memory_tracker2_->GetSize(MemoryTracker::kUnmanaged));
}

TEST_F(SharedTextureTest, Images) {
  scoped_refptr<TextureRef> ref1 = texture_manager1_->CreateTexture(10, 10);
  scoped_refptr<TextureRef> ref2 =
      texture_manager2_->Consume(20, ref1->texture());

  texture_manager1_->SetTarget(ref1.get(), GL_TEXTURE_2D);
  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  1,
                                  GL_RGBA,
                                  2,
                                  2,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  true);
  EXPECT_FALSE(ref1->texture()->HasImages());
  EXPECT_FALSE(ref2->texture()->HasImages());
  EXPECT_FALSE(texture_manager1_->HaveImages());
  EXPECT_FALSE(texture_manager2_->HaveImages());
  scoped_refptr<gfx::GLImage> image1(new gfx::GLImageStub);
  texture_manager1_->SetLevelImage(ref1.get(), GL_TEXTURE_2D, 1, image1.get());
  EXPECT_TRUE(ref1->texture()->HasImages());
  EXPECT_TRUE(ref2->texture()->HasImages());
  EXPECT_TRUE(texture_manager1_->HaveImages());
  EXPECT_TRUE(texture_manager2_->HaveImages());
  scoped_refptr<gfx::GLImage> image2(new gfx::GLImageStub);
  texture_manager1_->SetLevelImage(ref1.get(), GL_TEXTURE_2D, 1, image2.get());
  EXPECT_TRUE(ref1->texture()->HasImages());
  EXPECT_TRUE(ref2->texture()->HasImages());
  EXPECT_TRUE(texture_manager1_->HaveImages());
  EXPECT_TRUE(texture_manager2_->HaveImages());
  texture_manager1_->SetLevelInfo(ref1.get(),
                                  GL_TEXTURE_2D,
                                  1,
                                  GL_RGBA,
                                  2,
                                  2,
                                  1,
                                  0,
                                  GL_RGBA,
                                  GL_UNSIGNED_BYTE,
                                  true);
  EXPECT_FALSE(ref1->texture()->HasImages());
  EXPECT_FALSE(ref2->texture()->HasImages());
  EXPECT_FALSE(texture_manager1_->HaveImages());
  EXPECT_FALSE(texture_manager1_->HaveImages());

  EXPECT_CALL(*gl_, DeleteTextures(1, _))
      .Times(1)
      .RetiresOnSaturation();
  texture_manager1_->RemoveTexture(10);
  texture_manager2_->RemoveTexture(20);
}

}  // namespace gles2
}  // namespace gpu
