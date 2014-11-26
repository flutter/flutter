// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderParagraph.h"

#include "sky/engine/core/rendering/InlineIterator.h"

namespace blink {

RenderParagraph::RenderParagraph(ContainerNode* node)
    : RenderBlockFlow(node)
{
}

RenderParagraph::~RenderParagraph()
{
}

RenderParagraph* RenderParagraph::createAnonymous(Document& document)
{
    RenderParagraph* renderer = new RenderParagraph(0);
    renderer->setDocumentForAnonymous(&document);
    return renderer;
}

void RenderParagraph::addOverflowFromChildren()
{
    LayoutUnit endPadding = hasOverflowClip() ? paddingEnd() : LayoutUnit();
    // FIXME: Need to find another way to do this, since scrollbars could show when we don't want them to.
    if (hasOverflowClip() && !endPadding && node() && node()->isRootEditableElement() && style()->isLeftToRightDirection())
        endPadding = 1;
    for (RootInlineBox* curr = firstRootBox(); curr; curr = curr->nextRootBox()) {
        addLayoutOverflow(curr->paddedLayoutOverflowRect(endPadding));
        LayoutRect visualOverflow = curr->visualOverflowRect(curr->lineTop(), curr->lineBottom());
        addContentsVisualOverflow(visualOverflow);
    }
}

void RenderParagraph::simplifiedNormalFlowLayout()
{
      ListHashSet<RootInlineBox*> lineBoxes;
      for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
          RenderObject* o = walker.current();
          if (!o->isOutOfFlowPositioned() && o->isReplaced()) {
              o->layoutIfNeeded();
              if (toRenderBox(o)->inlineBoxWrapper()) {
                  RootInlineBox& box = toRenderBox(o)->inlineBoxWrapper()->root();
                  lineBoxes.add(&box);
              }
          } else if (o->isText() || (o->isRenderInline() && !walker.atEndOfInline())) {
              o->clearNeedsLayout();
          }
      }

      // FIXME: Glyph overflow will get lost in this case, but not really a big deal.
      GlyphOverflowAndFallbackFontsMap textBoxDataMap;
      for (ListHashSet<RootInlineBox*>::const_iterator it = lineBoxes.begin(); it != lineBoxes.end(); ++it) {
          RootInlineBox* box = *it;
          box->computeOverflow(box->lineTop(), box->lineBottom(), textBoxDataMap);
      }
}

void RenderParagraph::paintContents(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    m_lineBoxes.paint(this, paintInfo, paintOffset);
}

bool RenderParagraph::hitTestContents(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction hitTestAction)
{
    return m_lineBoxes.hitTest(this, request, result, locationInContainer, accumulatedOffset, hitTestAction);
}


} // namespace blink
