// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <vector>

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/shell/platform/android/image_lru.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(ImageLRU, CanStoreSingleImage) {
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  ImageLRU image_lru;

  EXPECT_EQ(image_lru.FindImage(1, {}), nullptr);

  image_lru.AddImage(image, 1);

  EXPECT_EQ(image_lru.FindImage(1, {}), image);
}

TEST(ImageLRU, EvictsLRU) {
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  ImageLRU image_lru;

  // Fill up the cache, nothing is removed
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.AddImage(image, i + 1), 0u);
  }
  // Confirm each image is in the cache. This should keep the LRU
  // order the same.
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.FindImage(i + 1, {}), image);
  }

  // Insert new image and verify least recently used was removed.
  EXPECT_EQ(image_lru.AddImage(image, 100), 1u);
}

TEST(ImageLRU, CacheHitPromotesImageBeforeEviction) {
  ImageLRU cache;
  std::array<sk_sp<DlImage>, kImageReaderSwapchainSize> images;
  for (HardwareBufferKey key = 1; key <= kImageReaderSwapchainSize; key++) {
    images[key - 1] = sk_make_sp<DlImageSkia>(nullptr);
    cache.AddImage(images[key - 1], key);
  }

  EXPECT_EQ(cache.FindImage(1, {}), images[0]);
  EXPECT_EQ(cache.FindImage(1, {}), images[0]);
  auto new_image = sk_make_sp<DlImageSkia>(nullptr);
  const HardwareBufferKey next_key = kImageReaderSwapchainSize + 1;
  EXPECT_EQ(cache.AddImage(new_image, next_key), 2u);
  EXPECT_EQ(cache.FindImage(2, {}), nullptr);
  EXPECT_TRUE(images[1]->unique());
  EXPECT_EQ(cache.FindImage(1, {}), images[0]);
  EXPECT_EQ(cache.FindImage(next_key, {}), new_image);
  for (HardwareBufferKey key = 3; key <= kImageReaderSwapchainSize; key++) {
    EXPECT_EQ(cache.FindImage(key, {}), images[key - 1]);
  }
}

TEST(ImageLRU, CanClear) {
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  ImageLRU image_lru;

  // Fill up the cache, nothing is removed
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.AddImage(image, i + 1), 0u);
  }
  image_lru.Clear();

  // Expect no cache entries.
  for (auto i = 0u; i < kImageReaderSwapchainSize; i++) {
    EXPECT_EQ(image_lru.FindImage(i + 1, {}), nullptr);
  }
}

TEST(ImageLRU, RetainsAndroidBufferQueueWorkingSet) {
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  ImageLRU image_lru;
  constexpr HardwareBufferKey kAndroidBufferQueueMaxSlots = 64u;

  for (HardwareBufferKey key = 1u; key <= kAndroidBufferQueueMaxSlots; key++) {
    EXPECT_EQ(image_lru.AddImage(image, key), 0u);
  }
  for (HardwareBufferKey key = 1u; key <= kAndroidBufferQueueMaxSlots; key++) {
    EXPECT_EQ(image_lru.FindImage(key, {}), image);
  }

  const HardwareBufferKey next_key = kAndroidBufferQueueMaxSlots + 1u;
  EXPECT_EQ(image_lru.AddImage(image, next_key), 1u);
  EXPECT_EQ(image_lru.FindImage(1u, {}), nullptr);
  EXPECT_EQ(image_lru.FindImage(next_key, {}), image);
}

TEST(ImageLRU, RetainsImagesOnMissWithUnchangedBufferConfiguration) {
  const AHardwareBuffer_Desc descriptor = {
      .width = 1920,
      .height = 1080,
      .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM};
  ImageLRU cache;
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  EXPECT_EQ(cache.FindImage(1, descriptor), nullptr);
  cache.AddImage(image, 1);

  EXPECT_EQ(
      cache.FindImage(2, descriptor, [](HardwareBufferKey) { ADD_FAILURE(); }),
      nullptr);
  EXPECT_EQ(cache.FindImage(1, descriptor), image);
}

