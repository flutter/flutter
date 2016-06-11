// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/int32_list.h"

namespace blink {

Int32List::Int32List()
    : data_(nullptr), num_elements_(0), dart_handle_(nullptr) {}

Int32List::Int32List(Dart_Handle list)
    : data_(nullptr), num_elements_(0), dart_handle_(list) {
  if (Dart_IsNull(list))
    return;

  Dart_TypedData_Type type;
  Dart_TypedDataAcquireData(
      list, &type, reinterpret_cast<void**>(&data_), &num_elements_);
  DCHECK(!LogIfError(list));
  DCHECK(type == Dart_TypedData_kInt32);
}

Int32List::Int32List(Int32List&& other)
    : data_(other.data_),
      num_elements_(other.num_elements_),
      dart_handle_(other.dart_handle_) {
  other.data_ = nullptr;
  other.dart_handle_ = nullptr;
}

Int32List::~Int32List() {
  Release();
}

void Int32List::Release() {
  if (data_) {
    Dart_TypedDataReleaseData(dart_handle_);
    data_ = nullptr;
  }
}


Int32List DartConverter<Int32List>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle list = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(list));

  Int32List result(list);
  return result;
}

void DartConverter<Int32List>::SetReturnValue(Dart_NativeArguments args,
                                              Int32List val) {
  Dart_SetReturnValue(args, val.dart_handle());
}

} // namespace blink
