// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/TextBox.h"

#include "base/logging.h"
#include "flutter/tonic/dart_class_library.h"
#include "flutter/tonic/dart_error.h"
#include "sky/engine/core/script/ui_dart_state.h"

namespace blink {

Dart_Handle DartConverter<TextBox>::ToDart(const TextBox& val) {
  if (val.is_null)
    return Dart_Null();
  DartClassLibrary& class_library = DartState::Current()->class_library();
  Dart_Handle type = Dart_HandleFromPersistent(
      class_library.GetClass("ui", "TextBox"));
  DCHECK(!LogIfError(type));
  const int argc = 5;
  Dart_Handle argv[argc] = {
    blink::ToDart(val.sk_rect.fLeft),
    blink::ToDart(val.sk_rect.fTop),
    blink::ToDart(val.sk_rect.fRight),
    blink::ToDart(val.sk_rect.fBottom),
    blink::ToDart(static_cast<int>(val.direction)),
  };
  return Dart_New(type, blink::ToDart("_"), argc, argv);
}

} // namespace blink
