// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class Canvas;
class DartLibraryNatives;

class Picture : public base::RefCountedThreadSafe<Picture>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
public:
  ~Picture() override;
  static scoped_refptr<Picture> Create(sk_sp<SkPicture> picture);

  const sk_sp<SkPicture>& picture() const { return picture_; }

  void dispose();

  static void RegisterNatives(DartLibraryNatives* natives);

private:
  explicit Picture(sk_sp<SkPicture> picture);

  sk_sp<SkPicture> picture_;
};

} // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_H_
