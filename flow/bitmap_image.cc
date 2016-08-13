// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/bitmap_image.h"

namespace flow {

sk_sp<SkImage> BitmapImageCreate(SkImageGenerator& generator) {
  SkBitmap bitmap;
  if (generator.tryGenerateBitmap(&bitmap))
    return SkImage::MakeFromBitmap(bitmap);
  return nullptr;
}

}  // namespace flow
