// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Offset.h"

#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_error.h"
#include "base/logging.h"

namespace blink {

// Convert handle.x,y ==> SkSize.
Offset DartConverter<Offset>::FromDart(Dart_Handle handle) {
  DCHECK(!LogIfError(handle));
  Dart_Handle dx_value =
      Dart_GetField(handle, DOMDartState::Current()->dx_handle());
  Dart_Handle dy_value =
      Dart_GetField(handle, DOMDartState::Current()->dy_handle());
  double dx = 0.0, dy = 0.0;
  Dart_Handle err = Dart_DoubleValue(dx_value, &dx);
  DCHECK(!LogIfError(err));
  err = Dart_DoubleValue(dy_value, &dy);
  DCHECK(!LogIfError(err));

  Offset result;
  result.sk_size.set(dx, dy);
  result.is_null = false;
  return result;
}

Offset DartConverter<Offset>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  return FromDart(Dart_GetNativeArgument(args, index));
}

} // namespace blink
