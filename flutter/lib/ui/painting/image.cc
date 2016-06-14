// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"

namespace blink {

typedef CanvasImage Image;

IMPLEMENT_WRAPPERTYPEINFO(ui, Image);

#define FOR_EACH_BINDING(V) \
  V(Image, width) \
  V(Image, height) \
  V(Image, dispose)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void CanvasImage::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

CanvasImage::CanvasImage() {
}

CanvasImage::~CanvasImage() {
}

void CanvasImage::dispose() {
  ClearDartWrapper();
}

}  // namespace blink
