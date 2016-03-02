// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/RSTransform.h"

#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/tonic/dart_error.h"
#include "base/logging.h"

namespace blink {

// Convert dart_xform._value[0...3] ==> RSTransform
RSTransform DartConverter<RSTransform>::FromDart(Dart_Handle dart_xform) {
  RSTransform result;
  result.is_null = true;
  if (Dart_IsNull(dart_xform))
    return result;

  Dart_Handle value =
      Dart_GetField(dart_xform, UIDartState::Current()->value_handle());
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
    &result.sk_xform.fSCos,
    &result.sk_xform.fSSin,
    &result.sk_xform.fTx,
    &result.sk_xform.fTy
  };
  for (intptr_t i = 0; i < 4; ++i)
    *dest[i] = data[i];

  Dart_TypedDataReleaseData(value);

  result.is_null = false;
  return result;
}

} // namespace blink
