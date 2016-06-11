// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_
#define SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_

#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkColor.h"

namespace blink {

struct CanvasColor {
  SkColor sk_color;

  CanvasColor(SkColor color) : sk_color(color) { }
  CanvasColor() : sk_color() { }
  operator SkColor() const { return sk_color; }
};

template <>
struct DartConverter<CanvasColor> {
  static CanvasColor FromDart(Dart_Handle handle);
  static CanvasColor FromArguments(Dart_NativeArguments args,
                                   int index,
                                   Dart_Handle& exception);
  static void SetReturnValue(Dart_NativeArguments args, CanvasColor val);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVASCOLOR_H_
