// Copyright (C) 2013 Google Inc. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef StrokeData_h
#define StrokeData_h

#include "platform/PlatformExport.h"
#include "platform/graphics/DashArray.h"
#include "platform/graphics/Gradient.h"
#include "platform/graphics/GraphicsTypes.h"
#include "platform/graphics/Pattern.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/effects/SkDashPathEffect.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

// Encapsulates stroke painting information.
// It is pulled out of GraphicsContextState to enable other methods to use it.
class PLATFORM_EXPORT StrokeData {
public:
    StrokeData()
        : m_style(SolidStroke)
        , m_thickness(0)
        , m_color(Color::black)
        , m_lineCap(SkPaint::kDefault_Cap)
        , m_lineJoin(SkPaint::kDefault_Join)
        , m_miterLimit(4)
    {
    }

    StrokeStyle style() const { return m_style; }
    void setStyle(StrokeStyle style) { m_style = style; }

    float thickness() const { return m_thickness; }
    void setThickness(float thickness) { m_thickness = thickness; }

    Color color() const { return m_color; }
    void setColor(const Color& color) { m_color = color; }

    Gradient* gradient() const { return m_gradient.get(); }
    void setGradient(const PassRefPtr<Gradient> gradient) { m_gradient = gradient; }
    void clearGradient() { m_gradient.clear(); }

    Pattern* pattern() const { return m_pattern.get(); }
    void setPattern(const PassRefPtr<Pattern> pattern) { m_pattern = pattern; }
    void clearPattern() { m_pattern.clear(); }

    LineCap lineCap() const { return (LineCap)m_lineCap; }
    void setLineCap(LineCap cap) { m_lineCap = (SkPaint::Cap)cap; }

    LineJoin lineJoin() const { return (LineJoin)m_lineJoin; }
    void setLineJoin(LineJoin join) { m_lineJoin = (SkPaint::Join)join; }

    float miterLimit() const { return m_miterLimit; }
    void setMiterLimit(float miterLimit) { m_miterLimit = miterLimit; }

    void setLineDash(const DashArray&, float);

    // Sets everything on the paint except the pattern, gradient and color.
    // If a non-zero length is provided, the number of dashes/dots on a
    // dashed/dotted line will be adjusted to start and end that length with a
    // dash/dot.
    void setupPaint(SkPaint*, int length = 0) const;

    // Setup any DashPathEffect on the paint. If a non-zero length is provided,
    // and no line dash has been set, the number of dashes/dots on a dashed/dotted
    // line will be adjusted to start and end that length with a dash/dot.
    void setupPaintDashPathEffect(SkPaint*, int) const;

private:
    StrokeStyle m_style;
    float m_thickness;
    Color m_color;
    RefPtr<Gradient> m_gradient;
    RefPtr<Pattern> m_pattern;
    SkPaint::Cap m_lineCap;
    SkPaint::Join m_lineJoin;
    float m_miterLimit;
    RefPtr<SkDashPathEffect> m_dash;
};

} // namespace blink

#endif // StrokeData_h
