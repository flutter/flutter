// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/shell/platform/android/image_lru.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkSurface.h"

#include <thread>
#include <vector>

namespace flutter {
namespace testing {

namespace {

sk_sp<flutter::DlImage> MakeTestImage(int width = 2, int height = 2) {
  SkImageInfo info = SkImageInfo::MakeN32Premul(width, height);
  sk_sp<SkSurface> surface = SkSurfaces::Raster(info);
  if (!surface) {
    return nullptr;
  }
  return DlImageSkia::Make(surface->makeImageSnapshot());
}

}  // namespace

TEST(ImageLRU, CanStoreSingleImage) {
  auto image = MakeTestImage(1, 1);
  ASSERT_NE(image, nullptr);
  ImageLRU image_lru;

  EXPECT_EQ(image_lru.FindImage(1), nullptr);

  image_lru.AddImage(image, 1);

  EXPECT_EQ(image_lru.FindImage(1), image);
}

TEST(ImageLRU, EvictsLRU) {
  auto image = MakeTestImage(2, 2);
  ASSERT_NE(image, nullptr);
  ImageLRU image_lru;

  // Fill up the cache, nothing is removed
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.AddImage(image, i + 1), 0u);
  }
  // Confirm each image is in the cache. This should keep the LRU
  // order the same.
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.FindImage(i + 1), image);
  }

  // Insert new image and verify least recently used was removed.
  EXPECT_EQ(image_lru.AddImage(image, 100), 1u);
}

TEST(ImageLRU, CanClear) {
  auto image = MakeTestImage(3, 3);
  ASSERT_NE(image, nullptr);
  ImageLRU image_lru;

  // Fill up the cache, nothing is removed
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.AddImage(image, i + 1), 0u);
  }
  image_lru.Clear();

  // Expect no cache entries.
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.FindImage(i + 1), nullptr);
  }
}

TEST(ImageLRU, NullKeyReturnsNullptr) {
  ImageLRU image_lru;
  EXPECT_EQ(image_lru.FindImage(std::nullopt), nullptr);
  EXPECT_EQ(image_lru.FindImage(0u), nullptr);
}

TEST(ImageLRU, RepeatedAccessUpdatesMRU) {
  auto image = MakeTestImage(4, 4);
  ASSERT_NE(image, nullptr);
  ImageLRU image_lru;

  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.AddImage(image, i + 1), 0u);
  }

  // Access key 1, making it MRU (most recently used)
  EXPECT_EQ(image_lru.FindImage(1), image);

  // Now key 2 should be the LRU, so inserting a new key evicts 2 instead of 1
  EXPECT_EQ(image_lru.AddImage(image, 999), 2u);
  EXPECT_EQ(image_lru.FindImage(1), image);
  EXPECT_EQ(image_lru.FindImage(2), nullptr);
}

TEST(ImageLRU, UpdateExistingKey) {
  auto image1 = MakeTestImage(5, 5);
  auto image2 = MakeTestImage(6, 6);
  ASSERT_NE(image1, nullptr);
  ASSERT_NE(image2, nullptr);
  ASSERT_NE(image1, image2);
  ImageLRU image_lru;

  EXPECT_EQ(image_lru.AddImage(image1, 10), 0u);
  EXPECT_EQ(image_lru.FindImage(10), image1);

  // Re-inserting key 10 updates the image without eviction
  EXPECT_EQ(image_lru.AddImage(image2, 10), 0u);
  EXPECT_EQ(image_lru.FindImage(10), image2);
}

TEST(ImageLRU, MultithreadedConcurrentAccess) {
  ImageLRU image_lru;
  auto test_image = MakeTestImage(8, 8);
  ASSERT_NE(test_image, nullptr);

  std::vector<std::thread> workers;
  for (int t = 0; t < 8; ++t) {
    workers.emplace_back([&image_lru, test_image, t]() {
      for (int i = 1; i <= 50; ++i) {
        uint64_t key = (t * 100) + i;
        image_lru.AddImage(test_image, key);
        auto found = image_lru.FindImage(key);
        if (found) {
          EXPECT_EQ(found, test_image);
        }
      }
    });
  }
  for (auto& w : workers) {
    w.join();
  }
}

}  // namespace testing
}  // namespace flutter
