// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_IMAGE_DECODING_H_
#define FLUTTER_LIB_UI_PAINTING_IMAGE_DECODING_H_

#include "flutter/tonic/dart_library_natives.h"

namespace blink {

class ImageDecoding {
 public:
  static void RegisterNatives(DartLibraryNatives* natives);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_IMAGE_DECODING_H_
