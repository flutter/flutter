// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYER_SNAPSHOT_STORE_H_
#define FLUTTER_FLOW_LAYER_SNAPSHOT_STORE_H_

#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_delta.h"

#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkSurfaceCharacterization.h"
#include "third_party/skia/include/utils/SkBase64.h"

namespace flutter {

/// Container for snapshot data pertaining to a given layer. A layer is
/// identified by it's unique id.
class LayerSnapshotData {
 public:
  LayerSnapshotData(int64_t layer_unique_id,
                    const fml::TimeDelta& duration,
                    const sk_sp<SkData>& snapshot,
                    const SkRect& bounds);

  ~LayerSnapshotData() = default;

  int64_t GetLayerUniqueId() const { return layer_unique_id_; }

  fml::TimeDelta GetDuration() const { return duration_; }

  sk_sp<SkData> GetSnapshot() const { return snapshot_; }

  SkRect GetBounds() const { return bounds_; }

 private:
  const int64_t layer_unique_id_;
  const fml::TimeDelta duration_;
  const sk_sp<SkData> snapshot_;
  const SkRect bounds_;
};

/// Collects snapshots of layers during frame rasterization.
class LayerSnapshotStore {
 public:
  typedef std::vector<LayerSnapshotData> Snapshots;

  LayerSnapshotStore() = default;

  ~LayerSnapshotStore() = default;

  /// Clears all the stored snapshots.
  void Clear();

  /// Adds snapshots for a given layer. `duration` marks the time taken to
  /// rasterize this one layer.
  void Add(const LayerSnapshotData& data);

  // Returns the number of snapshots collected.
  size_t Size() const { return layer_snapshots_.size(); }

  // make this class iterable
  Snapshots::iterator begin() { return layer_snapshots_.begin(); }
  Snapshots::iterator end() { return layer_snapshots_.end(); }

 private:
  Snapshots layer_snapshots_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerSnapshotStore);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYER_SNAPSHOT_STORE_H_
