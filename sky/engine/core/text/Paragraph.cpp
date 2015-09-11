// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {

Paragraph::Paragraph(PassOwnPtr<RenderView> renderView)
    : m_renderView(renderView)
{
}

Paragraph::~Paragraph()
{
}

double Paragraph::width()
{
    return m_renderView->firstChildBox()->width();
}

double Paragraph::height()
{
    return m_renderView->firstChildBox()->height();
}

double Paragraph::minIntrinsicWidth()
{
    return 0.0;
}

double Paragraph::maxIntrinsicWidth()
{
    return 0.0;
}

double Paragraph::alphabeticBaseline()
{
    return 0.0;
}

double Paragraph::ideographicBaseline()
{
    return 0.0;
}

void Paragraph::layout()
{
    LayoutUnit maxWidth = std::max(m_minWidth, m_maxWidth);
    LayoutUnit maxHeight = std::max(m_minHeight, m_maxHeight);
    IntSize maxSize(maxWidth, maxHeight);

    m_renderView->setFrameViewSize(maxSize);
    m_renderView->layout();
}

void Paragraph::paint(Canvas* canvas, const Offset& offset)
{
}

} // namespace blink
