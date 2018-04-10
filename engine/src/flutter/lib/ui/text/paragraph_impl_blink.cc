// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_impl_blink.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"
#include "flutter/sky/engine/platform/text/TextBoundaries.h"
#include "lib/fxl/tasks/task_runner.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace blink {

ParagraphImplBlink::ParagraphImplBlink(PassOwnPtr<RenderView> renderView)
    : m_renderView(renderView) {}

ParagraphImplBlink::~ParagraphImplBlink() {
  if (m_renderView) {
    RenderView* renderView = m_renderView.leakPtr();
    Threads::UI()->PostTask([renderView]() { renderView->destroy(); });
  }
}

double ParagraphImplBlink::width() {
  return firstChildBox()->width();
}

double ParagraphImplBlink::height() {
  return firstChildBox()->height();
}

double ParagraphImplBlink::minIntrinsicWidth() {
  return firstChildBox()->minPreferredLogicalWidth();
}

double ParagraphImplBlink::maxIntrinsicWidth() {
  return firstChildBox()->maxPreferredLogicalWidth();
}

double ParagraphImplBlink::alphabeticBaseline() {
  return firstChildBox()->firstLineBoxBaseline(
      FontBaselineOrAuto(AlphabeticBaseline));
}

double ParagraphImplBlink::ideographicBaseline() {
  return firstChildBox()->firstLineBoxBaseline(
      FontBaselineOrAuto(IdeographicBaseline));
}

bool ParagraphImplBlink::didExceedMaxLines() {
  RenderBox* box = firstChildBox();
  ASSERT(box->isRenderParagraph());
  RenderParagraph* paragraph = static_cast<RenderParagraph*>(box);
  return paragraph->didExceedMaxLines();
}

void ParagraphImplBlink::layout(double width) {
  FontCachePurgePreventer fontCachePurgePreventer;

  int maxWidth = LayoutUnit(width);  // Handles infinity properly.
  m_renderView->setFrameViewSize(IntSize(maxWidth, intMaxForLayoutUnit));
  m_renderView->layout();
}

void ParagraphImplBlink::paint(Canvas* canvas, double x, double y) {
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
  FXL_DCHECK(bounds.x() == 0 && bounds.y() == 0);
  PaintInfo paintInfo(&context, enclosingIntRect(bounds), box);
  box->paint(paintInfo, LayoutPoint(), layers);
  // Note we're ignoring any layers encountered.
  // TODO(abarth): Remove the concept of RenderLayers.

  skCanvas->translate(-x, -y);
}

std::vector<TextBox> ParagraphImplBlink::getRectsForRange(unsigned start,
                                                          unsigned end) {
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

int ParagraphImplBlink::absoluteOffsetForPosition(
    const PositionWithAffinity& position) {
  FXL_DCHECK(position.renderer());
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
  FXL_DCHECK(false);
  return 0;
}

Dart_Handle ParagraphImplBlink::getPositionForOffset(double dx, double dy) {
  LayoutPoint point(dx, dy);
  PositionWithAffinity position = m_renderView->positionForPoint(point);
  Dart_Handle result = Dart_NewListOf(Dart_CoreType_Int, 2);
  Dart_ListSetAt(result, 0, ToDart(absoluteOffsetForPosition(position)));
  Dart_ListSetAt(result, 1, ToDart(static_cast<int>(position.affinity())));
  return result;
}

Dart_Handle ParagraphImplBlink::getWordBoundary(unsigned offset) {
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

  Dart_Handle result = Dart_NewListOf(Dart_CoreType_Int, 2);
  Dart_ListSetAt(result, 0, ToDart(start));
  Dart_ListSetAt(result, 1, ToDart(end));
  return result;
}

}  // namespace blink
