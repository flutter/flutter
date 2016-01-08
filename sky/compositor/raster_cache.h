// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_RASTER_CACHE_H_
#define SKY_COMPOSITOR_RASTER_CACHE_H_

#include <memory>
#include <unordered_map>

#include "base/macros.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkImage.h"
#include "sky/compositor/instrumentation.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

namespace sky {
namespace compositor {

class RasterCache {
 public:
  RasterCache();
  ~RasterCache();

  RefPtr<SkImage> GetPrerolledImage(GrContext* context, SkPicture* picture,
                                    const SkMatrix& ctm);
  void SweepAfterFrame();

 private:
  struct Entry {
    Entry();
    ~Entry();

    bool used_this_frame = false;
    int access_count = 0;
    SkISize physical_size;
    RefPtr<SkImage> image;
  };

  using Cache = std::unordered_map<uint32_t, Entry>;
  Cache cache_;

  DISALLOW_COPY_AND_ASSIGN(RasterCache);
};

}  // namespace compositor
}  // namespace sky

#endif  // SKY_COMPOSITOR_RASTER_CACHE_H_
