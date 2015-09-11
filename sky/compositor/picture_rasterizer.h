// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_PICTURE_RASTERIZER_H_
#define SKY_COMPOSITOR_PICTURE_RASTERIZER_H_

#include "base/macros.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkImage.h"
#include "sky/compositor/instrumentation.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

#include <functional>  // for std::hash
#include <unordered_map>
#include <unordered_set>

namespace sky {
namespace compositor {

class PaintContext;
class PictureRasterzier {
 public:
  PictureRasterzier();
  ~PictureRasterzier();

  RefPtr<SkImage> GetCachedImageIfPresent(PaintContext& context,
                                          GrContext* gr_context,
                                          SkPicture* picture,
                                          const SkISize& physical_size,
                                          const SkMatrix& incoming_ctm);

  void PurgeCache();

  const instrumentation::Counter& cache_fills() { return cache_fills_; }

  const instrumentation::Counter& cache_hits() { return cache_hits_; }

  const instrumentation::Counter& cache_evictions() { return cache_evictions_; }

 private:
  struct Key {
    uint32_t pictureID;
    SkISize size;

    explicit Key(uint32_t ident, SkISize sz);
    Key(const Key& key);
  };

  struct KeyHash {
    std::size_t operator()(const Key& key) const {
      return std::hash<uint32_t>()(key.pictureID) ^
             std::hash<int32_t>()(key.size.width()) ^
             std::hash<int32_t>()(key.size.height());
    }
  };

  struct KeyEqual {
    bool operator()(const Key& lhs, const Key& rhs) const {
      return lhs.pictureID == rhs.pictureID && lhs.size == rhs.size;
    }
  };

  struct Value {
    static const int8_t kDeadAccessCount = -1;

    int8_t access_count;
    RefPtr<SkImage> image;

    Value();
    ~Value();
  };

  using Cache = std::unordered_map<Key, Value, KeyHash, KeyEqual>;
  Cache cache_;
  instrumentation::Counter cache_fills_;
  instrumentation::Counter cache_hits_;
  instrumentation::Counter cache_evictions_;

  RefPtr<SkImage> ImageFromPicture(PaintContext& context,
                                   GrContext* gr_context,
                                   SkPicture* picture,
                                   const SkISize& physical_size,
                                   const SkMatrix& incomingCTM);

  DISALLOW_COPY_AND_ASSIGN(PictureRasterzier);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_PICTURE_RASTERIZER_H_
