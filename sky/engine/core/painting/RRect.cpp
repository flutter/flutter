// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/RRect.h"

#include "flutter/tonic/dart_error.h"
#include "sky/engine/core/script/ui_dart_state.h"

namespace blink {

// Construct an SkRRect from a Dart RRect object.
// The Dart RRect has a _value field which is a Float32List containing
//   [left, top, right, bottom, xRad, yRad]
RRect DartConverter<RRect>::FromDart(Dart_Handle dart_rrect) {
  RRect result;
  result.is_null = true;
  if (Dart_IsNull(dart_rrect))
    return result;

  Dart_Handle value =
    Dart_GetField(dart_rrect, UIDartState::Current()->value_handle());
  if (Dart_IsNull(value))
    return result;

  Dart_TypedData_Type type;
  float* data = nullptr;
  intptr_t num_elements = 0;
  Dart_TypedDataAcquireData(
      value, &type, reinterpret_cast<void**>(&data), &num_elements);
  DCHECK(!LogIfError(value));
  DCHECK(type == Dart_TypedData_kFloat32 && num_elements == 6);

  result.sk_rrect.setRectXY(
      SkRect::MakeLTRB(data[0], data[1], data[2], data[3]),
      data[4], data[5]);

  Dart_TypedDataReleaseData(value);

  result.is_null = false;
  return result;
}

RRect DartConverter<RRect>::FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
  Dart_Handle dart_rrect = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_rrect));
  return FromDart(dart_rrect);
}

} // namespace blink
