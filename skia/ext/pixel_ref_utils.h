// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_PIXEL_REF_UTILS_H_
#define SKIA_EXT_PIXEL_REF_UTILS_H_

#include <vector>

#include "SkPicture.h"
#include "SkRect.h"

namespace skia {

class SK_API PixelRefUtils {
 public:

  struct PositionPixelRef {
    SkPixelRef* pixel_ref;
    SkRect pixel_ref_rect;
  };

  static void GatherDiscardablePixelRefs(
      SkPicture* picture,
      std::vector<PositionPixelRef>* pixel_refs);
};

typedef std::vector<PixelRefUtils::PositionPixelRef> DiscardablePixelRefList;

}  // namespace skia

#endif
