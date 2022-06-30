// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/raster_cache_key.h"
#include <optional>
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer.h"
namespace flutter {

//

std::optional<std::vector<uint64_t>> RasterCacheKeyID::LayerChildrenIds(
    Layer* layer) {
  auto& children_layers = layer->as_container_layer()->layers();
  auto children_count = children_layers.size();
  if (children_count == 0) {
    return std::nullopt;
  }
  std::vector<uint64_t> ids;
  std::transform(children_layers.begin(), children_layers.end(),
                 std::back_inserter(ids),
                 [](auto& layer) -> uint64_t { return layer->unique_id(); });
  return ids;
}

}  // namespace flutter
