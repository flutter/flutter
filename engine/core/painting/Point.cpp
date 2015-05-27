// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/Point.h"

#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_state.h"
#include "base/logging.h"

namespace blink {

// Convert dartPoint.x,y ==> SkPoint.
Point DartConverter<Point, void>::FromArgumentsWithNullCheck(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Point result;
  result.is_null = true;

  Dart_Handle dartPoint = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dartPoint));

  Dart_Handle xValue = Dart_GetField(dartPoint, Dart_NewStringFromCString("x"));
  Dart_Handle yValue = Dart_GetField(dartPoint, Dart_NewStringFromCString("y"));

  double x = 0.0, y = 0.0;
  Dart_Handle err = Dart_DoubleValue(xValue, &x);
  DCHECK(!LogIfError(err));
  err = Dart_DoubleValue(xValue, &y);
  DCHECK(!LogIfError(err));
  result.sk_point.set(x, y);
  result.is_null = false;
  return result;
}

} // namespace blink
