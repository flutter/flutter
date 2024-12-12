// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/rrect.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/logging/dart_error.h"
#include "third_party/tonic/typed_data/typed_list.h"

using flutter::RRect;

namespace tonic {

// Construct an DlRoundRect from a Dart RRect object.
// The Dart RRect is a Float32List containing
//   [left, top, right, bottom, xRadius, yRadius]
RRect DartConverter<flutter::RRect>::FromDart(Dart_Handle value) {
  Float32List buffer(value);

  RRect result;
  result.is_null = true;
  if (buffer.data() == nullptr) {
    return result;
  }

  impeller::RoundingRadii radii = {{buffer[4], buffer[5]},
                                   {buffer[6], buffer[7]},
                                   {buffer[10], buffer[11]},
                                   {buffer[8], buffer[9]}};

  result.rrect = flutter::DlRoundRect::MakeRectRadii(
      flutter::DlRect::MakeLTRB(buffer[0], buffer[1], buffer[2], buffer[3]),
      radii);

  result.is_null = false;
  return result;
}

RRect DartConverter<flutter::RRect>::FromArguments(Dart_NativeArguments args,
                                                   int index,
                                                   Dart_Handle& exception) {
  Dart_Handle value = Dart_GetNativeArgument(args, index);
  FML_DCHECK(!CheckAndHandleError(value));
  return FromDart(value);
}

}  // namespace tonic
