// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/compositor/picture_serializer.h"

#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkPixelSerializer.h"
#include "third_party/skia/include/core/SkStream.h"
#include "ui/gfx/codec/png_codec.h"

namespace sky {

class PngPixelSerializer : public SkPixelSerializer {
 public:
  bool onUseEncodedData(const void*, size_t) override { return true; }
  SkData* onEncodePixels(const SkImageInfo& info, const void* pixels,
      size_t row_bytes) override {
    std::vector<unsigned char> data;

    SkBitmap bm;
    if (!bm.installPixels(info, const_cast<void*>(pixels), row_bytes))
      return nullptr;
    if (!gfx::PNGCodec::EncodeBGRASkBitmap(bm, false, &data))
      return nullptr;
    return SkData::NewWithCopy(&data.front(), data.size());
  }
};

void SerializePicture(const char* file_name, SkPicture* picture) {
  SkFILEWStream stream(file_name);
  PngPixelSerializer serializer;
  picture->serialize(&stream, &serializer);
}

}  // namespace sky
