// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/text_box.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/dart_class_library.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_error.h"

using namespace blink;

namespace tonic {

namespace {

Dart_Handle GetTextBoxType() {
  DartClassLibrary& class_library = DartState::Current()->class_library();
  Dart_Handle type =
      Dart_HandleFromPersistent(class_library.GetClass("ui", "TextBox"));
  FML_DCHECK(!LogIfError(type));
  return type;
}

}  // anonymous namespace

Dart_Handle DartConverter<TextBox>::ToDart(const TextBox& val) {
  constexpr int argc = 5;
  Dart_Handle argv[argc] = {
      tonic::ToDart(val.rect.fLeft),
      tonic::ToDart(val.rect.fTop),
      tonic::ToDart(val.rect.fRight),
      tonic::ToDart(val.rect.fBottom),
      tonic::ToDart(static_cast<int>(val.direction)),
  };
  return Dart_New(GetTextBoxType(), tonic::ToDart("_"), argc, argv);
}

Dart_Handle DartListFactory<TextBox>::NewList(intptr_t length) {
  return Dart_NewListOfType(GetTextBoxType(), length);
}

}  // namespace tonic
