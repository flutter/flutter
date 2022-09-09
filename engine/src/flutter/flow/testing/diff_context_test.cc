// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "diff_context_test.h"
#include "flutter/display_list/display_list_builder.h"

namespace flutter {
namespace testing {

DiffContextTest::DiffContextTest()
    : unref_queue_(fml::MakeRefCounted<SkiaUnrefQueue>(
          GetCurrentTaskRunner(),
          fml::TimeDelta::FromSeconds(0))) {}

Damage DiffContextTest::DiffLayerTree(MockLayerTree& layer_tree,
                                      const MockLayerTree& old_layer_tree,
                                      const SkIRect& additional_damage,
                                      int horizontal_clip_alignment,
                                      int vertical_clip_alignment,
                                      bool use_raster_cache) {
  FML_CHECK(layer_tree.size() == old_layer_tree.size());

  DiffContext dc(layer_tree.size(), 1, layer_tree.paint_region_map(),
                 old_layer_tree.paint_region_map(), use_raster_cache);
  dc.PushCullRect(
      SkRect::MakeIWH(layer_tree.size().width(), layer_tree.size().height()));
  layer_tree.root()->Diff(&dc, old_layer_tree.root());
  return dc.ComputeDamage(additional_damage, horizontal_clip_alignment,
                          vertical_clip_alignment);
}

sk_sp<DisplayList> DiffContextTest::CreateDisplayList(const SkRect& bounds,
                                                      SkColor color) {
  DisplayListBuilder builder;
  builder.setColor(color);
  builder.drawRect(bounds);
  return builder.Build();
}

std::shared_ptr<DisplayListLayer> DiffContextTest::CreateDisplayListLayer(
    sk_sp<DisplayList> display_list,
    const SkPoint& offset) {
  return std::make_shared<DisplayListLayer>(
      offset, SkiaGPUObject(display_list, unref_queue()), false, false);
}

std::shared_ptr<ContainerLayer> DiffContextTest::CreateContainerLayer(
    std::initializer_list<std::shared_ptr<Layer>> layers) {
  auto res = std::make_shared<ContainerLayer>();
  for (const auto& l : layers) {
    res->Add(l);
  }
  return res;
}

std::shared_ptr<OpacityLayer> DiffContextTest::CreateOpacityLater(
    std::initializer_list<std::shared_ptr<Layer>> layers,
    SkAlpha alpha,
    const SkPoint& offset) {
  auto res = std::make_shared<OpacityLayer>(alpha, offset);
  for (const auto& l : layers) {
    res->Add(l);
  }
  return res;
}

}  // namespace testing
}  // namespace flutter
