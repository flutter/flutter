// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_H_

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/text/text_box.h"
#include "flutter/third_party/txt/src/txt/paragraph.h"

namespace blink {

class ParagraphImpl {
 public:
  virtual ~ParagraphImpl(){};

  virtual double width() = 0;

  virtual double height() = 0;

  virtual double minIntrinsicWidth() = 0;

  virtual double maxIntrinsicWidth() = 0;

  virtual double alphabeticBaseline() = 0;

  virtual double ideographicBaseline() = 0;

  virtual bool didExceedMaxLines() = 0;

  virtual void layout(double width) = 0;

  virtual void paint(Canvas* canvas, double x, double y) = 0;

  virtual std::vector<TextBox> getRectsForRange(
      unsigned start,
      unsigned end,
      txt::Paragraph::RectStyle rect_style) = 0;

  virtual Dart_Handle getPositionForOffset(double dx, double dy) = 0;

  virtual Dart_Handle getWordBoundary(unsigned offset) = 0;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_H_
