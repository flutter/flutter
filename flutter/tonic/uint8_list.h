// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_UINT8_LIST_H_
#define FLUTTER_TONIC_UINT8_LIST_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"

namespace blink {

// A simple wrapper around a Dart Uint8List. It uses Dart_TypedDataAcquireData
// to obtain a raw pointer to the data, which is released when this object is
// destroyed.
//
// This is designed to be used with DartConverter only.
class Uint8List {
 public:
  explicit Uint8List(Dart_Handle list);
  Uint8List(Uint8List&& other);
  Uint8List();
  ~Uint8List();

  uint8& at(intptr_t i)
  {
      CHECK(i < num_elements_);
      return data_[i];
  }
  const uint8& at(intptr_t i) const
  {
      CHECK(i < num_elements_);
      return data_[i];
  }

  uint8& operator[](intptr_t i) { return at(i); }
  const uint8& operator[](intptr_t i) const { return at(i); }

  const uint8* data() const { return data_; }
  intptr_t num_elements() const { return num_elements_; }
  Dart_Handle dart_handle() const { return dart_handle_; }

 private:
  uint8* data_;
  intptr_t num_elements_;
  Dart_Handle dart_handle_;

  Uint8List(const Uint8List& other) = delete;
};

template <>
struct DartConverter<Uint8List> {
  static void SetReturnValue(Dart_NativeArguments args, Uint8List val);
  static Uint8List FromArguments(Dart_NativeArguments args,
                                 int index,
                                 Dart_Handle& exception);
  static Dart_Handle ToDart(const uint8_t* buffer, unsigned int length);
};

} // namespace blink

#endif  // FLUTTER_TONIC_UINT8_LIST_H_
