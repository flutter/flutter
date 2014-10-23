/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/CSSToLengthConversionData.h"

#include "core/rendering/RenderView.h"
#include "core/rendering/style/RenderStyle.h"

namespace blink {

CSSToLengthConversionData::CSSToLengthConversionData(const RenderStyle* style, const RenderStyle* rootStyle, const RenderView* renderView, float zoom, bool computingFontSize)
    : m_style(style)
    , m_rootStyle(rootStyle)
    , m_viewportWidth(renderView ? renderView->layoutViewportWidth() : 0)
    , m_viewportHeight(renderView ? renderView->layoutViewportHeight() : 0)
    , m_zoom(zoom)
    , m_useEffectiveZoom(false)
    , m_computingFontSize(computingFontSize)
{
    ASSERT(zoom > 0);
}

CSSToLengthConversionData::CSSToLengthConversionData(const RenderStyle* style, const RenderStyle* rootStyle, const RenderView* renderView, bool computingFontSize)
    : m_style(style)
    , m_rootStyle(rootStyle)
    , m_viewportWidth(renderView ? renderView->layoutViewportWidth() : 0)
    , m_viewportHeight(renderView ? renderView->layoutViewportHeight() : 0)
    , m_useEffectiveZoom(true)
    , m_computingFontSize(computingFontSize)
{
}

CSSToLengthConversionData::CSSToLengthConversionData(const RenderStyle* style, const RenderStyle* rootStyle, float viewportWidth, float viewportHeight, float zoom, bool computingFontSize)
    : m_style(style)
    , m_rootStyle(rootStyle)
    , m_viewportWidth(viewportWidth)
    , m_viewportHeight(viewportHeight)
    , m_zoom(zoom)
    , m_useEffectiveZoom(false)
    , m_computingFontSize(computingFontSize)
{
    ASSERT(zoom > 0);
}

float CSSToLengthConversionData::zoom() const
{
    if (m_useEffectiveZoom)
        return m_style ? m_style->effectiveZoom() : 1;
    return m_zoom;
}

double CSSToLengthConversionData::viewportWidthPercent() const
{
    m_style->setHasViewportUnits();
    return m_viewportWidth / 100;
}
double CSSToLengthConversionData::viewportHeightPercent() const
{
    m_style->setHasViewportUnits();
    return m_viewportHeight / 100;
}
double CSSToLengthConversionData::viewportMinPercent() const
{
    m_style->setHasViewportUnits();
    return std::min(m_viewportWidth, m_viewportHeight) / 100;
}
double CSSToLengthConversionData::viewportMaxPercent() const
{
    m_style->setHasViewportUnits();
    return std::max(m_viewportWidth, m_viewportHeight) / 100;
}

} // namespace blink
