// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_
#define FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_

#include <string>

#include "flutter/display_list/display_list.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPromiseImageTexture.h"
#include "third_party/skia/include/gpu/GrContextThreadSafeProxy.h"
namespace flutter {

class SnapshotDelegate {
 public:
  virtual std::pair<sk_sp<SkImage>, std::string> MakeGpuImage(
      sk_sp<DisplayList> display_list,
      SkISize picture_size) = 0;

  virtual sk_sp<SkImage> MakeRasterSnapshot(
      std::function<void(SkCanvas*)> draw_callback,
      SkISize picture_size) = 0;

  virtual sk_sp<SkImage> MakeRasterSnapshot(sk_sp<SkPicture> picture,
                                            SkISize picture_size) = 0;

  virtual sk_sp<SkImage> ConvertToRasterImage(sk_sp<SkImage> image) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SNAPSHOT_DELEGATE_H_
