// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "impeller/entity/contents/gradient_texture_cache.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/playground/playground_test.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

namespace impeller {
namespace testing {

using GradientTextureCacheTest = EntityPlayground;
INSTANTIATE_PLAYGROUND_SUITE(GradientTextureCacheTest);

TEST_P(GradientTextureCacheTest, ReusesTextureForIdenticalGradient) {
  GradientTextureCache cache;
  std::vector<Color> colors = {Color::Red(), Color::Blue()};
  std::vector<Scalar> stops = {0.0f, 1.0f};

  std::shared_ptr<Texture> first = cache.Lookup(GetContext(), colors, stops);
  ASSERT_NE(first, nullptr);
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 1u);

  // An equal but distinct set of colors and stops must hit the same entry.
  std::vector<Color> other_colors = {Color::Red(), Color::Blue()};
  std::vector<Scalar> other_stops = {0.0f, 1.0f};
  std::shared_ptr<Texture> second =
      cache.Lookup(GetContext(), other_colors, other_stops);

  EXPECT_EQ(first, second);
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 1u);
}

TEST_P(GradientTextureCacheTest, DifferentGradientsGetDifferentTextures) {
  GradientTextureCache cache;
  std::vector<Scalar> stops = {0.0f, 1.0f};

  std::shared_ptr<Texture> red_blue = cache.Lookup(
      GetContext(), std::vector<Color>{Color::Red(), Color::Blue()}, stops);
  std::shared_ptr<Texture> red_green = cache.Lookup(
      GetContext(), std::vector<Color>{Color::Red(), Color::Green()}, stops);

  ASSERT_NE(red_blue, nullptr);
  ASSERT_NE(red_green, nullptr);
  EXPECT_NE(red_blue, red_green);
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 2u);

  // Differing only in stops is also a distinct gradient.
  std::shared_ptr<Texture> shifted_stops = cache.Lookup(
      GetContext(), std::vector<Color>{Color::Red(), Color::Blue()},
      std::vector<Scalar>{0.0f, 0.5f});
  EXPECT_NE(red_blue, shifted_stops);
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 3u);
}

TEST_P(GradientTextureCacheTest, EvictsEntriesUnusedForAFrame) {
  GradientTextureCache cache;
  std::vector<Color> colors = {Color::Red(), Color::Blue()};
  std::vector<Scalar> stops = {0.0f, 1.0f};

  cache.MarkFrameStart();
  std::shared_ptr<Texture> texture = cache.Lookup(GetContext(), colors, stops);
  ASSERT_NE(texture, nullptr);
  cache.MarkFrameEnd();
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 1u);

  // Used again, so it survives the frame.
  cache.MarkFrameStart();
  EXPECT_EQ(cache.Lookup(GetContext(), colors, stops), texture);
  cache.MarkFrameEnd();
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 1u);

  // Unused for a whole frame, so it is dropped.
  cache.MarkFrameStart();
  cache.MarkFrameEnd();
  EXPECT_EQ(cache.GetCacheSizeForTesting(), 0u);
}

}  // namespace testing
}  // namespace impeller
