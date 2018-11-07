// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_TXT_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_TXT_H_

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "flutter/lib/ui/text/text_box.h"

namespace blink {

class ParagraphImplTxt : public ParagraphImpl {
 public:
  ~ParagraphImplTxt() override;

  explicit ParagraphImplTxt(std::unique_ptr<txt::Paragraph> paragraph);

  double width() override;
  double height() override;
  double minIntrinsicWidth() override;
  double maxIntrinsicWidth() override;
  double alphabeticBaseline() override;
  double ideographicBaseline() override;
  bool didExceedMaxLines() override;

  void layout(double width) override;
  void paint(Canvas* canvas, double x, double y) override;

  std::vector<TextBox> getRectsForRange(
      unsigned start,
      unsigned end,
      txt::Paragraph::RectHeightStyle rect_height_style,
      txt::Paragraph::RectWidthStyle rect_width_style) override;
  Dart_Handle getPositionForOffset(double dx, double dy) override;
  Dart_Handle getWordBoundary(unsigned offset) override;

 private:
  std::unique_ptr<txt::Paragraph> m_paragraph;
  double m_width = -1.0;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_IMPL_TXT_H_
