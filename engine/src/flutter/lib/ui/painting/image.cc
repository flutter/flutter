// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image.h"

#include <algorithm>
#include <limits>

#include "flutter/lib/ui/painting/image_encoding.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

typedef CanvasImage Image;

// Since _Image is a private class, we can't use IMPLEMENT_WRAPPERTYPEINFO
static const tonic::DartWrapperInfo kDartWrapperInfo_ui_Image = {
    "ui",
    "_Image",
    sizeof(Image),
};
const tonic::DartWrapperInfo& Image::dart_wrapper_info_ =
    kDartWrapperInfo_ui_Image;

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
  // We don't actually want Dart's GC to use the size of this object to make GC
  // decisions, as it is generally both created and disposed in the framework.
  // This is similar to why we do not report the sizes of engine layers.
  return sizeof(*this);
}
}  // namespace flutter
