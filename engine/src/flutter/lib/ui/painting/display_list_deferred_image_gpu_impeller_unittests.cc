// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/graphics/texture.h"  // Include for TextureRegistry
#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_impeller.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter {
namespace testing {
namespace {
class MockTextureRegistry : public TextureRegistry {
 public:
  MockTextureRegistry() = default;
  virtual ~MockTextureRegistry() = default;
};

class MockDlImage : public DlImage {
 public:
  MOCK_METHOD(DlISize, GetSize, (), (const, override));
  MOCK_METHOD(sk_sp<SkImage>, skia_image, (), (const, override));
  MOCK_METHOD(bool, isOpaque, (), (const, override));
  MOCK_METHOD(bool, isTextureBacked, (), (const, override));
  MOCK_METHOD(std::shared_ptr<impeller::Texture>,
              impeller_texture,
              (),
              (const, override));
  MOCK_METHOD(size_t, GetApproximateByteSize, (), (const, override));
  MOCK_METHOD(bool, isUIThreadSafe, (), (const, override));
};

class MockSnapshotDelegate : public SnapshotDelegate {
 public:
  MockSnapshotDelegate()
      : weak_factory_(this),
        texture_registry_(std::make_shared<MockTextureRegistry>()) {}
  virtual ~MockSnapshotDelegate() = default;

  MOCK_METHOD(std::unique_ptr<GpuImageResult>,
              MakeSkiaGpuImage,
              (sk_sp<DisplayList>, const SkImageInfo&),
              (override));
  MOCK_METHOD(std::shared_ptr<TextureRegistry>,
              GetTextureRegistry,
              (),
              (override));
  MOCK_METHOD(GrDirectContext*, GetGrContext, (), (override));
  MOCK_METHOD(void,
              MakeRasterSnapshot,
              (sk_sp<DisplayList>,
               DlISize,
               std::function<void(sk_sp<DlImage>)>),
              (override));
  MOCK_METHOD(sk_sp<DlImage>,
              MakeRasterSnapshotSync,
              (sk_sp<DisplayList>, DlISize),
              (override));
  MOCK_METHOD(sk_sp<SkImage>,
              ConvertToRasterImage,
              (sk_sp<SkImage>),
              (override));
  MOCK_METHOD(void,
              CacheRuntimeStage,
              (const std::shared_ptr<impeller::RuntimeStage>&),
              (override));
  MOCK_METHOD(bool, MakeRenderContextCurrent, (), (override));

  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> GetWeakPtr() {
    return weak_factory_.GetWeakPtr();
  }

  std::shared_ptr<MockTextureRegistry> GetMockTextureRegistry() {
    return texture_registry_;
  }

 private:
  fml::TaskRunnerAffineWeakPtrFactory<MockSnapshotDelegate> weak_factory_;
  std::shared_ptr<MockTextureRegistry> texture_registry_;
};

void PostTaskSync(fml::RefPtr<fml::TaskRunner> task_runner,
                  std::function<void()> task) {
  fml::AutoResetWaitableEvent latch;
  task_runner->PostTask([&latch, &task]() {
    task();
    latch.Signal();
  });
  latch.Wait();
}

}  // namespace

TEST(DlDeferredImageGPUImpeller, GetSize) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();
  const DlISize size = {100, 200};
  flutter::DisplayListBuilder builder;

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;
  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    // Set up the mock to return the internal texture_registry_.
    ON_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillByDefault(
            ::testing::Return(snapshot_delegate->GetMockTextureRegistry()));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  auto image = DlDeferredImageGPUImpeller::Make(
      builder.Build(), size, snapshot_delegate_weak_ptr, task_runner);
  ASSERT_EQ(image->GetSize(), size);

  PostTaskSync(task_runner, [&]() { snapshot_delegate.reset(); });
}

TEST(DlDeferredImageGPUImpeller, TrashesDisplayList) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();
  const DlISize size = {100, 200};
  flutter::DisplayListBuilder builder;

  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;
  PostTaskSync(task_runner, [&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    // Set up the mock to return the internal texture_registry_.
    ON_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillByDefault(
            ::testing::Return(snapshot_delegate->GetMockTextureRegistry()));

    auto mock_image = sk_make_sp<MockDlImage>();
    impeller::TextureDescriptor desc;
    desc.size = {1, 1};
    auto mock_texture = std::make_shared<impeller::testing::MockTexture>(desc);
    EXPECT_CALL(*mock_image, impeller_texture)
        .WillOnce(::testing::Return(mock_texture));
    EXPECT_CALL(*snapshot_delegate,
                MakeRasterSnapshotSync(::testing::_, ::testing::_))
        .WillOnce(::testing::Return(mock_image));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  // Pause raster thread.
  fml::AutoResetWaitableEvent latch;
  task_runner->PostTask([&latch]() { latch.Wait(); });

  auto image = DlDeferredImageGPUImpeller::Make(
      builder.Build(), size, snapshot_delegate_weak_ptr, task_runner);

  EXPECT_FALSE(image->impeller_texture());
  EXPECT_TRUE(image->wrapper_->display_list_);

  // Unpause raster thread.
  latch.Signal();

  PostTaskSync(task_runner, [&]() {
    EXPECT_TRUE(image->impeller_texture());
    EXPECT_FALSE(image->wrapper_->display_list_);
    snapshot_delegate.reset();
  });
}

}  // namespace testing
}  // namespace flutter
