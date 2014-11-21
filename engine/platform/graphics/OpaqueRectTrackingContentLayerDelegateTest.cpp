/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"

#include "sky/engine/platform/graphics/OpaqueRectTrackingContentLayerDelegate.h"

#include "skia/ext/platform_canvas.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/graphics/Color.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/public/platform/WebFloatRect.h"
#include "sky/engine/public/platform/WebRect.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

struct PaintCallback {
    virtual void operator()(GraphicsContext&, const IntRect&) = 0;
};

class TestLayerPainterChromium : public GraphicsContextPainter {
public:
    TestLayerPainterChromium(PaintCallback& callback) : m_callback(callback) { }

    virtual void paint(GraphicsContext& context, const IntRect& contentRect) override
    {
        m_callback(context, contentRect);
    }

private:
    PaintCallback& m_callback;
};

// Paint callback functions

struct PaintFillOpaque : public PaintCallback {
    virtual void operator()(GraphicsContext& context, const IntRect& contentRect) override
    {
        Color opaque(255, 0, 0, 255);
        IntRect top(contentRect.x(), contentRect.y(), contentRect.width(), contentRect.height() / 2);
        IntRect bottom(contentRect.x(), contentRect.y() + contentRect.height() / 2, contentRect.width(), contentRect.height() / 2);
        context.fillRect(top, opaque);
        context.fillRect(bottom, opaque);
    }
};

struct PaintFillAlpha : public PaintCallback {
    virtual void operator()(GraphicsContext& context, const IntRect& contentRect) override
    {
        Color alpha(0, 0, 0, 0);
        context.fillRect(contentRect, alpha);
    }
};

struct PaintFillPartialOpaque : public PaintCallback {
    PaintFillPartialOpaque(IntRect opaqueRect)
        : m_opaqueRect(opaqueRect)
    {
    }

    virtual void operator()(GraphicsContext& context, const IntRect& contentRect) override
    {
        Color alpha(0, 0, 0, 0);
        context.fillRect(contentRect, alpha);

        IntRect fillOpaque = m_opaqueRect;
        fillOpaque.intersect(contentRect);

        Color opaque(255, 255, 255, 255);
        context.fillRect(fillOpaque, opaque);
    }

    IntRect m_opaqueRect;
};

#define EXPECT_EQ_RECT(a, b) \
    EXPECT_EQ(a.x, b.x); \
    EXPECT_EQ(a.width, b.width); \
    EXPECT_EQ(a.y, b.y); \
    EXPECT_EQ(a.height, b.height);

class OpaqueRectTrackingContentLayerDelegateTest : public testing::Test {
public:
    OpaqueRectTrackingContentLayerDelegateTest()
        : m_skCanvas(adoptPtr(skia::CreateBitmapCanvas(canvasRect().width, canvasRect().height, false)))
    {
    }

    SkCanvas* skCanvas() { return m_skCanvas.get(); }
    WebRect canvasRect() { return WebRect(0, 0, 400, 400); }

private:
    OwnPtr<SkCanvas> m_skCanvas;
};

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testOpaqueRectPresentAfterOpaquePaint)
{
    PaintFillOpaque fillOpaque;
    TestLayerPainterChromium painter(fillOpaque);

    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    WebFloatRect opaqueRect;
    delegate.paintContents(skCanvas(), canvasRect(), false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(0, 0, 400, 400), opaqueRect);
}

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testOpaqueRectNotPresentAfterNonOpaquePaint)
{
    PaintFillAlpha fillAlpha;
    TestLayerPainterChromium painter(fillAlpha);
    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    WebFloatRect opaqueRect;
    delegate.paintContents(skCanvas(), canvasRect(), false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(0, 0, 0, 0), opaqueRect);
}

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testOpaqueRectNotPresentForOpaqueLayerWithOpaquePaint)
{
    PaintFillOpaque fillOpaque;
    TestLayerPainterChromium painter(fillOpaque);
    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    delegate.setOpaque(true);

    WebFloatRect opaqueRect;
    delegate.paintContents(skCanvas(), canvasRect(), false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(0, 0, 0, 0), opaqueRect);
}

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testOpaqueRectNotPresentForOpaqueLayerWithNonOpaquePaint)
{
    PaintFillOpaque fillAlpha;
    TestLayerPainterChromium painter(fillAlpha);
    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    delegate.setOpaque(true);

    WebFloatRect opaqueRect;
    delegate.paintContents(skCanvas(), canvasRect(), false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(0, 0, 0, 0), opaqueRect);
}

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testPartialOpaqueRectNoTransform)
{
    IntRect partialRect(100, 200, 50, 75);
    PaintFillPartialOpaque fillPartial(partialRect);
    TestLayerPainterChromium painter(fillPartial);
    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    WebFloatRect opaqueRect;
    delegate.paintContents(skCanvas(), canvasRect(), false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(partialRect.x(), partialRect.y(), partialRect.width(), partialRect.height()), opaqueRect);
}

TEST_F(OpaqueRectTrackingContentLayerDelegateTest, testPartialOpaqueRectTranslation)
{
    IntRect partialRect(100, 200, 50, 75);
    PaintFillPartialOpaque fillPartial(partialRect);
    TestLayerPainterChromium painter(fillPartial);
    OpaqueRectTrackingContentLayerDelegate delegate(&painter);

    WebFloatRect opaqueRect;
    WebRect contentRect(11, 12, 389, 388);
    delegate.paintContents(skCanvas(), contentRect, false, opaqueRect);
    EXPECT_EQ_RECT(WebFloatRect(partialRect.x(), partialRect.y(), partialRect.width(), partialRect.height()), opaqueRect);
}

} // namespace
