// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_KEY_H_
#define FLUTTER_FLOW_RASTER_CACHE_KEY_H_

#include <unordered_map>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace flutter {

enum class RasterCacheKeyType { kLayer, kPicture, kDisplayList };

enum class RasterCacheKeyKind { kLayerMetrics, kPictureMetrics };

class RasterCacheKey {
 public:
  RasterCacheKey(uint64_t id, RasterCacheKeyType type, const SkMatrix& ctm)
      : id_(id), type_(type), matrix_(ctm) {
    matrix_[SkMatrix::kMTransX] = 0;
    matrix_[SkMatrix::kMTransY] = 0;
  }

  uint64_t id() const { return id_; }
  RasterCacheKeyType type() const { return type_; }
  const SkMatrix& matrix() const { return matrix_; }

  RasterCacheKeyKind kind() const {
    switch (type_) {
      case RasterCacheKeyType::kPicture:
      case RasterCacheKeyType::kDisplayList:
        return RasterCacheKeyKind::kPictureMetrics;
      case RasterCacheKeyType::kLayer:
        return RasterCacheKeyKind::kLayerMetrics;
    }
  }

  struct Hash {
    std::size_t operator()(RasterCacheKey const& key) const {
      return fml::HashCombine(key.id_, key.type_);
    }
  };

  struct Equal {
    constexpr bool operator()(const RasterCacheKey& lhs,
                              const RasterCacheKey& rhs) const {
      return lhs.id_ == rhs.id_ && lhs.type_ == rhs.type_ &&
             lhs.matrix_ == rhs.matrix_;
    }
  };

  template <class Value>
  using Map = std::unordered_map<RasterCacheKey, Value, Hash, Equal>;

 private:
  uint64_t id_;

  RasterCacheKeyType type_;

  // ctm where only fractional (0-1) translations are preserved:
  //   matrix_ = ctm;
  //   matrix_[SkMatrix::kMTransX] = SkScalarFraction(ctm.getTranslateX());
  //   matrix_[SkMatrix::kMTransY] = SkScalarFraction(ctm.getTranslateY());
  SkMatrix matrix_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_RASTER_CACHE_KEY_H_
