// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_imported_image.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// Invalid arguments must be rejected before any Vulkan call. The
// import pipeline itself is covered by DCompPresenterTest, which owns the
// Direct3D side of the shared texture.
TEST(VulkanImportedImageTest, RejectsInvalidArguments) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  HANDLE fake_handle = reinterpret_cast<HANDLE>(0x1);
  EXPECT_EQ(VulkanImportedImage::Import(manager.get(), nullptr, 100, 100),
            nullptr);
  EXPECT_EQ(VulkanImportedImage::Import(manager.get(), fake_handle, 0, 100),
            nullptr);
  EXPECT_EQ(VulkanImportedImage::Import(manager.get(), fake_handle, 100, 0),
            nullptr);
}

}  // namespace testing
}  // namespace flutter
