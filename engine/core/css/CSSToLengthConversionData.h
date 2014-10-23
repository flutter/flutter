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

#ifndef CSSToLengthConversionData_h
#define CSSToLengthConversionData_h

#include "wtf/Assertions.h"
#include "wtf/Noncopyable.h"

namespace blink {

class RenderStyle;
class RenderView;

class CSSToLengthConversionData {
public:
    CSSToLengthConversionData(const RenderStyle* currStyle, const RenderStyle* rootStyle, const RenderView*, float zoom, bool computingFontSize = false);
    CSSToLengthConversionData(const RenderStyle* currStyle, const RenderStyle* rootStyle, const RenderView*, bool computingFontSize = false);
    CSSToLengthConversionData(const RenderStyle* currStyle, const RenderStyle* rootStyle, float viewportWidth, float viewportHeight, float zoom, bool computingFontSize = false);

    const RenderStyle& style() const { return *m_style; }
    const RenderStyle* rootStyle() const { return m_rootStyle; }
    float zoom() const;
    bool computingFontSize() const { return m_computingFontSize; }

    // Accessing these marks the style as having viewport units
    double viewportWidthPercent() const;
    double viewportHeightPercent() const;
    double viewportMinPercent() const;
    double viewportMaxPercent() const;

    void setStyle(const RenderStyle* style) { m_style = style; }
    void setRootStyle(const RenderStyle* rootStyle) { m_rootStyle = rootStyle; }

    CSSToLengthConversionData copyWithAdjustedZoom(float newZoom) const
    {
        return CSSToLengthConversionData(m_style, m_rootStyle, m_viewportWidth, m_viewportHeight, newZoom, m_computingFontSize);
    }

private:
    const RenderStyle* m_style;
    const RenderStyle* m_rootStyle;
    float m_viewportWidth;
    float m_viewportHeight;
    float m_zoom;
    bool m_useEffectiveZoom;
    bool m_computingFontSize;
};

} // namespace blink

#endif
