// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_H_

#include "third_party/tonic/dart_library_natives.h"

namespace blink {

class CanvasImage;

Dart_Handle EncodeImage(CanvasImage* canvas_image,
                        int format,
                        Dart_Handle callback_handle);

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_ENCODING_H_
