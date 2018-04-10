// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"
#include "flutter/sky/engine/platform/text/TextBoundaries.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "lib/fxl/logging.h"
#include "lib/fxl/tasks/task_runner.h"
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
  V(Paragraph, didExceedMaxLines)   \
  V(Paragraph, layout)              \
  V(Paragraph, paint)               \
  V(Paragraph, getWordBoundary)     \
  V(Paragraph, getRectsForRange)    \
  V(Paragraph, getPositionForOffset)

DART_BIND_ALL(Paragraph, FOR_EACH_BINDING)

Paragraph::Paragraph(PassOwnPtr<RenderView> renderView)
    : m_paragraphImpl(std::make_unique<ParagraphImplBlink>(renderView)) {}

Paragraph::Paragraph(std::unique_ptr<txt::Paragraph> paragraph)
    : m_paragraphImpl(
          std::make_unique<ParagraphImplTxt>(std::move(paragraph))) {}

Paragraph::~Paragraph() {
  if (m_renderView) {
    RenderView* renderView = m_renderView.leakPtr();
    destruction_task_runner_->PostTask(
        [renderView]() { renderView->destroy(); });
  }
}

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

std::vector<TextBox> Paragraph::getRectsForRange(unsigned start, unsigned end) {
  return m_paragraphImpl->getRectsForRange(start, end);
}

Dart_Handle Paragraph::getPositionForOffset(double dx, double dy) {
  return m_paragraphImpl->getPositionForOffset(dx, dy);
}

Dart_Handle Paragraph::getWordBoundary(unsigned offset) {
  return m_paragraphImpl->getWordBoundary(offset);
}

}  // namespace blink
