// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Rect.h"

#include "base/logging.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {

Dart_Handle DartConverter<Rect>::ToDart(const Rect& val) {
  if (val.is_null)
    return Dart_Null();
  DartClassLibrary& class_library = DartState::Current()->class_library();
  Dart_Handle type = Dart_HandleFromPersistent(
      class_library.GetClass("ui", "Rect"));
  DCHECK(!LogIfError(type));
  const int argc = 4;
  Dart_Handle argv[argc] = {
    blink::ToDart(val.sk_rect.fLeft),
    blink::ToDart(val.sk_rect.fTop),
    blink::ToDart(val.sk_rect.fRight),
    blink::ToDart(val.sk_rect.fBottom),
  };
  return Dart_New(type, blink::ToDart("fromLTRB"), argc, argv);
}

// Convert dart_rect._value[0...3] ==> SkRect
Rect DartConverter<Rect>::FromDart(Dart_Handle dart_rect) {
  Rect result;
  result.is_null = true;
  if (Dart_IsNull(dart_rect))
    return result;

  Dart_Handle value =
      Dart_GetField(dart_rect, UIDartState::Current()->value_handle());
  if (Dart_IsNull(value))
    return result;

  Dart_TypedData_Type type;
  float* data = nullptr;
  intptr_t num_elements = 0;
  Dart_TypedDataAcquireData(
      value, &type, reinterpret_cast<void**>(&data), &num_elements);
  DCHECK(!LogIfError(value));
  ASSERT(type == Dart_TypedData_kFloat32 && num_elements == 4);

  SkScalar* dest[] = {
    &result.sk_rect.fLeft,
    &result.sk_rect.fTop,
    &result.sk_rect.fRight,
    &result.sk_rect.fBottom
  };
  for (intptr_t i = 0; i < 4; ++i)
    *dest[i] = data[i];

  Dart_TypedDataReleaseData(value);

  result.is_null = false;
  return result;
}

Rect DartConverter<Rect>::FromArguments(Dart_NativeArguments args,
                                        int index,
                                        Dart_Handle& exception) {
  Dart_Handle dart_rect = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_rect));
  return FromDart(dart_rect);
}

} // namespace blink
