// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/utils.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {

typedef CanvasImage Image;

IMPLEMENT_WRAPPERTYPEINFO(ui, Image);

#define FOR_EACH_BINDING(V) \
  V(Image, width)           \
  V(Image, height)          \
  V(Image, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasImage::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

CanvasImage::CanvasImage() {}

CanvasImage::~CanvasImage() {
  // Skia objects must be deleted on the IO thread so that any associated GL
  // objects will be cleaned up through the IO thread's GL context.
  SkiaUnrefOnIOThread(&image_);
}

void CanvasImage::dispose() {
  ClearDartWrapper();
}

size_t CanvasImage::GetAllocationSize() {
  if (image_) {
    return image_->width() * image_->height() * 4;
  } else {
    return sizeof(CanvasImage);
  }
}

}  // namespace blink
