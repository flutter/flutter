/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/core/rendering/RenderTreeAsText.h"

#include "flutter/sky/engine/core/rendering/InlineTextBox.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/wtf/HexNumber.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"

namespace blink {

String quoteAndEscapeNonPrintables(const String& s) {
  StringBuilder result;
  result.append('"');
  for (unsigned i = 0; i != s.length(); ++i) {
    UChar c = s[i];
    if (c == '\\') {
      result.append('\\');
      result.append('\\');
    } else if (c == '"') {
      result.append('\\');
      result.append('"');
    } else if (c == '\n' || c == noBreakSpace)
      result.append(' ');
    else {
      if (c >= 0x20 && c < 0x7F)
        result.append(c);
      else {
        result.append('\\');
        result.append('x');
        result.append('{');
        appendUnsignedAsHex(c, result);
        result.append('}');
      }
    }
  }
  result.append('"');
  return result.toString();
}

void RenderTreeAsText::writeRenderObject(TextStream& ts,
                                         const RenderObject& o,
                                         RenderAsTextBehavior behavior) {}

static void writeTextRun(TextStream& ts,
                         const RenderText& o,
                         const InlineTextBox& run) {
  // FIXME: For now use an "enclosingIntRect" model for x, y and logicalWidth,
  // although this makes it harder to detect any changes caused by the
  // conversion to floating point. :(
  int x = run.x();
  int y = run.y();
  int logicalWidth = ceilf(run.left() + run.logicalWidth()) - x;

  ts << "text run at (" << x << "," << y << ") width " << logicalWidth;
  if (!run.isLeftToRightDirection() || run.dirOverride()) {
    ts << (!run.isLeftToRightDirection() ? " RTL" : " LTR");
    if (run.dirOverride())
      ts << " override";
  }
  ts << ": "
     << quoteAndEscapeNonPrintables(
            String(o.text()).substring(run.start(), run.len()));
  if (run.hasHyphen())
    ts << " + hyphen string "
       << quoteAndEscapeNonPrintables(o.style()->hyphenString());
  ts << "\n";
}

void write(TextStream& ts,
           const RenderObject& o,
           int indent,
           RenderAsTextBehavior behavior) {
  writeIndent(ts, indent);

  RenderTreeAsText::writeRenderObject(ts, o, behavior);
  ts << "\n";

  if (o.isText()) {
    const RenderText& text = toRenderText(o);
    for (InlineTextBox* box = text.firstTextBox(); box;
         box = box->nextTextBox()) {
      writeIndent(ts, indent + 1);
      writeTextRun(ts, text, *box);
    }
  }

  for (RenderObject* child = o.slowFirstChild(); child;
       child = child->nextSibling()) {
    if (child->hasLayer())
      continue;
    write(ts, *child, indent + 1, behavior);
  }
}

static void write(TextStream& ts,
                  RenderLayer& l,
                  const LayoutRect& layerBounds,
                  const LayoutRect& backgroundClipRect,
                  int indent = 0,
                  RenderAsTextBehavior behavior = RenderAsTextBehaviorNormal) {
  IntRect adjustedLayoutBounds = pixelSnappedIntRect(layerBounds);
  IntRect adjustedBackgroundClipRect = pixelSnappedIntRect(backgroundClipRect);

  writeIndent(ts, indent);

  ts << "layer ";

  if (behavior & RenderAsTextShowAddresses)
    ts << static_cast<const void*>(&l) << " ";

  ts << adjustedLayoutBounds;

  if (!adjustedLayoutBounds.isEmpty()) {
    if (!adjustedBackgroundClipRect.contains(adjustedLayoutBounds))
      ts << " backgroundClip " << adjustedBackgroundClipRect;
  }

  ts << "\n";
  write(ts, *l.renderer(), indent + 1, behavior);
}

void RenderTreeAsText::writeLayers(TextStream& ts,
                                   const RenderLayer* rootLayer,
                                   RenderLayer* layer,
                                   const LayoutRect& paintRect,
                                   int indent,
                                   RenderAsTextBehavior behavior) {
  // FIXME: Apply overflow to the root layer to not break every test. Complete
  // hack. Sigh.
  LayoutRect paintDirtyRect(paintRect);
  if (rootLayer == layer) {
    paintDirtyRect.setWidth(
        max<LayoutUnit>(paintDirtyRect.width(),
                        rootLayer->renderer()->layoutOverflowRect().maxX()));
    paintDirtyRect.setHeight(
        max<LayoutUnit>(paintDirtyRect.height(),
                        rootLayer->renderer()->layoutOverflowRect().maxY()));
  }

  // Calculate the clip rects we should use.
  LayoutRect layerBounds;
  ClipRect damageRect;
  layer->clipper().calculateRects(
      ClipRectsContext(rootLayer, UncachedClipRects), paintDirtyRect,
      layerBounds, damageRect);

  // FIXME: Apply overflow to the root layer to not break every test. Complete
  // hack. Sigh.
  if (rootLayer == layer)
    layerBounds.setSize(layer->size().expandedTo(pixelSnappedIntSize(
        layer->renderer()->maxLayoutOverflow(), LayoutPoint(0, 0))));

  // Ensure our lists are up-to-date.
  layer->stackingNode()->updateLayerListsIfNeeded();

  bool shouldPaint = (behavior & RenderAsTextShowAllLayers)
                         ? true
                         : layer->intersectsDamageRect(
                               layerBounds, damageRect.rect(), rootLayer);

  if (shouldPaint)
    write(ts, *layer, layerBounds, damageRect.rect(), indent, behavior);

  if (Vector<RenderLayerStackingNode*>* normalFlowList =
          layer->stackingNode()->normalFlowList()) {
    int currIndent = indent;
    if (behavior & RenderAsTextShowLayerNesting) {
      writeIndent(ts, indent);
      ts << " normal flow list(" << normalFlowList->size() << ")\n";
      ++currIndent;
    }
    for (unsigned i = 0; i != normalFlowList->size(); ++i)
      writeLayers(ts, rootLayer, normalFlowList->at(i)->layer(), paintDirtyRect,
                  currIndent, behavior);
  }

  if (Vector<RenderLayerStackingNode*>* posList =
          layer->stackingNode()->zOrderList()) {
    int currIndent = indent;
    if (behavior & RenderAsTextShowLayerNesting) {
      writeIndent(ts, indent);
      ts << " positive z-order list(" << posList->size() << ")\n";
      ++currIndent;
    }
    for (unsigned i = 0; i != posList->size(); ++i)
      writeLayers(ts, rootLayer, posList->at(i)->layer(), paintDirtyRect,
                  currIndent, behavior);
  }
}

}  // namespace blink
