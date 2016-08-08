// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_PICTURE_SERIALIZER_H_
#define SKY_SHELL_GPU_PICTURE_SERIALIZER_H_

#include <string>

#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPixelSerializer.h"

namespace sky {

class PngPixelSerializer : public SkPixelSerializer {
 public:
  bool onUseEncodedData(const void*, size_t) override;
  SkData* onEncode(const SkPixmap& pixmap) override;
};

void SerializePicture(const std::string& path, SkPicture* picture);

}  // namespace sky

#endif  // SKY_SHELL_GPU_PICTURE_SERIALIZER_H_
