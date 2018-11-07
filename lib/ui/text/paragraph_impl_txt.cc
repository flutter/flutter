// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_impl_txt.h"

#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/tonic/converter/dart_converter.h"

using tonic::ToDart;

namespace blink {

ParagraphImplTxt::ParagraphImplTxt(std::unique_ptr<txt::Paragraph> paragraph)
    : m_paragraph(std::move(paragraph)) {}

ParagraphImplTxt::~ParagraphImplTxt() {}

double ParagraphImplTxt::width() {
  return m_paragraph->GetMaxWidth();
}

double ParagraphImplTxt::height() {
  return m_paragraph->GetHeight();
}

double ParagraphImplTxt::minIntrinsicWidth() {
  return m_paragraph->GetMinIntrinsicWidth();
}

double ParagraphImplTxt::maxIntrinsicWidth() {
  return m_paragraph->GetMaxIntrinsicWidth();
}

double ParagraphImplTxt::alphabeticBaseline() {
  return m_paragraph->GetAlphabeticBaseline();
}

double ParagraphImplTxt::ideographicBaseline() {
  return m_paragraph->GetIdeographicBaseline();
}

bool ParagraphImplTxt::didExceedMaxLines() {
  return m_paragraph->DidExceedMaxLines();
}

void ParagraphImplTxt::layout(double width) {
  m_width = width;
  m_paragraph->Layout(width);
}

void ParagraphImplTxt::paint(Canvas* canvas, double x, double y) {
  SkCanvas* sk_canvas = canvas->canvas();
  if (!sk_canvas)
    return;
  m_paragraph->Paint(sk_canvas, x, y);
}

std::vector<TextBox> ParagraphImplTxt::getRectsForRange(
    unsigned start,
    unsigned end,
    txt::Paragraph::RectHeightStyle rect_height_style,
    txt::Paragraph::RectWidthStyle rect_width_style) {
  std::vector<TextBox> result;
  std::vector<txt::Paragraph::TextBox> boxes = m_paragraph->GetRectsForRange(
      start, end, rect_height_style, rect_width_style);
  for (const txt::Paragraph::TextBox& box : boxes) {
    result.emplace_back(box.rect,
                        static_cast<blink::TextDirection>(box.direction));
  }
  return result;
}

Dart_Handle ParagraphImplTxt::getPositionForOffset(double dx, double dy) {
  Dart_Handle result = Dart_NewListOf(Dart_CoreType_Int, 2);
  txt::Paragraph::PositionWithAffinity pos =
      m_paragraph->GetGlyphPositionAtCoordinate(dx, dy);
  Dart_ListSetAt(result, 0, ToDart(pos.position));
  Dart_ListSetAt(result, 1, ToDart(static_cast<int>(pos.affinity)));
  return result;
}

Dart_Handle ParagraphImplTxt::getWordBoundary(unsigned offset) {
  txt::Paragraph::Range<size_t> point = m_paragraph->GetWordBoundary(offset);
  Dart_Handle result = Dart_NewListOf(Dart_CoreType_Int, 2);
  Dart_ListSetAt(result, 0, ToDart(point.start));
  Dart_ListSetAt(result, 1, ToDart(point.end));
  return result;
}

}  // namespace blink
