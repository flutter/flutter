// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_POINT_H_
#define SKY_ENGINE_CORE_PAINTING_POINT_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkPoint.h"

namespace blink {
// Very simple wrapper for SkPoint to add a null state.
class Point {
 public:
  SkPoint sk_point;
  bool is_null;
};

template <>
struct DartConverter<Point> {
  static Point FromDart(Dart_Handle handle);
  static Point FromArguments(Dart_NativeArguments args,
                             int index,
                             Dart_Handle& exception);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_POINT_H_
