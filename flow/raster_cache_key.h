// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_KEY_H_
#define FLUTTER_FLOW_RASTER_CACHE_KEY_H_

#include <optional>
#include <unordered_map>
#include <utility>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkMatrix.h"

namespace flutter {

class Layer;

enum class RasterCacheKeyType { kLayer, kDisplayList, kLayerChildren };

class RasterCacheKeyID {
 public:
  RasterCacheKeyID(uint16_t id, RasterCacheKeyType type)
      : ids_({id}), type_(type) {}

  RasterCacheKeyID(const std::vector<uint64_t> ids, RasterCacheKeyType type)
      : ids_(ids), type_(type) {}

  const std::vector<uint64_t>& ids() const { return ids_; }

  RasterCacheKeyType type() const { return type_; }

  static std::optional<std::vector<uint64_t>> LayerChildrenIds(Layer* layer);

  std::size_t GetHash() const {
    std::size_t seed = fml::HashCombine();
    for (auto id : ids_) {
      fml::HashCombineSeed(seed, id);
    }
    return fml::HashCombine(seed, type_);
  }

  bool operator==(const RasterCacheKeyID& other) const {
    return type_ == other.type_ && ids_ == other.ids_;
  }

  bool operator!=(const RasterCacheKeyID& other) const {
    return !operator==(other);
  }

 private:
  const std::vector<uint64_t> ids_;
  const RasterCacheKeyType type_;
};

enum class RasterCacheKeyKind { kLayerMetrics, kDisplayListMetrics };

class RasterCacheKey {
 public:
  RasterCacheKey(uint64_t id, RasterCacheKeyType type, const SkMatrix& ctm)
      : RasterCacheKey(RasterCacheKeyID(id, type), ctm) {}

  RasterCacheKey(RasterCacheKeyID id, const SkMatrix& ctm)
      : id_(std::move(id)), matrix_(ctm) {
    matrix_[SkMatrix::kMTransX] = 0;
    matrix_[SkMatrix::kMTransY] = 0;
  }

  const RasterCacheKeyID& id() const { return id_; }
  RasterCacheKeyType type() const { return id_.type(); }
  const SkMatrix& matrix() const { return matrix_; }

  RasterCacheKeyKind kind() const {
    switch (id_.type()) {
      case RasterCacheKeyType::kDisplayList:
        return RasterCacheKeyKind::kDisplayListMetrics;
      case RasterCacheKeyType::kLayer:
      case RasterCacheKeyType::kLayerChildren:
        return RasterCacheKeyKind::kLayerMetrics;
    }
  }

  struct Hash {
    std::size_t operator()(RasterCacheKey const& key) const {
      return key.id_.GetHash();
    }
  };

  struct Equal {
    constexpr bool operator()(const RasterCacheKey& lhs,
                              const RasterCacheKey& rhs) const {
      return lhs.id_ == rhs.id_ && lhs.matrix_ == rhs.matrix_;
    }
  };

  template <class Value>
  using Map = std::unordered_map<RasterCacheKey, Value, Hash, Equal>;

 private:
  RasterCacheKeyID id_;

  // ctm where only fractional (0-1) translations are preserved:
  //   matrix_ = ctm;
  //   matrix_[SkMatrix::kMTransX] = SkScalarFraction(ctm.getTranslateX());
  //   matrix_[SkMatrix::kMTransY] = SkScalarFraction(ctm.getTranslateY());
  SkMatrix matrix_;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_RASTER_CACHE_KEY_H_
