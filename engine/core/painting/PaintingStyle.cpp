// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/PaintingStyle.h"

#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_builtin.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_value.h"

namespace blink {

// If this fails, it's because SkXfermode has changed. We need to change
// PaintingStyle.dart to ensure the PaintingStyle enum is in sync with the C++
// values.
COMPILE_ASSERT(SkPaint::kStyleCount == 3, Need_to_update_PaintingStyle_dart);

// Convert dart_style => SkPaint::Style.
SkPaint::Style DartConverter<PaintingStyle>::FromArgumentsWithNullCheck(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  SkPaint::Style result;

  Dart_Handle dart_style = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_style));

  Dart_Handle value =
      Dart_GetField(dart_style, DOMDartState::Current()->index_handle());

  uint64_t style = 0;
  Dart_Handle rv = Dart_IntegerToUint64(value, &style);
  DCHECK(!LogIfError(rv));

  result = static_cast<SkPaint::Style>(style);
  return result;
}

} // namespace blink
