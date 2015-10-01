// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/ImageShader.h"

namespace blink {

PassRefPtr<ImageShader> ImageShader::create() {
  return adoptRef(new ImageShader());
}

void ImageShader::initWithImage(CanvasImage* image,
                                SkShader::TileMode tmx,
                                SkShader::TileMode tmy,
                                const Float64List& matrix4,
                                ExceptionState& es) {
  ASSERT(image != NULL);

  SkMatrix sk_matrix = toSkMatrix(matrix4, es);
  if (es.had_exception())
      return;

  SkBitmap bitmap;
  image->image()->asLegacyBitmap(&bitmap, SkImage::kRO_LegacyBitmapMode);

  set_shader(adoptRef(SkShader::CreateBitmapShader(bitmap, tmx, tmy, &sk_matrix)));
}

ImageShader::ImageShader() : Shader(nullptr) {
}

ImageShader::~ImageShader() {
}

}  // namespace blink
