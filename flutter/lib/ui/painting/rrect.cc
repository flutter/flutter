// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rrect.h"

#include "flutter/tonic/dart_error.h"
#include "flutter/tonic/float32_list.h"

namespace blink {

// Construct an SkRRect from a Dart RRect object.
// The Dart RRect is a Float32List containing
//   [left, top, right, bottom, xRadius, yRadius]
RRect DartConverter<RRect>::FromDart(Dart_Handle value) {
  Float32List buffer(value);

  RRect result;
  result.is_null = true;
  if (buffer.data() == nullptr)
    return result;

  result.sk_rrect.setRectXY(
      SkRect::MakeLTRB(buffer[0], buffer[1], buffer[2], buffer[3]),
      buffer[4], buffer[5]);

  result.is_null = false;
  return result;
}

RRect DartConverter<RRect>::FromArguments(Dart_NativeArguments args,
                                          int index,
                                          Dart_Handle& exception) {
  Dart_Handle value = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(value));
  return FromDart(value);
}

} // namespace blink
