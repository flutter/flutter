// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image.h"

#include "flutter/lib/ui/painting/image_encoding.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

typedef CanvasImage Image;

IMPLEMENT_WRAPPERTYPEINFO(ui, Image);

#define FOR_EACH_BINDING(V) \
  V(Image, width)           \
  V(Image, height)          \
  V(Image, toByteData)      \
  V(Image, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasImage::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

CanvasImage::CanvasImage() = default;

CanvasImage::~CanvasImage() = default;

Dart_Handle CanvasImage::toByteData(int format, Dart_Handle callback) {
  return EncodeImage(this, format, callback);
}

void CanvasImage::dispose() {
  image_.reset();
  ClearDartWrapper();
}

size_t CanvasImage::GetAllocationSize() const {
  if (auto image = image_.get()) {
    const auto& info = image->imageInfo();
    const auto kMipmapOverhead = 4.0 / 3.0;
    const size_t image_byte_size = info.computeMinByteSize() * kMipmapOverhead;
    return image_byte_size + sizeof(this);
  } else {
    return sizeof(CanvasImage);
  }
}

}  // namespace flutter
