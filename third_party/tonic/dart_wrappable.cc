// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tonic/dart_wrappable.h"

#include "tonic/dart_class_library.h"
#include "tonic/dart_state.h"
#include "tonic/dart_wrapper_info.h"
#include "tonic/logging/dart_error.h"

namespace tonic {

DartWrappable::~DartWrappable() {
  // Calls the destructor of dart_wrapper_ to delete WeakPersistentHandle.
}

// TODO(dnfield): Delete this. https://github.com/flutter/flutter/issues/50997
Dart_Handle DartWrappable::CreateDartWrapper(DartState* dart_state) {
  if (!dart_wrapper_.is_empty()) {
    // Any previously given out wrapper must have been GCed.
    TONIC_DCHECK(Dart_IsNull(dart_wrapper_.Get()));
    dart_wrapper_.Clear();
  }

  const DartWrapperInfo& info = GetDartWrapperInfo();

  Dart_PersistentHandle type = dart_state->class_library().GetClass(info);
  TONIC_DCHECK(!LogIfError(type));

  Dart_Handle wrapper =
      Dart_New(type, dart_state->private_constructor_name(), 0, nullptr);

  TONIC_DCHECK(!LogIfError(wrapper));

  Dart_Handle res = Dart_SetNativeInstanceField(
      wrapper, kPeerIndex, reinterpret_cast<intptr_t>(this));
  TONIC_DCHECK(!LogIfError(res));
  res = Dart_SetNativeInstanceField(wrapper, kWrapperInfoIndex,
                                    reinterpret_cast<intptr_t>(&info));
  TONIC_DCHECK(!LogIfError(res));

  this->RetainDartWrappableReference();  // Balanced in FinalizeDartWrapper.
  dart_wrapper_.Set(dart_state, wrapper, this, GetAllocationSize(),
                    &FinalizeDartWrapper);

  return wrapper;
}

void DartWrappable::AssociateWithDartWrapper(Dart_Handle wrapper) {
  if (!dart_wrapper_.is_empty()) {
    // Any previously given out wrapper must have been GCed.
    TONIC_DCHECK(Dart_IsNull(dart_wrapper_.Get()));
    dart_wrapper_.Clear();
  }

  TONIC_CHECK(!LogIfError(wrapper));

  const DartWrapperInfo& info = GetDartWrapperInfo();

  TONIC_CHECK(!LogIfError(Dart_SetNativeInstanceField(
      wrapper, kPeerIndex, reinterpret_cast<intptr_t>(this))));
  TONIC_CHECK(!LogIfError(Dart_SetNativeInstanceField(
      wrapper, kWrapperInfoIndex, reinterpret_cast<intptr_t>(&info))));

  this->RetainDartWrappableReference();  // Balanced in FinalizeDartWrapper.

  DartState* dart_state = DartState::Current();
  dart_wrapper_.Set(dart_state, wrapper, this, GetAllocationSize(),
                    &FinalizeDartWrapper);
}

void DartWrappable::ClearDartWrapper() {
  TONIC_DCHECK(!dart_wrapper_.is_empty());
  Dart_Handle wrapper = dart_wrapper_.Get();
  TONIC_CHECK(!LogIfError(Dart_SetNativeInstanceField(wrapper, kPeerIndex, 0)));
  TONIC_CHECK(
      !LogIfError(Dart_SetNativeInstanceField(wrapper, kWrapperInfoIndex, 0)));
  dart_wrapper_.Clear();
  this->ReleaseDartWrappableReference();
}

void DartWrappable::FinalizeDartWrapper(void* isolate_callback_data,
                                        void* peer) {
  DartWrappable* wrappable = reinterpret_cast<DartWrappable*>(peer);
  wrappable->ReleaseDartWrappableReference();  // Balanced in CreateDartWrapper.
}

size_t DartWrappable::GetAllocationSize() const {
  return GetDartWrapperInfo().size_in_bytes;
}

Dart_PersistentHandle DartWrappable::GetTypeForWrapper(
    tonic::DartState* dart_state,
    const tonic::DartWrapperInfo& wrapper_info) {
  return dart_state->class_library().GetClass(wrapper_info);
}

DartWrappable* DartConverterWrappable::FromDart(Dart_Handle handle) {
  intptr_t peer = 0;
  Dart_Handle result =
      Dart_GetNativeInstanceField(handle, DartWrappable::kPeerIndex, &peer);
  if (Dart_IsError(result))
    return nullptr;
  return reinterpret_cast<DartWrappable*>(peer);
}

DartWrappable* DartConverterWrappable::FromArguments(Dart_NativeArguments args,
                                                     int index,
                                                     Dart_Handle& exception) {
  intptr_t native_fields[DartWrappable::kNumberOfNativeFields];
  Dart_Handle result = Dart_GetNativeFieldsOfArgument(
      args, index, DartWrappable::kNumberOfNativeFields, native_fields);
  if (Dart_IsError(result)) {
    exception = Dart_NewStringFromCString(DartError::kInvalidArgument);
    return nullptr;
  }
  if (!native_fields[DartWrappable::kPeerIndex])
    return nullptr;
  return reinterpret_cast<DartWrappable*>(
      native_fields[DartWrappable::kPeerIndex]);
}

}  // namespace tonic
