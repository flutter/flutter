// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/shell/platform/android/image_lru.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(ImageLRU, CanStoreSingleImage) {
  auto image = DlImageSkia::Make(nullptr);
  ImageLRU image_lru;

  EXPECT_EQ(image_lru.FindImage(1), nullptr);

  image_lru.AddImage(image, 1);

  EXPECT_EQ(image_lru.FindImage(1), image);
}

TEST(ImageLRU, EvictsLRU) {
  auto image = DlImageSkia::Make(nullptr);
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
  auto image = DlImageSkia::Make(nullptr);
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
}

TEST(ImageLRU, RepeatedAccessUpdatesMRU) {
  auto image = DlImageSkia::Make(nullptr);
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
  auto image1 = DlImageSkia::Make(nullptr);
  auto image2 = DlImageSkia::Make(nullptr);
  ImageLRU image_lru;

  EXPECT_EQ(image_lru.AddImage(image1, 10), 0u);
  EXPECT_EQ(image_lru.FindImage(10), image1);

  // Re-inserting key 10 updates the image without eviction
  EXPECT_EQ(image_lru.AddImage(image2, 10), 0u);
  EXPECT_EQ(image_lru.FindImage(10), image2);
}

}  // namespace testing
}  // namespace flutter
