// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/task_runner.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

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
  V(Paragraph, didExceedMaxLines)   \
  V(Paragraph, layout)              \
  V(Paragraph, paint)               \
  V(Paragraph, getWordBoundary)     \
  V(Paragraph, getRectsForRange)    \
  V(Paragraph, getPositionForOffset)

DART_BIND_ALL(Paragraph, FOR_EACH_BINDING)

Paragraph::Paragraph(std::unique_ptr<txt::Paragraph> paragraph)
    : m_paragraphImpl(
          std::make_unique<ParagraphImplTxt>(std::move(paragraph))) {}

Paragraph::~Paragraph() = default;

size_t Paragraph::GetAllocationSize() {
  // We don't have an accurate accounting of the paragraph's memory consumption,
  // so return a fixed size to indicate that its impact is more than the size
  // of the Paragraph class.
  return 2000;
}

double Paragraph::width() {
  return m_paragraphImpl->width();
}

double Paragraph::height() {
  return m_paragraphImpl->height();
}

double Paragraph::minIntrinsicWidth() {
  return m_paragraphImpl->minIntrinsicWidth();
}

double Paragraph::maxIntrinsicWidth() {
  return m_paragraphImpl->maxIntrinsicWidth();
}

double Paragraph::alphabeticBaseline() {
  return m_paragraphImpl->alphabeticBaseline();
}

double Paragraph::ideographicBaseline() {
  return m_paragraphImpl->ideographicBaseline();
}

bool Paragraph::didExceedMaxLines() {
  return m_paragraphImpl->didExceedMaxLines();
}

void Paragraph::layout(double width) {
  m_paragraphImpl->layout(width);
}

void Paragraph::paint(Canvas* canvas, double x, double y) {
  m_paragraphImpl->paint(canvas, x, y);
}

std::vector<TextBox> Paragraph::getRectsForRange(unsigned start,
                                                 unsigned end,
                                                 unsigned boxHeightStyle,
                                                 unsigned boxWidthStyle) {
  return m_paragraphImpl->getRectsForRange(
      start, end, static_cast<txt::Paragraph::RectHeightStyle>(boxHeightStyle),
      static_cast<txt::Paragraph::RectWidthStyle>(boxWidthStyle));
}

Dart_Handle Paragraph::getPositionForOffset(double dx, double dy) {
  return m_paragraphImpl->getPositionForOffset(dx, dy);
}

Dart_Handle Paragraph::getWordBoundary(unsigned offset) {
  return m_paragraphImpl->getWordBoundary(offset);
}

}  // namespace blink
