// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/uint8_list.h"

namespace blink {

Uint8List::Uint8List()
    : data_(nullptr), num_elements_(0), dart_handle_(nullptr) {}

Uint8List::Uint8List(Dart_Handle list)
    : data_(nullptr), num_elements_(0), dart_handle_(list) {
  if (Dart_IsNull(list))
    return;

  Dart_TypedData_Type type;
  Dart_TypedDataAcquireData(
      list, &type, reinterpret_cast<void**>(&data_), &num_elements_);
  DCHECK(!LogIfError(list));
  DCHECK(type == Dart_TypedData_kUint8);
}

Uint8List::Uint8List(Uint8List&& other)
    : data_(other.data_),
      num_elements_(other.num_elements_),
      dart_handle_(other.dart_handle_) {
  other.data_ = nullptr;
  other.dart_handle_ = nullptr;
}

Uint8List::~Uint8List() {
  if (data_)
    Dart_TypedDataReleaseData(dart_handle_);
}

Uint8List DartConverter<Uint8List>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle list = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(list));

  Uint8List result(list);
  return result;
}

void DartConverter<Uint8List>::SetReturnValue(Dart_NativeArguments args,
                                              Uint8List val) {
  Dart_SetReturnValue(args, val.dart_handle());
}

Dart_Handle DartConverter<Uint8List>::ToDart(const uint8_t* buffer,
                                             unsigned int length) {
  const intptr_t buffer_length = static_cast<intptr_t>(length);
  Dart_Handle array = Dart_NewTypedData(Dart_TypedData_kUint8, buffer_length);
  DCHECK(!LogIfError(array));
  {
    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t data_length = 0;
    Dart_TypedDataAcquireData(array, &type, &data, &data_length);
    CHECK_EQ(type, Dart_TypedData_kUint8);
    CHECK(data);
    CHECK_EQ(data_length, buffer_length);
    memmove(data, buffer, data_length);
    Dart_TypedDataReleaseData(array);
  }
  return array;
}

} // namespace blink
