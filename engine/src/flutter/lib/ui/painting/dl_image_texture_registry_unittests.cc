// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/painting/dl_image_texture_registry.h"
#include "flutter/lib/ui/painting/testing/mocks.h"
#include "flutter/testing/post_task_sync.h"
#include "gtest/gtest.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

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
    return dl_image;
  }

  sk_sp<DlImage> dl_image;
};

TEST(DlImageTextureRegistryTest, BasicInfo) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;

  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  auto dl_image = DlImageTextureRegistry::Make(snapshot_delegate_weak_ptr,
                                               task_runner, /*texture_id=*/1234,
                                               /*width=*/100, /*height=*/200);

  EXPECT_EQ(dl_image->GetSize().width, 100);
  EXPECT_EQ(dl_image->GetSize().height, 200);
  EXPECT_FALSE(dl_image->isOpaque());
  EXPECT_TRUE(dl_image->isTextureBacked());
  EXPECT_TRUE(dl_image->isUIThreadSafe());
  EXPECT_GE(dl_image->GetApproximateByteSize(), 100u * 200u * 4u);

  PostTaskSync(task_runner, [&]() { snapshot_delegate.reset(); });
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenNoRegistry) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;

  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    EXPECT_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillRepeatedly(::testing::Return(nullptr));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  auto dl_image = DlImageTextureRegistry::Make(snapshot_delegate_weak_ptr,
                                               task_runner, /*texture_id=*/1234,
                                               /*width=*/100, /*height=*/200);

  // We need to wait for the posted task to complete. We can just post a sync
  // task.
  PostTaskSync(task_runner, []() {});

  EXPECT_EQ(dl_image->impeller_texture(), nullptr);

  PostTaskSync(task_runner, [&]() { snapshot_delegate.reset(); });
}

TEST(DlImageTextureRegistryTest, ResolvesToNullWhenTextureNotFound) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;

  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    auto registry = std::make_shared<TextureRegistry>();
    EXPECT_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillRepeatedly(::testing::Return(registry));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  auto dl_image = DlImageTextureRegistry::Make(snapshot_delegate_weak_ptr,
                                               task_runner, /*texture_id=*/1234,
                                               /*width=*/100, /*height=*/200);

  PostTaskSync(task_runner, []() {});

  EXPECT_EQ(dl_image->impeller_texture(), nullptr);

  PostTaskSync(task_runner, [&]() { snapshot_delegate.reset(); });
}

TEST(DlImageTextureRegistryTest, ResolvesWhenTextureFound) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;

  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    auto registry = std::make_shared<TextureRegistry>();
    EXPECT_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillRepeatedly(::testing::Return(registry));

    auto texture = std::shared_ptr<MockTexture>(new MockTexture(1234));

    auto mock_dl_image = sk_make_sp<MockDlImage>();
    impeller::TextureDescriptor desc;
    desc.size = {1, 1};
    auto impeller_texture =
        std::make_shared<impeller::testing::MockTexture>(desc);
    EXPECT_CALL(*mock_dl_image, impeller_texture)
        .WillRepeatedly(::testing::Return(impeller_texture));
    texture->dl_image = mock_dl_image;

    registry->RegisterTexture(texture);

    EXPECT_CALL(*snapshot_delegate, GetGrContext())
        .WillRepeatedly(::testing::Return(nullptr));

    auto dummy_aiks = std::shared_ptr<impeller::AiksContext>(
        reinterpret_cast<impeller::AiksContext*>(1),
        [](impeller::AiksContext*) {});
    EXPECT_CALL(*snapshot_delegate, GetSnapshotDelegateAiksContext())
        .WillRepeatedly(::testing::Return(dummy_aiks));

    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  auto dl_image = DlImageTextureRegistry::Make(snapshot_delegate_weak_ptr,
                                               task_runner, /*texture_id=*/1234,
                                               /*width=*/100, /*height=*/200);

  PostTaskSync(task_runner, []() {});

  EXPECT_NE(dl_image->impeller_texture(), nullptr);

  PostTaskSync(task_runner, [&]() { snapshot_delegate.reset(); });
}

}  // namespace testing
}  // namespace flutter
