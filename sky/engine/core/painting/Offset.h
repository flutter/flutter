// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_OFFSET_H_
#define SKY_ENGINE_CORE_PAINTING_OFFSET_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_converter.h"
#include "third_party/skia/include/core/SkSize.h"

namespace blink {
// Very simple wrapper for SkSize to add a null state.
class Offset {
 public:
  SkSize sk_size;
  bool is_null;
};

template <>
struct DartConverter<Offset> {
  static Offset FromDart(Dart_Handle handle);
  static Offset FromArguments(Dart_NativeArguments args,
                              int index,
                              Dart_Handle& exception);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_OFFSET_H_
