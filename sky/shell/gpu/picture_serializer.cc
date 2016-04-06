// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/gpu/picture_serializer.h"

#include <vector>
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkPixelSerializer.h"
#include "third_party/skia/include/core/SkStream.h"
#include "ui/gfx/codec/png_codec.h"

namespace sky {

bool PngPixelSerializer::onUseEncodedData(const void*, size_t) {
  return true;
}

SkData* PngPixelSerializer::onEncode(const SkPixmap& pixmap) {
  std::vector<unsigned char> data;

  SkBitmap bm;
  if (!bm.installPixels(pixmap))
    return nullptr;
  if (!gfx::PNGCodec::EncodeBGRASkBitmap(bm, false, &data))
    return nullptr;
  return SkData::NewWithCopy(&data.front(), data.size());
};

void SerializePicture(const base::FilePath& file_name, SkPicture* picture) {
  SkFILEWStream stream(file_name.AsUTF8Unsafe().c_str());
  PngPixelSerializer serializer;
  picture->serialize(&stream, &serializer);
}

}  // namespace sky
