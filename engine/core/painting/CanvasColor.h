// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_
#define SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_

#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkColor.h"

namespace blink {

class CanvasColor {
 public:
  SkColor sk_color;
};

template<>
struct DartConverter<CanvasColor, void> {
  static CanvasColor FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                                int index,
                                                Dart_Handle& exception);
  static void SetReturnValue(Dart_NativeArguments args, unsigned val);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_
