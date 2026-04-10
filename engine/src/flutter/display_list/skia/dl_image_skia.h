// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_SKIA_DL_IMAGE_SKIA_H_
#define FLUTTER_DISPLAY_LIST_SKIA_DL_IMAGE_SKIA_H_

#include "flutter/display_list/image/dl_image.h"
#include "flutter/fml/macros.h"
#include "flutter/third_party/skia/include/core/SkImage.h"

namespace flutter {

class DlImageSkia : public DlImage {
 public:
  static sk_sp<DlImage> Make(const SkImage* image);

  static sk_sp<DlImage> Make(sk_sp<SkImage> image);

  DlImageSkia() = default;

  // |DlImage|
  Type GetType() const override;

  // |DlImage|
  const DlImageSkia* asDlImageSkia() const override;

  // |DlImage|
  const impeller::DlImageImpeller* asDlImageImpeller() const override;

  virtual sk_sp<SkImage> skia_image() const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DlImageSkia);
};

class DlImageSkiaImpl final : public DlImageSkia {
 public:
  explicit DlImageSkiaImpl(sk_sp<SkImage> image);

  // |DlImage|
  ~DlImageSkiaImpl() override;

  // |DlImage|
  bool isOpaque() const override;

  // |DlImage|
  bool isTextureBacked() const override;

  // |DlImage|
  bool isUIThreadSafe() const override;

  // |DlImage|
  DlISize GetSize() const override;

  // |DlImage|
  size_t GetApproximateByteSize() const override;

  bool Equals(const DlImage* other) const override {
    if (!other) {
      return false;
    }
    if (this == other) {
      return true;
    }
    const DlImageSkia* skia_image = other->asDlImageSkia();
    if (!skia_image) {
      return false;
    }
    return image_ == skia_image->skia_image();
  }

  sk_sp<SkImage> skia_image() const override;

 private:
  sk_sp<SkImage> image_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_SKIA_DL_IMAGE_SKIA_H_
