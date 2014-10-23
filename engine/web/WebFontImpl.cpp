/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "web/WebFontImpl.h"

#include "platform/fonts/FontCache.h"
#include "platform/fonts/FontDescription.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/text/TextRun.h"
#include "public/platform/WebFloatPoint.h"
#include "public/platform/WebFloatRect.h"
#include "public/platform/WebRect.h"
#include "public/web/WebFontDescription.h"
#include "public/web/WebTextRun.h"
#include <skia/ext/platform_canvas.h>

namespace blink {

WebFont* WebFont::create(const WebFontDescription& desc)
{
    return new WebFontImpl(desc);
}

WebFontImpl::WebFontImpl(const FontDescription& desc)
    : m_font(desc)
{
    m_font.update(nullptr);
}

WebFontDescription WebFontImpl::fontDescription() const
{
    return WebFontDescription(m_font.fontDescription());
}

int WebFontImpl::ascent() const
{
    return m_font.fontMetrics().ascent();
}

int WebFontImpl::descent() const
{
    return m_font.fontMetrics().descent();
}

int WebFontImpl::height() const
{
    return m_font.fontMetrics().height();
}

int WebFontImpl::lineSpacing() const
{
    return m_font.fontMetrics().lineSpacing();
}

float WebFontImpl::xHeight() const
{
    return m_font.fontMetrics().xHeight();
}

void WebFontImpl::drawText(WebCanvas* canvas, const WebTextRun& run, const WebFloatPoint& leftBaseline,
                           WebColor color, const WebRect& clip, bool canvasIsOpaque,
                           int from, int to) const
{
    FontCachePurgePreventer fontCachePurgePreventer;
    FloatRect textClipRect(clip);
    TextRun textRun(run);
    TextRunPaintInfo runInfo(textRun);
    runInfo.from = from;
    runInfo.to = to == -1 ? textRun.length() : to;
    runInfo.bounds = textClipRect;
    GraphicsContext gc(canvas);

    gc.save();
    gc.setCertainlyOpaque(canvasIsOpaque);
    gc.setFillColor(color);
    gc.clip(textClipRect);
    m_font.drawText(&gc, runInfo, leftBaseline);
    gc.restore();
}

int WebFontImpl::calculateWidth(const WebTextRun& run) const
{
    FontCachePurgePreventer fontCachePurgePreventer;
    return m_font.width(run, 0);
}

int WebFontImpl::offsetForPosition(const WebTextRun& run, float position) const
{
    FontCachePurgePreventer fontCachePurgePreventer;
    return m_font.offsetForPosition(run, position, true);
}

WebFloatRect WebFontImpl::selectionRectForText(const WebTextRun& run, const WebFloatPoint& leftBaseline, int height, int from, int to) const
{
    FontCachePurgePreventer fontCachePurgePreventer;
    return m_font.selectionRectForText(run, leftBaseline, height, from, to);
}

} // namespace blink
