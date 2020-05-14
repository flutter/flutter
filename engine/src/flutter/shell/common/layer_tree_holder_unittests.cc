// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <functional>
#include <future>
#include <memory>

#include "flutter/shell/common/layer_tree_holder.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(LayerTreeHolder, EmptyOnInit) {
  const LayerTreeHolder layer_tree_holder;
  ASSERT_TRUE(layer_tree_holder.IsEmpty());
}

TEST(LayerTreeHolder, PutOneAndGet) {
  LayerTreeHolder layer_tree_holder;
  const auto frame_size = SkISize::Make(64, 64);
  auto layer_tree = std::make_unique<LayerTree>(frame_size, 100.0f, 1.0f);
  layer_tree_holder.PushIfNewer(std::move(layer_tree));
  ASSERT_FALSE(layer_tree_holder.IsEmpty());
  const auto stored = layer_tree_holder.Pop();
  ASSERT_EQ(stored->frame_size(), frame_size);
  ASSERT_TRUE(layer_tree_holder.IsEmpty());
}

TEST(LayerTreeHolder, PutMultiGetsLatest) {
  const auto build_begin = fml::TimePoint::Now();
  const auto target_time_1 = build_begin + fml::TimeDelta::FromSeconds(2);
  const auto target_time_2 = build_begin + fml::TimeDelta::FromSeconds(5);

  LayerTreeHolder layer_tree_holder;
  const auto frame_size_1 = SkISize::Make(64, 64);
  auto layer_tree_1 = std::make_unique<LayerTree>(frame_size_1, 100.0f, 1.0f);
  layer_tree_1->RecordBuildTime(build_begin, target_time_1);
  layer_tree_holder.PushIfNewer(std::move(layer_tree_1));

  const auto frame_size_2 = SkISize::Make(128, 128);
  auto layer_tree_2 = std::make_unique<LayerTree>(frame_size_2, 100.0f, 1.0f);
  layer_tree_2->RecordBuildTime(build_begin, target_time_2);
  layer_tree_holder.PushIfNewer(std::move(layer_tree_2));

  const auto stored = layer_tree_holder.Pop();
  ASSERT_EQ(stored->frame_size(), frame_size_2);
  ASSERT_TRUE(layer_tree_holder.IsEmpty());
}

TEST(LayerTreeHolder, RetainsOlderIfNewerFrameHasEarlierTargetTime) {
  const auto build_begin = fml::TimePoint::Now();
  const auto target_time_1 = build_begin + fml::TimeDelta::FromSeconds(5);
  const auto target_time_2 = build_begin + fml::TimeDelta::FromSeconds(2);

  LayerTreeHolder layer_tree_holder;
  const auto frame_size_1 = SkISize::Make(64, 64);
  auto layer_tree_1 = std::make_unique<LayerTree>(frame_size_1, 100.0f, 1.0f);
  layer_tree_1->RecordBuildTime(build_begin, target_time_1);
  layer_tree_holder.PushIfNewer(std::move(layer_tree_1));

  const auto frame_size_2 = SkISize::Make(128, 128);
  auto layer_tree_2 = std::make_unique<LayerTree>(frame_size_2, 100.0f, 1.0f);
  layer_tree_2->RecordBuildTime(build_begin, target_time_2);
  layer_tree_holder.PushIfNewer(std::move(layer_tree_2));

  const auto stored = layer_tree_holder.Pop();
  ASSERT_EQ(stored->frame_size(), frame_size_1);
  ASSERT_TRUE(layer_tree_holder.IsEmpty());
}

}  // namespace testing
}  // namespace flutter
