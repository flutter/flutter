// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/picture_serializer.h"

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkPixelSerializer.h"
#include "third_party/skia/include/core/SkStream.h"

namespace shell {

bool PngPixelSerializer::onUseEncodedData(const void*, size_t) {
  return true;
}

SkData* PngPixelSerializer::onEncode(const SkPixmap& pixmap) {
  SkDynamicMemoryWStream stream;

  bool encode_result = SkEncodeImage(
      &stream, pixmap, SkEncodedImageFormat::kPNG, 80 /* quality */);

  return encode_result ? stream.detachAsData().release() : nullptr;
}

void SerializePicture(const std::string& path, SkPicture* picture) {
  SkFILEWStream stream(path.c_str());
  PngPixelSerializer serializer;
  picture->serialize(&stream, &serializer);
}

}  // namespace shell
