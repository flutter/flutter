// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/picture_serializer.h"

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkImageEncoder.h"
#include "third_party/skia/include/core/SkPixelSerializer.h"
#include "third_party/skia/include/core/SkStream.h"

namespace sky {

bool PngPixelSerializer::onUseEncodedData(const void*, size_t) {
  return true;
}

SkData* PngPixelSerializer::onEncode(const SkPixmap& pixmap) {
  SkBitmap bitmap;

  if (!bitmap.installPixels(pixmap)) {
    return nullptr;
  }

  return SkImageEncoder::EncodeData(bitmap, SkImageEncoder::Type::kPNG_Type,
                                    SkImageEncoder::kDefaultQuality);
}

void SerializePicture(const base::FilePath& file_name, SkPicture* picture) {
  SkFILEWStream stream(file_name.AsUTF8Unsafe().c_str());
  PngPixelSerializer serializer;
  picture->serialize(&stream, &serializer);
}

}  // namespace sky
