// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/float32_list.h"

#include "flutter/tonic/dart_error.h"

namespace blink {

Float32List::Float32List()
    : data_(nullptr), num_elements_(0), dart_handle_(nullptr) {}

Float32List::Float32List(Dart_Handle list)
    : data_(nullptr), num_elements_(0), dart_handle_(list) {
  if (Dart_IsNull(list))
    return;

  Dart_TypedData_Type type;
  Dart_TypedDataAcquireData(
      list, &type, reinterpret_cast<void**>(&data_), &num_elements_);
  DCHECK(!LogIfError(list));
  DCHECK(type == Dart_TypedData_kFloat32);
}

Float32List::Float32List(Float32List&& other)
    : data_(other.data_),
      num_elements_(other.num_elements_),
      dart_handle_(other.dart_handle_) {
  other.data_ = nullptr;
  other.dart_handle_ = nullptr;
}

Float32List::~Float32List() {
  if (data_)
    Dart_TypedDataReleaseData(dart_handle_);
}

Float32List DartConverter<Float32List>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle list = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(list));
  return Float32List(list);
}

void DartConverter<Float32List>::SetReturnValue(Dart_NativeArguments args,
                                                Float32List val) {
  Dart_SetReturnValue(args, val.dart_handle());
}


} // namespace blink