TEST(ImageLRU, InvalidatesChangedBufferConfiguration) {
  const AHardwareBuffer_Desc original = {
      .width = 100,
      .height = 200,
      .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM};
  for (const auto changed : {
           AHardwareBuffer_Desc{
               .width = 200, .height = 200, .format = original.format},
           AHardwareBuffer_Desc{
               .width = 100, .height = 100, .format = original.format},
           AHardwareBuffer_Desc{
               .width = 100,
               .height = 200,
               .format = AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM},
       }) {
    ImageLRU cache;
    auto image = sk_make_sp<DlImageSkia>(nullptr);
    EXPECT_EQ(cache.FindImage(1, original), nullptr);
    cache.AddImage(image, 1);
    cache.AddImage(image, 2);
    EXPECT_FALSE(image->unique());

    std::vector<HardwareBufferKey> evicted;
    EXPECT_EQ(
        cache.FindImage(3, changed,
                        [&](HardwareBufferKey key) { evicted.push_back(key); }),
        nullptr);
    EXPECT_THAT(evicted, ::testing::UnorderedElementsAre(1u, 2u));
    EXPECT_TRUE(image->unique());
    cache.AddImage(image, 3);
    EXPECT_EQ(cache.FindImage(3, changed), image);
    EXPECT_EQ(cache.FindImage(1, changed), nullptr);
    EXPECT_EQ(cache.FindImage(2, changed), nullptr);
  }
}

TEST(ImageLRU, RetainsActiveBuffersAcrossManyFrames) {
  for (const size_t pool_size : {19u, 31u, 64u}) {
    SCOPED_TRACE(pool_size);
    ImageLRU cache;
    auto image = sk_make_sp<DlImageSkia>(nullptr);
    for (HardwareBufferKey key = 1; key <= pool_size; key++) {
      EXPECT_EQ(cache.FindImage(key, {}), nullptr);
      cache.AddImage(image, key);
    }
    for (size_t frame = 0; frame < 8 * kImageReaderSwapchainSize; frame++) {
      EXPECT_EQ(cache.FindImage(1 + frame % pool_size, {},
                                [](HardwareBufferKey) { ADD_FAILURE(); }),
                image);
    }
  }
}

TEST(ImageLRU, ExpiresUnusedBuffersEvenWhenEveryFrameHits) {
  ImageLRU cache;
  auto old_image = sk_make_sp<DlImageSkia>(nullptr);
  auto active_image = sk_make_sp<DlImageSkia>(nullptr);
  cache.FindImage(1, {});
  cache.AddImage(old_image, 1);
  cache.FindImage(2, {});
  cache.AddImage(active_image, 2);
  for (size_t frame = 2; frame < 2 * kImageReaderSwapchainSize; frame++) {
    EXPECT_EQ(cache.FindImage(2, {}, [](HardwareBufferKey) { ADD_FAILURE(); }),
              active_image);
  }
  EXPECT_FALSE(old_image->unique());
  std::vector<HardwareBufferKey> evicted;
  EXPECT_EQ(cache.FindImage(
                2, {}, [&](HardwareBufferKey key) { evicted.push_back(key); }),
            active_image);
  EXPECT_EQ(evicted, (std::vector<HardwareBufferKey>{1}));
  EXPECT_TRUE(old_image->unique());
  EXPECT_EQ(cache.FindImage(1, {}), nullptr);
}

TEST(ImageLRU, ExpiresReplacedPoolAtSameSize) {
  ImageLRU cache;
  auto old_image = sk_make_sp<DlImageSkia>(nullptr);
  auto new_image = sk_make_sp<DlImageSkia>(nullptr);
  std::vector<HardwareBufferKey> evicted;
  auto on_evict = [&](HardwareBufferKey key) { evicted.push_back(key); };
  for (HardwareBufferKey key = 1; key <= 31; key++) {
    cache.FindImage(key, {}, on_evict);
    cache.AddImage(old_image, key);
  }
  for (HardwareBufferKey key = 32; key <= 62; key++) {
    cache.FindImage(key, {}, on_evict);
    cache.AddImage(new_image, key);
  }
  EXPECT_TRUE(evicted.empty());
  EXPECT_FALSE(old_image->unique());
  for (size_t frame = 0; frame < 2 * kImageReaderSwapchainSize; frame++) {
    EXPECT_EQ(cache.FindImage(32 + frame % 31, {}, on_evict), new_image);
  }
  ASSERT_EQ(evicted.size(), 31u);
  for (size_t i = 0; i < evicted.size(); i++) {
    EXPECT_EQ(evicted[i], i + 1);
  }
  EXPECT_TRUE(old_image->unique());
  // Expiration leaves reusable empty slots, rather than evicting active images.
  EXPECT_EQ(cache.AddImage(new_image, 63), 0u);
  EXPECT_EQ(cache.FindImage(63, {}), new_image);
}

TEST(ImageLRU, FramesWithoutBufferIDsStillExpireOldImages) {
  ImageLRU cache;
  auto image = sk_make_sp<DlImageSkia>(nullptr);
  cache.FindImage(1, {});
  cache.AddImage(image, 1);
  for (size_t frame = 0; frame < 2 * kImageReaderSwapchainSize; frame++) {
    EXPECT_EQ(cache.FindImage(std::nullopt, {}), nullptr);
  }
  EXPECT_TRUE(image->unique());
}

}  // namespace testing
}  // namespace flutter
