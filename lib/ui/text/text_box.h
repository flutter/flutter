// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_TEXT_BOX_H_
#define FLUTTER_LIB_UI_TEXT_TEXT_BOX_H_

#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/tonic/converter/dart_converter.h"

namespace blink {

enum class TextDirection {
  rtl,
  ltr,
};

struct TextBox {
  SkRect rect;
  TextDirection direction;

  TextBox(SkRect r, TextDirection d) : rect(r), direction(d) {}
};

}  // namespace blink

namespace tonic {

template <>
struct DartConverter<blink::TextBox> {
  static Dart_Handle ToDart(const blink::TextBox& val);
};

template <>
struct DartListFactory<blink::TextBox> {
  static Dart_Handle NewList(intptr_t length);
};

}  // namespace tonic

#endif  // FLUTTER_LIB_UI_TEXT_TEXT_BOX_H_
