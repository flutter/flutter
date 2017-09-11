// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/text_box.h"

#include "lib/fxl/logging.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_error.h"

using namespace blink;

namespace tonic {

Dart_Handle DartConverter<TextBox>::ToDart(const TextBox& val) {
  if (val.is_null)
    return Dart_Null();
  DartClassLibrary& class_library = DartState::Current()->class_library();
  Dart_Handle type =
      Dart_HandleFromPersistent(class_library.GetClass("ui", "TextBox"));
  FXL_DCHECK(!LogIfError(type));
  constexpr int argc = 5;
  Dart_Handle argv[argc] = {
      tonic::ToDart(val.sk_rect.fLeft),
      tonic::ToDart(val.sk_rect.fTop),
      tonic::ToDart(val.sk_rect.fRight),
      tonic::ToDart(val.sk_rect.fBottom),
      tonic::ToDart(static_cast<int>(val.direction)),
  };
  return Dart_New(type, tonic::ToDart("_"), argc, argv);
}

}  // namespace tonic
