// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/TextDecoration.h"

namespace blink {

static TextDecoration toTextDecoration(int index) {
  switch (index) {
    case 0: // none
      return TextDecorationNone;
    case 1: // underline
      return TextDecorationUnderline;
    case 2: // overline
      return TextDecorationOverline;
    case 3: // lineThrough
      return TextDecorationLineThrough;
    default:
      return TextDecorationNone;
  }
}

TextDecoration DartConverter<TextDecoration>::FromArguments(
    Dart_NativeArguments args, int index, Dart_Handle& exception) {
  return toTextDecoration(DartConverterEnum<int>::FromArguments(args, index, exception));
}

TextDecoration DartConverter<TextDecoration>::FromDart(Dart_Handle handle) {
  return toTextDecoration(DartConverterEnum<int>::FromDart(handle));
}

} // namespace blink
