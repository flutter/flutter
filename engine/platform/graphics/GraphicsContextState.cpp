// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/graphics/GraphicsContextState.h"

#include "platform/graphics/skia/SkiaUtils.h"

namespace blink {

GraphicsContextState::GraphicsContextState()
    : m_fillColor(Color::black)
    , m_fillRule(RULE_NONZERO)
    , m_textDrawingMode(TextModeFill)
    , m_alpha(256)
    , m_compositeOperator(CompositeSourceOver)
    , m_blendMode(WebBlendModeNormal)
    , m_interpolationQuality(InterpolationDefault)
    , m_saveCount(0)
    , m_shouldAntialias(true)
    , m_shouldClampToSourceRect(true)
{
    m_strokePaint.setStyle(SkPaint::kStroke_Style);
    m_strokePaint.setStrokeWidth(SkFloatToScalar(m_strokeData.thickness()));
    m_strokePaint.setColor(applyAlpha(m_strokeData.color().rgb()));
    m_strokePaint.setStrokeCap(SkPaint::kDefault_Cap);
    m_strokePaint.setStrokeJoin(SkPaint::kDefault_Join);
    m_strokePaint.setStrokeMiter(SkFloatToScalar(m_strokeData.miterLimit()));
    m_strokePaint.setFilterLevel(WebCoreInterpolationQualityToSkFilterLevel(m_interpolationQuality));
    m_strokePaint.setAntiAlias(m_shouldAntialias);
    m_fillPaint.setColor(applyAlpha(m_fillColor.rgb()));
    m_fillPaint.setFilterLevel(WebCoreInterpolationQualityToSkFilterLevel(m_interpolationQuality));
    m_fillPaint.setAntiAlias(m_shouldAntialias);
}

GraphicsContextState::GraphicsContextState(const GraphicsContextState& other)
    : m_strokePaint(other.m_strokePaint)
    , m_fillPaint(other.m_fillPaint)
    , m_strokeData(other.m_strokeData)
    , m_fillColor(other.m_fillColor)
    , m_fillRule(other.m_fillRule)
    , m_fillGradient(other.m_fillGradient)
    , m_fillPattern(other.m_fillPattern)
    , m_looper(other.m_looper)
    , m_textDrawingMode(other.m_textDrawingMode)
    , m_alpha(other.m_alpha)
    , m_colorFilter(other.m_colorFilter)
    , m_compositeOperator(other.m_compositeOperator)
    , m_blendMode(other.m_blendMode)
    , m_interpolationQuality(other.m_interpolationQuality)
    , m_saveCount(0)
    , m_shouldAntialias(other.m_shouldAntialias)
    , m_shouldClampToSourceRect(other.m_shouldClampToSourceRect) { }

void GraphicsContextState::copy(const GraphicsContextState& source)
{
    this->~GraphicsContextState();
    new (this) GraphicsContextState(source);
}

const SkPaint& GraphicsContextState::strokePaint(int strokedPathLength) const
{
    if (m_strokeData.gradient() && m_strokeData.gradient()->shaderChanged())
        m_strokePaint.setShader(m_strokeData.gradient()->shader());
    m_strokeData.setupPaintDashPathEffect(&m_strokePaint, strokedPathLength);
    return m_strokePaint;
}

const SkPaint& GraphicsContextState::fillPaint() const
{
    if (m_fillGradient && m_fillGradient->shaderChanged())
        m_fillPaint.setShader(m_fillGradient->shader());
    return m_fillPaint;
}

void GraphicsContextState::setStrokeStyle(StrokeStyle style)
{
    m_strokeData.setStyle(style);
}

void GraphicsContextState::setStrokeThickness(float thickness)
{
    m_strokeData.setThickness(thickness);
    m_strokePaint.setStrokeWidth(SkFloatToScalar(thickness));
}

void GraphicsContextState::setStrokeColor(const Color& color)
{
    m_strokeData.clearGradient();
    m_strokeData.clearPattern();
    m_strokeData.setColor(color);
    m_strokePaint.setColor(applyAlpha(color.rgb()));
    m_strokePaint.setShader(0);
}

void GraphicsContextState::setStrokeGradient(const PassRefPtr<Gradient> gradient)
{
    m_strokeData.setColor(Color::black);
    m_strokeData.clearPattern();
    m_strokeData.setGradient(gradient);
    m_strokePaint.setColor(applyAlpha(SK_ColorBLACK));
    m_strokePaint.setShader(m_strokeData.gradient()->shader());
}

void GraphicsContextState::clearStrokeGradient()
{
    m_strokeData.clearGradient();
    ASSERT(!m_strokeData.pattern());
    m_strokePaint.setColor(applyAlpha(m_strokeData.color().rgb()));
}

void GraphicsContextState::setStrokePattern(const PassRefPtr<Pattern> pattern)
{
    m_strokeData.setColor(Color::black);
    m_strokeData.clearGradient();
    m_strokeData.setPattern(pattern);
    m_strokePaint.setColor(applyAlpha(SK_ColorBLACK));
    m_strokePaint.setShader(m_strokeData.pattern()->shader());
}

void GraphicsContextState::clearStrokePattern()
{
    m_strokeData.clearPattern();
    ASSERT(!m_strokeData.gradient());
    m_strokePaint.setColor(applyAlpha(m_strokeData.color().rgb()));
}

void GraphicsContextState::setLineCap(LineCap cap)
{
    m_strokeData.setLineCap(cap);
    m_strokePaint.setStrokeCap((SkPaint::Cap)cap);
}

void GraphicsContextState::setLineJoin(LineJoin join)
{
    m_strokeData.setLineJoin(join);
    m_strokePaint.setStrokeJoin((SkPaint::Join)join);
}

void GraphicsContextState::setMiterLimit(float miterLimit)
{
    m_strokeData.setMiterLimit(miterLimit);
    m_strokePaint.setStrokeMiter(SkFloatToScalar(miterLimit));
}

void GraphicsContextState::setFillColor(const Color& color)
{
    m_fillColor = color;
    m_fillGradient.clear();
    m_fillPattern.clear();
    m_fillPaint.setColor(applyAlpha(color.rgb()));
    m_fillPaint.setShader(0);
}

void GraphicsContextState::setFillGradient(const PassRefPtr<Gradient> gradient)
{
    m_fillColor = Color::black;
    m_fillPattern.clear();
    m_fillGradient = gradient;
    m_fillPaint.setColor(applyAlpha(SK_ColorBLACK));
    m_fillPaint.setShader(m_fillGradient->shader());
}

void GraphicsContextState::clearFillGradient()
{
    m_fillGradient.clear();
    ASSERT(!m_fillPattern);
    m_fillPaint.setColor(applyAlpha(m_fillColor.rgb()));
}

void GraphicsContextState::setFillPattern(const PassRefPtr<Pattern> pattern)
{
    m_fillColor = Color::black;
    m_fillGradient.clear();
    m_fillPattern = pattern;
    m_fillPaint.setColor(applyAlpha(SK_ColorBLACK));
    m_fillPaint.setShader(m_fillPattern->shader());
}

void GraphicsContextState::clearFillPattern()
{
    m_fillPattern.clear();
    ASSERT(!m_fillGradient);
    m_fillPaint.setColor(applyAlpha(m_fillColor.rgb()));
}

// Shadow. (This will need tweaking if we use draw loopers for other things.)
void GraphicsContextState::setDrawLooper(PassRefPtr<SkDrawLooper> drawLooper)
{
    m_looper = drawLooper;
    m_strokePaint.setLooper(m_looper.get());
    m_fillPaint.setLooper(m_looper.get());
}

void GraphicsContextState::clearDrawLooper()
{
    m_looper.clear();
    m_strokePaint.setLooper(0);
    m_fillPaint.setLooper(0);
}

void GraphicsContextState::setAlphaAsFloat(float alpha)
{
    if (alpha < 0) {
        m_alpha = 0;
    } else {
        m_alpha = roundf(alpha * 256);
        if (m_alpha > 256)
            m_alpha = 256;
    }
    m_strokePaint.setColor(applyAlpha(m_strokeData.color().rgb()));
    m_fillPaint.setColor(applyAlpha(m_fillColor.rgb()));
}

void GraphicsContextState::setLineDash(const DashArray& dashes, float dashOffset)
{
    m_strokeData.setLineDash(dashes, dashOffset);
}

void GraphicsContextState::setColorFilter(PassRefPtr<SkColorFilter> colorFilter)
{
    m_colorFilter = colorFilter;
    m_strokePaint.setColorFilter(m_colorFilter.get());
    m_fillPaint.setColorFilter(m_colorFilter.get());
}

void GraphicsContextState::setCompositeOperation(CompositeOperator compositeOperation, WebBlendMode blendMode)
{
    m_compositeOperator = compositeOperation;
    m_blendMode = blendMode;
    SkXfermode::Mode xferMode = WebCoreCompositeToSkiaComposite(compositeOperation, blendMode);
    m_strokePaint.setXfermodeMode(xferMode);
    m_fillPaint.setXfermodeMode(xferMode);
}

void GraphicsContextState::setInterpolationQuality(InterpolationQuality quality)
{
    m_interpolationQuality = quality;
    m_strokePaint.setFilterLevel(WebCoreInterpolationQualityToSkFilterLevel(quality));
    m_fillPaint.setFilterLevel(WebCoreInterpolationQualityToSkFilterLevel(quality));
}

void GraphicsContextState::setShouldAntialias(bool shouldAntialias)
{
    m_shouldAntialias = shouldAntialias;
    m_strokePaint.setAntiAlias(shouldAntialias);
    m_fillPaint.setAntiAlias(shouldAntialias);
}


} // namespace blink
