// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/TextBox.h"

#include "lib/ftl/logging.h"
#include "lib/tonic/dart_class_library.h"
#include "lib/tonic/logging/dart_error.h"
#include "sky/engine/core/script/ui_dart_state.h"

using namespace blink;

namespace tonic {

Dart_Handle DartConverter<TextBox>::ToDart(const TextBox& val) {
  if (val.is_null)
    return Dart_Null();
  tonic::DartClassLibrary& class_library = DartState::Current()->class_library();
  Dart_Handle type =
      Dart_HandleFromPersistent(class_library.GetClass("ui", "TextBox"));
  FTL_DCHECK(!LogIfError(type));
  const int argc = 5;
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
