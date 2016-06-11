// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_direct_wrappable.h"

#include "flutter/tonic/dart_class_library.h"
#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/dart_state.h"
#include "flutter/tonic/dart_wrappable.h"
#include "flutter/tonic/dart_wrapper_info.h"

namespace blink {

Dart_Handle DartDirectWrappable<void*>::Wrap(
    DartState* dart_state,
    void* val,
    const DartWrapperInfo& info) {
  Dart_PersistentHandle type = dart_state->class_library().GetClass(info);
  DCHECK(!LogIfError(type));

  intptr_t native_fields[DartWrappable::kNumberOfNativeFields];
  native_fields[DartWrappable::kPeerIndex] = reinterpret_cast<intptr_t>(val);
  native_fields[DartWrappable::kWrapperInfoIndex] = reinterpret_cast<intptr_t>(&info);
  Dart_Handle wrapper =
      Dart_AllocateWithNativeFields(type, DartWrappable::kNumberOfNativeFields, native_fields);
  DCHECK(!LogIfError(wrapper));
  return wrapper;
}

void* DartDirectWrappable<void*>::FromDart(Dart_Handle handle) {
  intptr_t peer = 0;
  Dart_Handle result =
      Dart_GetNativeInstanceField(handle, DartWrappable::kPeerIndex, &peer);
  if (Dart_IsError(result))
    return nullptr;
  return reinterpret_cast<void*>(peer);
}

void* DartDirectWrappable<void*>::FromArguments(Dart_NativeArguments args,
                                                int index,
                                                Dart_Handle& exception) {
  intptr_t native_fields[DartWrappable::kNumberOfNativeFields];
  Dart_Handle result = Dart_GetNativeFieldsOfArgument(
      args, index, DartWrappable::kNumberOfNativeFields, native_fields);
  if (Dart_IsError(result)) {
    exception = Dart_NewStringFromCString(DartError::kInvalidArgument);
    return nullptr;
  }
  return reinterpret_cast<void*>(native_fields[DartWrappable::kPeerIndex]);
}

}  // namespace blink
