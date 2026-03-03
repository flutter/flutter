// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/graphics/texture.h"
#include "flutter/lib/ui/painting/dl_image_texture_registry.h"
#include "flutter/lib/ui/painting/testing/mocks.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockTexture : public Texture {
 public:
  explicit MockTexture(int64_t id) : Texture(id) {}
  ~MockTexture() override = default;

  void Paint(PaintContext& context,
             const DlRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override {}
  void MarkNewFrameAvailable() override {}
  void OnTextureUnregistered() override {}

  void OnGrContextCreated() override {}
  void OnGrContextDestroyed() override {}

  sk_sp<DlImage> GetTextureImage(PaintContext& context,
                                 const DlRect& bounds,
                                 bool freeze) override {
    return nullptr;
  }
};

TEST(DlImageTextureRegistryTest, BasicInfo) {
  MockSnapshotDelegate delegate;
  DlImageTextureRegistry dl_image(delegate.GetWeakPtr(), /*texture_id=*/1234,
                                  /*width=*/100, /*height=*/200);

  EXPECT_EQ(dl_image.GetSize().width, 100);
  EXPECT_EQ(dl_image.GetSize().height, 200);
  EXPECT_FALSE(dl_image.isOpaque());
  EXPECT_TRUE(dl_image.isTextureBacked());
  EXPECT_TRUE(dl_image.isUIThreadSafe());
  EXPECT_EQ(dl_image.GetApproximateByteSize(), 100u * 200u * 4u);
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenNoRegistry) {
  MockSnapshotDelegate delegate;
  EXPECT_CALL(delegate, GetTextureRegistry())
      .WillRepeatedly(::testing::Return(nullptr));
  DlImageTextureRegistry dl_image(delegate.GetWeakPtr(), /*texture_id=*/1234,
                                  /*width=*/100, /*height=*/200);

  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenTextureNotFound) {
  MockSnapshotDelegate delegate;
  auto registry = std::make_shared<TextureRegistry>();
  EXPECT_CALL(delegate, GetTextureRegistry())
      .WillRepeatedly(::testing::Return(registry));

  DlImageTextureRegistry dl_image(delegate.GetWeakPtr(), /*texture_id=*/1234,
                                  /*width=*/100, /*height=*/200);

  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);
}

TEST(DlImageTextureRegistryTest, ResolvesWhenTextureFound) {
  MockSnapshotDelegate delegate;
  auto registry = std::make_shared<TextureRegistry>();
  EXPECT_CALL(delegate, GetTextureRegistry())
      .WillRepeatedly(::testing::Return(registry));

  auto texture = std::shared_ptr<MockTexture>(new MockTexture(1234));
  registry->RegisterTexture(texture);

  EXPECT_CALL(delegate, GetGrContext())
      .WillRepeatedly(::testing::Return(nullptr));
  EXPECT_CALL(delegate, GetSnapshotDelegateAiksContext())
      .WillRepeatedly(::testing::Return(nullptr));

  DlImageTextureRegistry dl_image(delegate.GetWeakPtr(), /*texture_id=*/1234,
                                  /*width=*/100, /*height=*/200);

  // Still null because our MockTexture returns null, but it proves it didn't
  // crash.
  EXPECT_EQ(dl_image.skia_image(), nullptr);
  EXPECT_EQ(dl_image.impeller_texture(), nullptr);
}

}  // namespace testing
}  // namespace flutter
