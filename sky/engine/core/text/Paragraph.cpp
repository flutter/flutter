// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

#include "base/location.h"
#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "lib/tonic/converter/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/text/TextBoundaries.h"
#include "sky/engine/public/platform/Platform.h"

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

Paragraph::Paragraph(PassOwnPtr<RenderView> renderView)
    : m_renderView(renderView) {}

Paragraph::~Paragraph() {
  base::SingleThreadTaskRunner* runner = Platform::current()->GetUITaskRunner();
  runner->DeleteSoon(FROM_HERE, m_renderView.leakPtr());
}

double Paragraph::width() {
  return firstChildBox()->width();
}

double Paragraph::height() {
  return firstChildBox()->height();
}

double Paragraph::minIntrinsicWidth() {
  return firstChildBox()->minPreferredLogicalWidth();
}

double Paragraph::maxIntrinsicWidth() {
  return firstChildBox()->maxPreferredLogicalWidth();
}

double Paragraph::alphabeticBaseline() {
  return firstChildBox()->firstLineBoxBaseline(
      FontBaselineOrAuto(AlphabeticBaseline));
}

double Paragraph::ideographicBaseline() {
  return firstChildBox()->firstLineBoxBaseline(
      FontBaselineOrAuto(IdeographicBaseline));
}

void Paragraph::layout(double width) {
  FontCachePurgePreventer fontCachePurgePreventer;

  int maxWidth = LayoutUnit(width);  // Handles infinity properly.
  m_renderView->setFrameViewSize(IntSize(maxWidth, intMaxForLayoutUnit));
  m_renderView->layout();
}

void Paragraph::paint(Canvas* canvas, double x, double y) {
  SkCanvas* skCanvas = canvas->canvas();
  if (!skCanvas)
    return;

  FontCachePurgePreventer fontCachePurgePreventer;

  // Very simplified painting to allow painting an arbitrary (layer-less)
  // subtree.
  RenderBox* box = firstChildBox();
  skCanvas->translate(x, y);

  GraphicsContext context(skCanvas);
  Vector<RenderBox*> layers;
  LayoutRect bounds = box->absoluteBoundingBoxRect();
  DCHECK(bounds.x() == 0 && bounds.y() == 0);
  PaintInfo paintInfo(&context, enclosingIntRect(bounds), box);
  box->paint(paintInfo, LayoutPoint(), layers);
  // Note we're ignoring any layers encountered.
  // TODO(abarth): Remove the concept of RenderLayers.

  skCanvas->translate(-x, -y);
}

std::vector<TextBox> Paragraph::getRectsForRange(unsigned start, unsigned end) {
  if (end <= start || start == end)
    return std::vector<TextBox>();

  unsigned offset = 0;
  std::vector<TextBox> boxes;
  for (RenderObject* object = m_renderView.get(); object;
       object = object->nextInPreOrder()) {
    if (!object->isText())
      continue;
    RenderText* text = toRenderText(object);
    unsigned length = text->textLength();
    if (offset + length > start) {
      unsigned startOffset = offset > start ? 0 : start - offset;
      unsigned endOffset = end - offset;
      text->appendAbsoluteTextBoxesForRange(boxes, startOffset, endOffset);
    }
    offset += length;
    if (offset >= end)
      break;
  }

  return boxes;
}

int Paragraph::absoluteOffsetForPosition(const PositionWithAffinity& position) {
  DCHECK(position.renderer());
  unsigned offset = 0;
  for (RenderObject* object = m_renderView.get(); object;
       object = object->nextInPreOrder()) {
    if (object == position.renderer())
      return offset + position.offset();
    if (object->isText()) {
      RenderText* text = toRenderText(object);
      offset += text->textLength();
    }
  }
  DCHECK(false);
  return 0;
}

Dart_Handle Paragraph::getPositionForOffset(double dx, double dy) {
  LayoutPoint point(dx, dy);
  PositionWithAffinity position = m_renderView->positionForPoint(point);
  Dart_Handle result = Dart_NewList(2);
  Dart_ListSetAt(result, 0, ToDart(absoluteOffsetForPosition(position)));
  Dart_ListSetAt(result, 1, ToDart(static_cast<int>(position.affinity())));
  return result;
}

Dart_Handle Paragraph::getWordBoundary(unsigned offset) {
  String text;
  int start = 0, end = 0;

  for (RenderObject* object = m_renderView.get(); object;
       object = object->nextInPreOrder()) {
    if (!object->isText())
      continue;
    RenderText* renderText = toRenderText(object);
    text.append(renderText->text());
  }

  TextBreakIterator* it = wordBreakIterator(text, 0, text.length());
  if (it) {
    end = it->following(offset);
    if (end < 0)
      end = it->last();
    start = it->previous();
  }

  Dart_Handle result = Dart_NewList(2);
  Dart_ListSetAt(result, 0, ToDart(start));
  Dart_ListSetAt(result, 1, ToDart(end));
  return result;
}

}  // namespace blink
