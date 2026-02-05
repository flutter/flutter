// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/graphics/texture.h"  // Include for TextureRegistry
#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/thread.h"
#include "flutter/lib/ui/painting/display_list_deferred_image_gpu_impeller.h"
#include "flutter/lib/ui/painting/testing/mocks.h"
#include "flutter/testing/post_task_sync.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter {
namespace testing {

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
      builder.Build(), size, SnapshotPixelFormat::kDontCare,
      snapshot_delegate_weak_ptr, task_runner);
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
    EXPECT_CALL(
        *snapshot_delegate,
        MakeRasterSnapshotSync(::testing::_, ::testing::_, ::testing::_))
        .WillOnce(::testing::Return(mock_image));
    snapshot_delegate_weak_ptr = snapshot_delegate->GetWeakPtr();
  });

  sk_sp<DlDeferredImageGPUImpeller> image;
  // Pause raster thread.
  fml::AutoResetWaitableEvent latch;
  task_runner->PostTask([&latch, &image]() {
    latch.Wait();
    EXPECT_FALSE(image->impeller_texture());
  });

  image = DlDeferredImageGPUImpeller::Make(
      builder.Build(), size, SnapshotPixelFormat::kDontCare,
      snapshot_delegate_weak_ptr, task_runner);

  // Unpause raster thread.
  latch.Signal();

  PostTaskSync(task_runner, [&]() {
    EXPECT_TRUE(image->impeller_texture());
    snapshot_delegate.reset();
  });
}

}  // namespace testing
}  // namespace flutter
