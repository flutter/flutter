// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_RASTER_CACHE_KEY_H_
#define FLUTTER_FLOW_RASTER_CACHE_KEY_H_

#include <unordered_map>
#include "flutter/flow/matrix_decomposition.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace flow {

class RasterCacheKey {
 public:
  RasterCacheKey(const SkPicture& picture, const SkMatrix& ctm)
      : picture_id_(picture.uniqueID()), matrix_(ctm) {
    matrix_[SkMatrix::kMTransX] = SkScalarFraction(ctm.getTranslateX());
    matrix_[SkMatrix::kMTransY] = SkScalarFraction(ctm.getTranslateY());
#ifndef SUPPORT_FRACTIONAL_TRANSLATION
    FML_DCHECK(matrix_.getTranslateX() == 0 && matrix_.getTranslateY() == 0);
#endif
  }

  uint32_t picture_id() const { return picture_id_; }
  const SkMatrix& matrix() const { return matrix_; }

  struct Hash {
    std::size_t operator()(RasterCacheKey const& key) const {
      return key.picture_id_;
    }
  };

  struct Equal {
    constexpr bool operator()(const RasterCacheKey& lhs,
                              const RasterCacheKey& rhs) const {
      return lhs.picture_id_ == rhs.picture_id_ && lhs.matrix_ == rhs.matrix_;
    }
  };

  template <class Value>
  using Map = std::unordered_map<RasterCacheKey, Value, Hash, Equal>;

 private:
  uint32_t picture_id_;

  // ctm where only fractional (0-1) translations are preserved:
  //   matrix_ = ctm;
  //   matrix_[SkMatrix::kMTransX] = SkScalarFraction(ctm.getTranslateX());
  //   matrix_[SkMatrix::kMTransY] = SkScalarFraction(ctm.getTranslateY());
  SkMatrix matrix_;
};

}  // namespace flow

#endif  // FLUTTER_FLOW_RASTER_CACHE_KEY_H_
