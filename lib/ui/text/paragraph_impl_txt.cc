// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_impl_txt.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "lib/ftl/tasks/task_runner.h"

namespace blink {

ParagraphImplTxt::ParagraphImplTxt(std::unique_ptr<txt::Paragraph> paragraph)
    : m_paragraph(std::move(paragraph)) {}

ParagraphImplTxt::~ParagraphImplTxt() {}

double ParagraphImplTxt::width() {
  return m_width;
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

std::vector<TextBox> ParagraphImplTxt::getRectsForRange(unsigned start,
                                                        unsigned end) {
  return std::vector<TextBox>{0ull};
}

Dart_Handle ParagraphImplTxt::getPositionForOffset(double dx, double dy) {
  // TODO(garyq): Implement in the library.
  return nullptr;
}

Dart_Handle ParagraphImplTxt::getWordBoundary(unsigned offset) {
  // TODO(garyq): Implement in the library.
  return nullptr;
}

}  // namespace blink
