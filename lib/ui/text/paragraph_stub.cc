// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_stub.h"

#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(ui, Paragraph);

#define FOR_EACH_BINDING(V)         \
  V(Paragraph, width)               \
  V(Paragraph, height)              \
  V(Paragraph, minIntrinsicWidth)   \
  V(Paragraph, maxIntrinsicWidth)   \
  V(Paragraph, alphabeticBaseline)  \
  V(Paragraph, ideographicBaseline) \
  V(Paragraph, layout)              \
  V(Paragraph, paint)               \
  V(Paragraph, getWordBoundary)     \
  V(Paragraph, getRectsForRange)    \
  V(Paragraph, getPositionForOffset)

DART_BIND_ALL(Paragraph, FOR_EACH_BINDING)

Paragraph::Paragraph() {}

Paragraph::~Paragraph() {}

double Paragraph::width() {
  return 0.0;
}

double Paragraph::height() {
  return 0.0;
}

double Paragraph::minIntrinsicWidth() {
  return 0.0;
}

double Paragraph::maxIntrinsicWidth() {
  return 0.0;
}

double Paragraph::alphabeticBaseline() {
  return 0.0;
}

double Paragraph::ideographicBaseline() {
  return 0.0;
}

void Paragraph::layout(double width) {}

void Paragraph::paint(Canvas* canvas, double x, double y) {}

void Paragraph::getRectsForRange(unsigned start, unsigned end) {}

Dart_Handle Paragraph::getPositionForOffset(double dx, double dy) {
  Dart_Handle result = Dart_NewList(2);
  Dart_ListSetAt(result, 0, ToDart(0));
  Dart_ListSetAt(result, 1, ToDart(0));
  return result;
}

Dart_Handle Paragraph::getWordBoundary(unsigned offset) {
  Dart_Handle result = Dart_NewList(2);
  Dart_ListSetAt(result, 0, ToDart(0));
  Dart_ListSetAt(result, 1, ToDart(0));
  return result;
}

}  // namespace blink
