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
  auto size = sizeof(this);
  if (image_) {
    size += image_->GetApproximateByteSize();
  }
  // The VM will assert if we set a value larger than or close to
  // std::numeric_limits<intptr_t>::max().
  // https://github.com/dart-lang/sdk/issues/49332
  return std::clamp(
      size, static_cast<size_t>(0),
      static_cast<size_t>(std::numeric_limits<intptr_t>::max() / 10));
}
}  // namespace flutter
