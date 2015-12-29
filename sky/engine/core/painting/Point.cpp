// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Point.h"

#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_error.h"
#include "base/logging.h"

namespace blink {

// Convert handle.x,y ==> SkPoint.
Point DartConverter<Point>::FromDart(Dart_Handle handle) {
  DCHECK(!LogIfError(handle));
  Dart_Handle x_value =
      Dart_GetField(handle, DOMDartState::Current()->x_handle());
  Dart_Handle y_value =
      Dart_GetField(handle, DOMDartState::Current()->y_handle());
  double x = 0.0, y = 0.0;
  Dart_Handle err = Dart_DoubleValue(x_value, &x);
  DCHECK(!LogIfError(err));
  err = Dart_DoubleValue(y_value, &y);
  DCHECK(!LogIfError(err));

  Point result;
  result.sk_point.set(x, y);
  result.is_null = false;
  return result;
}

Point DartConverter<Point>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  return FromDart(Dart_GetNativeArgument(args, index));
}

} // namespace blink
