// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_BYTE_DATA_H_
#define FLUTTER_TONIC_DART_BYTE_DATA_H_

#include <vector>

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"

namespace blink {

class DartByteData {
 public:
  explicit DartByteData(Dart_Handle list);
  DartByteData(DartByteData&& other);
  DartByteData();
  ~DartByteData();

  const void* data() const { return data_; }
  size_t length_in_bytes() const { return length_in_bytes_; }
  Dart_Handle dart_handle() const { return dart_handle_; }

  std::vector<char> Copy() const;
  void Release() const;

 private:
  mutable void* data_;
  intptr_t length_in_bytes_;
  Dart_Handle dart_handle_;

  DartByteData(const DartByteData& other) = delete;
};

template <>
struct DartConverter<DartByteData> {
  static void SetReturnValue(Dart_NativeArguments args, DartByteData val);
  static DartByteData FromArguments(Dart_NativeArguments args,
                                    int index,
                                    Dart_Handle& exception);
};

} // namespace blink

#endif  // FLUTTER_TONIC_DART_BYTE_DATA_H_
