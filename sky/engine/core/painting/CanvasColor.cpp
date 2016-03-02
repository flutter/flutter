// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/CanvasColor.h"

#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/tonic/dart_error.h"

namespace blink {

CanvasColor DartConverter<CanvasColor>::FromDart(Dart_Handle dart_color) {
  Dart_Handle value =
      Dart_GetField(dart_color, UIDartState::Current()->value_handle());

  uint64_t sk_color = 0;
  Dart_Handle rv = Dart_IntegerToUint64(value, &sk_color);
  DCHECK(!LogIfError(rv));
  DCHECK(sk_color <= 0xffffffff);

  return static_cast<SkColor>(sk_color);
}

CanvasColor DartConverter<CanvasColor>::FromArguments(
    Dart_NativeArguments args,
    int index,
    Dart_Handle& exception) {
  Dart_Handle dart_color = Dart_GetNativeArgument(args, index);
  DCHECK(!LogIfError(dart_color));
  return FromDart(dart_color);
}

void DartConverter<CanvasColor>::SetReturnValue(Dart_NativeArguments args,
                                                CanvasColor val) {
  Dart_Handle color_class = UIDartState::Current()->color_class();
  Dart_Handle constructor_args[] = { ToDart(val.sk_color) };
  Dart_SetReturnValue(args,
                      Dart_New(color_class, Dart_Null(), 1, constructor_args));
}

} // namespace blink
