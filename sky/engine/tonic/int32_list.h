// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_INT32_LIST_H_
#define SKY_ENGINE_TONIC_INT32_LIST_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

// A simple wrapper around a Dart Int32List. It uses Dart_TypedDataAcquireData
// to obtain a raw pointer to the data, which is released when this object is
// destroyed.
//
// This is designed to be used with DartConverter only.
class Int32List {
 public:
  explicit Int32List(Dart_Handle list);
  Int32List(Int32List&& other);
  Int32List();
  ~Int32List();

  int32_t& at(intptr_t i)
  {
      CHECK(i < num_elements_);
      return data_[i];
  }
  const int32_t& at(intptr_t i) const
  {
      CHECK(i < num_elements_);
      return data_[i];
  }

  int32_t& operator[](intptr_t i) { return at(i); }
  const int32_t& operator[](intptr_t i) const { return at(i); }

  const int32_t* data() const { return data_; }
  intptr_t num_elements() const { return num_elements_; }
  Dart_Handle dart_handle() const { return dart_handle_; }

  void Release();

 private:
  int32_t* data_;
  intptr_t num_elements_;
  Dart_Handle dart_handle_;

  Int32List(const Int32List& other) = delete;
};

template <>
struct DartConverter<Int32List> {
  static void SetReturnValue(Dart_NativeArguments args, Int32List val);
  static Int32List FromArguments(Dart_NativeArguments args,
                                 int index,
                                 Dart_Handle& exception);
  static Int32List FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                              int index,
                                              Dart_Handle& exception) {
    return FromArguments(args, index, exception);
  }
};

} // namespace blink

#endif  // SKY_ENGINE_TONIC_INT32_LIST_H_
