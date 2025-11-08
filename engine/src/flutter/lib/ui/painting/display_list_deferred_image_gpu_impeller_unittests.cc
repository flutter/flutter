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

namespace flutter {
namespace testing {
namespace {
class MockTextureRegistry : public TextureRegistry {
 public:
  MockTextureRegistry() = default;
  virtual ~MockTextureRegistry() = default;
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
}  // namespace

TEST(DlDeferredImageGPUImpeller, GetSize) {
  fml::Thread raster_thread("raster");
  auto task_runner = raster_thread.GetTaskRunner();
  const DlISize size = {100, 200};
  flutter::DisplayListBuilder builder;

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<MockSnapshotDelegate> snapshot_delegate;
  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_weak_ptr;
  task_runner->PostTask([&]() {
    snapshot_delegate = std::make_unique<MockSnapshotDelegate>();
    // Set up the mock to return the internal texture_registry_.
    ON_CALL(*snapshot_delegate, GetTextureRegistry())
        .WillByDefault(
            ::testing::Return(snapshot_delegate->GetMockTextureRegistry()));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
    latch.Signal();
  });
  latch.Wait();

  auto image = DlDeferredImageGPUImpeller::Make(
      builder.Build(), size, snapshot_delegate_weak_ptr, task_runner);
  ASSERT_EQ(image->GetSize(), size);

  fml::AutoResetWaitableEvent destroy_latch;
  task_runner->PostTask([&]() {
    snapshot_delegate.reset();
    destroy_latch.Signal();
  });
  destroy_latch.Wait();
}

}  // namespace testing
}  // namespace flutter
