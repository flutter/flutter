// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/tonic/dart_args.h"
#include "sky/engine/tonic/dart_binding_macros.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_library_natives.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(Paragraph);

#define FOR_EACH_BINDING(V) \
  V(Paragraph, minWidth) \
  V(Paragraph, setMinWidth) \
  V(Paragraph, maxWidth) \
  V(Paragraph, setMaxWidth) \
  V(Paragraph, minHeight) \
  V(Paragraph, setMinHeight) \
  V(Paragraph, maxHeight) \
  V(Paragraph, setMaxHeight) \
  V(Paragraph, width) \
  V(Paragraph, height) \
  V(Paragraph, minIntrinsicWidth) \
  V(Paragraph, maxIntrinsicWidth) \
  V(Paragraph, alphabeticBaseline) \
  V(Paragraph, ideographicBaseline) \
  V(Paragraph, layout) \
  V(Paragraph, paint)

DART_BIND_ALL(Paragraph, FOR_EACH_BINDING)

Paragraph::Paragraph(PassOwnPtr<RenderView> renderView)
    : m_renderView(renderView)
{
}

Paragraph::~Paragraph()
{
}

double Paragraph::width()
{
    return firstChildBox()->width();
}

double Paragraph::height()
{
    return firstChildBox()->height();
}

double Paragraph::minIntrinsicWidth()
{
    return firstChildBox()->minPreferredLogicalWidth();
}

double Paragraph::maxIntrinsicWidth()
{
    return firstChildBox()->maxPreferredLogicalWidth();
}

double Paragraph::alphabeticBaseline()
{
    return firstChildBox()->firstLineBoxBaseline(FontBaselineOrAuto(AlphabeticBaseline));
}

double Paragraph::ideographicBaseline()
{
    return firstChildBox()->firstLineBoxBaseline(FontBaselineOrAuto(IdeographicBaseline));
}

void Paragraph::layout()
{
    FontCachePurgePreventer fontCachePurgePreventer;

    LayoutUnit maxWidth = std::max(m_minWidth, m_maxWidth);
    LayoutUnit maxHeight = std::max(m_minHeight, m_maxHeight);
    m_renderView->setFrameViewSize(IntSize(maxWidth, maxHeight));
    m_renderView->layout();
}

void Paragraph::paint(Canvas* canvas, const Offset& offset)
{
    FontCachePurgePreventer fontCachePurgePreventer;

    // Very simplified painting to allow painting an arbitrary (layer-less) subtree.
    RenderBox* box = firstChildBox();
    SkCanvas* skCanvas = canvas->skCanvas();
    skCanvas->translate(offset.sk_size.width(), offset.sk_size.height());

    GraphicsContext context(skCanvas);
    Vector<RenderBox*> layers;
    LayoutRect bounds = box->absoluteBoundingBoxRect();
    DCHECK(bounds.x() == 0 && bounds.y() == 0);
    PaintInfo paintInfo(&context, enclosingIntRect(bounds), box);
    box->paint(paintInfo, LayoutPoint(), layers);
    // Note we're ignoring any layers encountered.
    // TODO(abarth): Remove the concept of RenderLayers.

    skCanvas->translate(-offset.sk_size.width(), -offset.sk_size.height());
}

} // namespace blink
