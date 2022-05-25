// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layer_snapshot_store.h"

#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"

namespace flutter {

LayerSnapshotData::LayerSnapshotData(int64_t layer_unique_id,
                                     const fml::TimeDelta& duration,
                                     const sk_sp<SkData>& snapshot,
                                     const SkRect& bounds)
    : layer_unique_id_(layer_unique_id),
      duration_(duration),
      snapshot_(snapshot),
      bounds_(bounds) {}

void LayerSnapshotStore::Clear() {
  layer_snapshots_.clear();
}

void LayerSnapshotStore::Add(const LayerSnapshotData& data) {
  layer_snapshots_.push_back(data);
}

}  // namespace flutter
