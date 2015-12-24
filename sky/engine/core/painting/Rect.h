// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_RECT_H_
#define SKY_ENGINE_CORE_PAINTING_RECT_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkRect.h"

namespace blink {
// Very simple wrapper for SkRect to add a null state.
class Rect {
 public:
  SkRect sk_rect;
  bool is_null;
};

template <>
struct DartConverter<Rect> {
  static Rect FromDart(Dart_Handle handle);
  static Rect FromArguments(Dart_NativeArguments args,
                            int index,
                            Dart_Handle& exception);
  static Rect FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                         int index,
                                         Dart_Handle& exception) {
    return FromArguments(args, index, exception);
  }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_RECT_H_
