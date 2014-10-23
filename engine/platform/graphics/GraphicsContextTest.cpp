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

#include "config.h"

#include "platform/graphics/GraphicsContext.h"

#include "platform/graphics/BitmapImage.h"
#include "platform/graphics/DisplayList.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/graphics/skia/NativeImageSkia.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

#define EXPECT_EQ_RECT(a, b) \
    EXPECT_EQ(a.x(), b.x()); \
    EXPECT_EQ(a.y(), b.y()); \
    EXPECT_EQ(a.width(), b.width()); \
    EXPECT_EQ(a.height(), b.height());

#define EXPECT_PIXELS_MATCH(bitmap, opaqueRect) \
{ \
    SkAutoLockPixels locker(bitmap); \
    for (int y = opaqueRect.y(); y < opaqueRect.maxY(); ++y) \
        for (int x = opaqueRect.x(); x < opaqueRect.maxX(); ++x) { \
            int alpha = *bitmap.getAddr32(x, y) >> 24; \
            EXPECT_EQ(255, alpha); \
        } \
}

#define EXPECT_PIXELS_MATCH_EXACT(bitmap, opaqueRect) \
{ \
    SkAutoLockPixels locker(bitmap); \
    for (int y = 0; y < bitmap.height(); ++y) \
        for (int x = 0; x < bitmap.width(); ++x) {     \
            int alpha = *bitmap.getAddr32(x, y) >> 24; \
            bool opaque = opaqueRect.contains(x, y); \
            EXPECT_EQ(opaque, alpha == 255); \
        } \
}

TEST(GraphicsContextTest, trackOpaqueTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), alpha, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(99, 13, 10, 90), opaque, CompositePlusLighter);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(99, 13, 10, 90), opaque, CompositeSourceIn);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(99, 13, 10, 90), alpha, CompositeSourceIn);
    EXPECT_EQ_RECT(IntRect(10, 10, 89, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(8, 8, 3, 90), opaque, CompositeSourceOut);
    EXPECT_EQ_RECT(IntRect(11, 10, 88, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(30, 30, 290, 290), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(30, 30, 290, 290), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(40, 20, 290, 50), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(30, 30, 290, 290), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 390, 50), opaque, CompositeSourceIn);
    EXPECT_EQ_RECT(IntRect(30, 30, 290, 290), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 390, 50), alpha);
    EXPECT_EQ_RECT(IntRect(30, 30, 290, 290), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 390, 50), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(30, 10, 290, 310), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueClipTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    context.save();
    context.clip(FloatRect(0, 0, 10, 10));
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    context.save();
    context.clip(FloatRect(20, 20, 10, 10));
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    // The intersection of the two clips becomes empty.
    context.clip(FloatRect(30, 20, 10, 10));
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    // The transform and the clip need to interact correctly (transform first)
    context.save();
    context.translate(10, 10);
    context.clip(FloatRect(20, 20, 10, 10));
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(30, 30, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    // The transform and the clip need to interact correctly (clip first)
    context.save();
    context.clip(FloatRect(20, 20, 10, 10));
    context.translate(10, 10);
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();

    context.clearRect(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    Path path;
    path.moveTo(FloatPoint(0, 0));
    path.addLineTo(FloatPoint(100, 0));

    // Non-rectangular clips just cause the paint to be considered non-opaque.
    context.save();
    context.clipPath(path, RULE_EVENODD);
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();

    // Another non-rectangular clip.
    context.save();
    context.clip(IntRect(30, 30, 20, 20));
    context.clipOut(IntRect(30, 30, 10, 10));
    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.restore();
}

TEST(GraphicsContextTest, trackImageMask)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    // Image masks are done by drawing a bitmap into a transparency layer that uses DstIn to mask
    // out a transparency layer below that is filled with the mask color. In the end this should
    // not be marked opaque.

    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(1);
    context.fillRect(FloatRect(10, 10, 10, 10), opaque, CompositeSourceOver);

    context.setCompositeOperation(CompositeDestinationIn);
    context.beginTransparencyLayer(1);

    OwnPtr<ImageBuffer> alphaImage = ImageBuffer::create(IntSize(100, 100));
    alphaImage->context()->fillRect(IntRect(0, 0, 100, 100), alpha);

    context.setCompositeOperation(CompositeSourceOver);
    context.drawImageBuffer(alphaImage.get(), FloatRect(10, 10, 10, 10));

    context.endLayer();
    context.endLayer();

    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackImageMaskWithOpaqueRect)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    // Image masks are done by drawing a bitmap into a transparency layer that uses DstIn to mask
    // out a transparency layer below that is filled with the mask color. In the end this should
    // not be marked opaque.

    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(1);
    context.fillRect(FloatRect(10, 10, 10, 10), opaque, CompositeSourceOver);

    context.setCompositeOperation(CompositeDestinationIn);
    context.beginTransparencyLayer(1);

    OwnPtr<ImageBuffer> alphaImage = ImageBuffer::create(IntSize(100, 100));
    alphaImage->context()->fillRect(IntRect(0, 0, 100, 100), alpha);

    context.setCompositeOperation(CompositeSourceOver);
    context.drawImageBuffer(alphaImage.get(), FloatRect(10, 10, 10, 10));

    // We can't have an opaque mask actually, but we can pretend here like it would look if we did.
    context.fillRect(FloatRect(12, 12, 3, 3), opaque, CompositeSourceOver);

    context.endLayer();
    context.endLayer();

    EXPECT_EQ_RECT(IntRect(12, 12, 3, 3), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueJoinTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    context.fillRect(FloatRect(20, 20, 10, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Doesn't join
    context.fillRect(FloatRect(31, 20, 10, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Does join
    context.fillRect(FloatRect(30, 20, 10, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 20, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Doesn't join
    context.fillRect(FloatRect(20, 31, 20, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 20, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Does join
    context.fillRect(FloatRect(20, 30, 20, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 20, 20), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Doesn't join
    context.fillRect(FloatRect(9, 20, 10, 20), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 20, 20), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Does join
    context.fillRect(FloatRect(10, 20, 10, 20), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 20, 30, 20), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Doesn't join
    context.fillRect(FloatRect(10, 9, 30, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 20, 30, 20), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    // Does join
    context.fillRect(FloatRect(10, 10, 30, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 30, 30), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueLineTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    context.setShouldAntialias(false);
    context.setMiterLimit(0);
    context.setStrokeThickness(4);
    context.setLineCap(SquareCap);
    context.setStrokeStyle(SolidStroke);
    context.setCompositeOperation(CompositeSourceOver);

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setCompositeOperation(CompositeSourceIn);

    context.save();
    context.setStrokeColor(alpha);
    context.drawLine(IntPoint(0, 0), IntPoint(100, 0));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setStrokeColor(opaque);
    context.drawLine(IntPoint(0, 10), IntPoint(100, 10));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setStrokeColor(alpha);
    context.drawLine(IntPoint(0, 10), IntPoint(100, 10));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 13, 90, 87), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setStrokeColor(alpha);
    context.drawLine(IntPoint(0, 11), IntPoint(100, 11));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 14, 90, 86), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setShouldAntialias(true);
    context.setCompositeOperation(CompositeSourceOver);

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setCompositeOperation(CompositeSourceIn);

    context.save();
    context.setStrokeColor(alpha);
    context.drawLine(IntPoint(0, 0), IntPoint(100, 0));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setShouldAntialias(false);
    context.save();
    context.setStrokeColor(opaque);
    context.drawLine(IntPoint(0, 10), IntPoint(100, 10));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setShouldAntialias(true);
    context.save();
    context.setStrokeColor(opaque);
    context.drawLine(IntPoint(0, 10), IntPoint(100, 10));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 13, 90, 87), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setStrokeColor(alpha);
    context.drawLine(IntPoint(0, 11), IntPoint(100, 11));
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 14, 90, 86), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaquePathTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setShouldAntialias(false);
    context.setMiterLimit(1);
    context.setStrokeThickness(5);
    context.setLineCap(SquareCap);
    context.setStrokeStyle(SolidStroke);
    context.setCompositeOperation(CompositeSourceIn);

    Path path;

    context.setFillColor(alpha);
    path.moveTo(FloatPoint(0, 0));
    path.addLineTo(FloatPoint(100, 0));
    context.fillPath(path);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    path.clear();

    context.setFillColor(opaque);
    path.moveTo(FloatPoint(0, 10));
    path.addLineTo(FloatPoint(100, 13));
    context.fillPath(path);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    path.clear();

    context.setFillColor(alpha);
    path.moveTo(FloatPoint(0, 10));
    path.addLineTo(FloatPoint(100, 13));
    context.fillPath(path);
    EXPECT_EQ_RECT(IntRect(10, 13, 90, 87), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    path.clear();

    context.setFillColor(alpha);
    path.moveTo(FloatPoint(0, 14));
    path.addLineTo(FloatPoint(100, 10));
    context.fillPath(path);
    EXPECT_EQ_RECT(IntRect(10, 14, 90, 86), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    path.clear();
}

TEST(GraphicsContextTest, trackOpaqueImageTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    SkBitmap opaqueBitmap;
    opaqueBitmap.allocN32Pixels(10, 10, true /* opaque */);

    for (int y = 0; y < opaqueBitmap.height(); ++y)
        for (int x = 0; x < opaqueBitmap.width(); ++x)
            *opaqueBitmap.getAddr32(x, y) = 0xFFFFFFFF;
    RefPtr<BitmapImage> opaqueImage = BitmapImage::create(NativeImageSkia::create(opaqueBitmap));
    EXPECT_TRUE(opaqueImage->currentFrameKnownToBeOpaque());

    SkBitmap alphaBitmap;
    alphaBitmap.allocN32Pixels(10, 10);

    for (int y = 0; y < alphaBitmap.height(); ++y)
        for (int x = 0; x < alphaBitmap.width(); ++x)
            *alphaBitmap.getAddr32(x, y) = 0x00000000;
    RefPtr<BitmapImage> alphaImage = BitmapImage::create(NativeImageSkia::create(alphaBitmap));
    EXPECT_FALSE(alphaImage->currentFrameKnownToBeOpaque());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawImage(opaqueImage.get(), IntPoint(0, 0));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.drawImage(alphaImage.get(), IntPoint(0, 0));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawImage(opaqueImage.get(), IntPoint(5, 5));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.drawImage(alphaImage.get(), IntPoint(5, 5));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawImage(opaqueImage.get(), IntPoint(10, 10));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
    context.drawImage(alphaImage.get(), IntPoint(10, 10));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawImage(alphaImage.get(), IntPoint(20, 10), CompositeSourceIn);
    EXPECT_EQ_RECT(IntRect(10, 20, 90, 80), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setAlphaAsFloat(0.5);
    context.drawImage(opaqueImage.get(), IntPoint(25, 15), CompositeSourceIn);
    context.restore();
    EXPECT_EQ_RECT(IntRect(10, 25, 90, 75), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawImage(alphaImage.get(), IntPoint(10, 20), CompositeSourceIn);
    EXPECT_EQ_RECT(IntRect(20, 10, 80, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.save();
    context.setAlphaAsFloat(0.5);
    context.drawImage(opaqueImage.get(), IntPoint(15, 25), CompositeSourceIn);
    context.restore();
    EXPECT_EQ_RECT(IntRect(25, 10, 75, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueOvalTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    EXPECT_EQ_RECT(IntRect(0, 0, 0, 0), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillEllipse(FloatRect(10, 10, 90, 90));
    context.strokeEllipse(FloatRect(10, 10, 90, 90));
    EXPECT_EQ_RECT(IntRect(0, 0, 0, 0), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setCompositeOperation(CompositeSourceIn);

    context.setShouldAntialias(false);

    context.setFillColor(opaque);
    context.fillEllipse(FloatRect(10, 10, 50, 30));
    context.strokeEllipse(FloatRect(10, 10, 50, 30));
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setFillColor(alpha);
    context.fillEllipse(FloatRect(10, 10, 30, 50));
    context.strokeEllipse(FloatRect(10, 10, 30, 50));
    EXPECT_EQ_RECT(IntRect(40, 10, 60, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setShouldAntialias(true);

    context.setFillColor(opaque);
    context.fillEllipse(FloatRect(10, 10, 50, 30));
    context.strokeEllipse(FloatRect(10, 10, 50, 30));
    EXPECT_EQ_RECT(IntRect(40, 41, 60, 59), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setFillColor(alpha);
    context.fillEllipse(FloatRect(20, 10, 30, 50));
    context.strokeEllipse(FloatRect(20, 10, 30, 50));
    EXPECT_EQ_RECT(IntRect(51, 41, 49, 59), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueRoundedRectTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);
    IntSize radii(10, 10);

    EXPECT_EQ_RECT(IntRect(0, 0, 0, 0), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRoundedRect(IntRect(10, 10, 90, 90), radii, radii, radii, radii, opaque);
    EXPECT_EQ_RECT(IntRect(0, 0, 0, 0), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.setCompositeOperation(CompositeSourceIn);
    context.setShouldAntialias(false);

    context.fillRoundedRect(IntRect(10, 10, 50, 30), radii, radii, radii, radii, opaque);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRoundedRect(IntRect(10, 10, 30, 50), radii, radii, radii, radii, alpha);
    EXPECT_EQ_RECT(IntRect(40, 10, 60, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRoundedRect(IntRect(10, 0, 50, 30), radii, radii, radii, radii, alpha);
    EXPECT_EQ_RECT(IntRect(40, 30, 60, 70), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRoundedRect(IntRect(30, 0, 70, 50), radii, radii, radii, radii, opaque);
    EXPECT_EQ_RECT(IntRect(40, 30, 60, 70), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueTextTest)
{
    int width = 200, height = 200;
    SkBitmap bitmap;
    bitmap.allocN32Pixels(width, height);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);
    SkRect textRect = SkRect::MakeWH(width, height);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    SkPaint opaquePaint;
    opaquePaint.setColor(opaque.rgb());
    opaquePaint.setXfermodeMode(SkXfermode::kSrc_Mode);
    SkPaint alphaPaint;
    alphaPaint.setColor(alpha.rgb());
    alphaPaint.setXfermodeMode(SkXfermode::kSrc_Mode);

    SkPoint point = SkPoint::Make(0, 0);

    context.fillRect(FloatRect(50, 50, 50, 50), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(50, 50, 50, 50), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawPosText("A", 1, &point, textRect, opaquePaint);
    EXPECT_EQ_RECT(IntRect(50, 50, 50, 50), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawPosText("A", 1, &point, textRect, alphaPaint);
    EXPECT_EQ_RECT(IntRect(0, 0, 0, 0), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(50, 50, 50, 50), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(50, 50, 50, 50), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(50, 50, 50, 50), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(50, 50, 50, 50), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueWritePixelsTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);

    SkBitmap opaqueBitmap;
    opaqueBitmap.allocN32Pixels(10, 10, true /* opaque */);
    for (int y = 0; y < opaqueBitmap.height(); ++y)
        for (int x = 0; x < opaqueBitmap.width(); ++x)
            *opaqueBitmap.getAddr32(x, y) = 0xFFFFFFFF;

    SkBitmap alphaBitmap;
    alphaBitmap.allocN32Pixels(10, 10);
    for (int y = 0; y < alphaBitmap.height(); ++y)
        for (int x = 0; x < alphaBitmap.width(); ++x)
            *alphaBitmap.getAddr32(x, y) = 0x00000000;

    SkPaint paint;
    paint.setXfermodeMode(SkXfermode::kSrc_Mode);

    context.writePixels(opaqueBitmap, 50, 50);
    EXPECT_EQ_RECT(IntRect(50, 50, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.writePixels(alphaBitmap, 10, 0);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.writePixels(alphaBitmap, 10, 1);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.writePixels(alphaBitmap, 0, 10);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.writePixels(alphaBitmap, 1, 10);
    EXPECT_EQ_RECT(IntRect(11, 11, 89, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueDrawBitmapTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);

    SkBitmap opaqueBitmap;
    opaqueBitmap.allocN32Pixels(10, 10, true /* opaque */);
    for (int y = 0; y < opaqueBitmap.height(); ++y)
        for (int x = 0; x < opaqueBitmap.width(); ++x)
            *opaqueBitmap.getAddr32(x, y) = 0xFFFFFFFF;

    SkBitmap alphaBitmap;
    alphaBitmap.allocN32Pixels(10, 10);
    for (int y = 0; y < alphaBitmap.height(); ++y)
        for (int x = 0; x < alphaBitmap.width(); ++x)
            *alphaBitmap.getAddr32(x, y) = 0x00000000;

    SkPaint paint;
    paint.setXfermodeMode(SkXfermode::kSrc_Mode);

    context.drawBitmap(opaqueBitmap, 10, 10, &paint);
    EXPECT_EQ_RECT(IntRect(10, 10, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.fillRect(FloatRect(10, 10, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmap(alphaBitmap, 10, 0, &paint);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmap(alphaBitmap, 10, 1, &paint);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmap(alphaBitmap, 0, 10, &paint);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmap(alphaBitmap, 1, 10, &paint);
    EXPECT_EQ_RECT(IntRect(11, 11, 89, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, trackOpaqueDrawBitmapRectTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(200, 200);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);

    SkBitmap opaqueBitmap;
    opaqueBitmap.allocN32Pixels(10, 10, true /* opaque */);
    for (int y = 0; y < opaqueBitmap.height(); ++y)
        for (int x = 0; x < opaqueBitmap.width(); ++x)
            *opaqueBitmap.getAddr32(x, y) = 0xFFFFFFFF;

    SkBitmap alphaBitmap;
    alphaBitmap.allocN32Pixels(10, 10);
    for (int y = 0; y < alphaBitmap.height(); ++y)
        for (int x = 0; x < alphaBitmap.width(); ++x)
            *alphaBitmap.getAddr32(x, y) = 0x00000000;

    SkPaint paint;
    paint.setXfermodeMode(SkXfermode::kSrc_Mode);

    context.drawBitmapRect(opaqueBitmap, 0, SkRect::MakeXYWH(10, 10, 90, 90), &paint);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmapRect(alphaBitmap, 0, SkRect::MakeXYWH(10, 0, 10, 10), &paint);
    EXPECT_EQ_RECT(IntRect(10, 10, 90, 90), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmapRect(alphaBitmap, 0, SkRect::MakeXYWH(10, 0, 10, 11), &paint);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmapRect(alphaBitmap, 0, SkRect::MakeXYWH(0, 10, 10, 10), &paint);
    EXPECT_EQ_RECT(IntRect(10, 11, 90, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.drawBitmapRect(alphaBitmap, 0, SkRect::MakeXYWH(0, 10, 11, 10), &paint);
    EXPECT_EQ_RECT(IntRect(11, 11, 89, 89), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, contextTransparencyLayerTest)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    context.fillRect(FloatRect(20, 20, 10, 10), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(20, 20, 10, 10), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.clearRect(FloatRect(20, 20, 10, 10));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    context.beginTransparencyLayer(0.5);
    context.save();
    context.fillRect(FloatRect(20, 20, 10, 10), opaque, CompositeSourceOver);
    context.restore();
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    context.clearRect(FloatRect(20, 20, 10, 10));
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());

    context.beginTransparencyLayer(0.5);
    context.fillRect(FloatRect(20, 20, 10, 10), opaque, CompositeSourceOver);
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, UnboundedDrawsAreClipped)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    Path path;
    context.setShouldAntialias(false);
    context.setMiterLimit(1);
    context.setStrokeThickness(5);
    context.setLineCap(SquareCap);
    context.setStrokeStyle(SolidStroke);

    // Make skia unable to compute fast bounds for our paths.
    DashArray dashArray;
    dashArray.append(1);
    dashArray.append(0);
    context.setLineDash(dashArray, 0);

    // Make the device opaque in 10,10 40x40.
    context.fillRect(FloatRect(10, 10, 40, 40), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 40, 40), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());

    // Clip to the left edge of the opaque area.
    context.clip(IntRect(10, 10, 10, 40));

    // Draw a path that gets clipped. This should destroy the opaque area but only inside the clip.
    context.setCompositeOperation(CompositeSourceOut);
    context.setFillColor(alpha);
    path.moveTo(FloatPoint(10, 10));
    path.addLineTo(FloatPoint(40, 40));
    context.strokePath(path);

    EXPECT_EQ_RECT(IntRect(20, 10, 30, 40), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, PreserveOpaqueOnlyMattersForFirstLayer)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);
    Color alpha(0.0f, 0.0f, 0.0f, 0.0f);

    Path path;
    context.setShouldAntialias(false);
    context.setMiterLimit(1);
    context.setStrokeThickness(5);
    context.setLineCap(SquareCap);
    context.setStrokeStyle(SolidStroke);

    // Make skia unable to compute fast bounds for our paths.
    DashArray dashArray;
    dashArray.append(1);
    dashArray.append(0);
    context.setLineDash(dashArray, 0);

    // Make the device opaque in 10,10 40x40.
    context.fillRect(FloatRect(10, 10, 40, 40), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(10, 10, 40, 40), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());

    // Begin a layer that preserves opaque.
    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(0.5);

    // Begin a layer that does not preserve opaque.
    context.setCompositeOperation(CompositeSourceOut);
    context.beginTransparencyLayer(0.5);

    // This should not destroy the device opaqueness.
    context.fillRect(FloatRect(10, 10, 40, 40), opaque, CompositeSourceOver);

    // This should not destroy the device opaqueness either.
    context.setFillColor(opaque);
    path.moveTo(FloatPoint(10, 10));
    path.addLineTo(FloatPoint(40, 40));
    context.strokePath(path);

    context.endLayer();
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(10, 10, 40, 40), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());

    // Now begin a layer that does not preserve opaque and draw through it to the device.
    context.setCompositeOperation(CompositeSourceOut);
    context.beginTransparencyLayer(0.5);

    // This should destroy the device opaqueness.
    context.fillRect(FloatRect(10, 10, 40, 40), opaque, CompositeSourceOver);

    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());

    // Now we draw with a path for which it cannot compute fast bounds. This should destroy the entire opaque region.

    context.setCompositeOperation(CompositeSourceOut);
    context.beginTransparencyLayer(0.5);

    // This should nuke the device opaqueness.
    context.setFillColor(opaque);
    path.moveTo(FloatPoint(10, 10));
    path.addLineTo(FloatPoint(40, 40));
    context.strokePath(path);

    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH_EXACT(bitmap, context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, OpaqueRegionForLayerWithNonRectDeviceClip)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(100, 100);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);
    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);

    context.fillRect(FloatRect(30, 30, 90, 90), opaque, CompositeSourceOver);

    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(0.5);
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(30, 30, 70, 70), context.opaqueRegion().asRect());

    Path path;
    path.moveTo(FloatPoint(0, 0));
    path.addLineTo(FloatPoint(50, 50));

    // For opaque preserving mode and deviceClip is not rect
    // we will not alter opaque rect.
    context.clipPath(path, RULE_EVENODD);

    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(0.5);
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(30, 30, 70, 70), context.opaqueRegion().asRect());

    // For non-opaque preserving mode and deviceClip is not rect
    // we will mark opaque rect as empty.
    context.setCompositeOperation(CompositeSourceOut);
    context.beginTransparencyLayer(0.5);

    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
}

TEST(GraphicsContextTest, OpaqueRegionForLayerWithRectDeviceClip)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(100, 100);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);

    Color opaque(1.0f, 0.0f, 0.0f, 1.0f);

    GraphicsContext context(&canvas);
    context.setRegionTrackingMode(GraphicsContext::RegionTrackingOpaque);

    context.fillRect(FloatRect(30, 30, 90, 90), opaque, CompositeSourceOver);
    EXPECT_EQ_RECT(IntRect(30, 30, 70, 70), context.opaqueRegion().asRect());

    // For non-opaque preserving mode and deviceClip is rect
    // we will mark device clip rect as non opaque.
    context.setCompositeOperation(CompositeSourceOut);
    context.beginTransparencyLayer(0.5);
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());

    context.clip(FloatRect(0, 0, 50, 50));
    context.fillRect(FloatRect(20, 20, 100, 100), opaque, CompositeSourceOver);

    // For opaque preserving mode and deviceClip is rect
    // we will intersect device clip rect with src opaque rect.
    context.setCompositeOperation(CompositeSourceOver);
    context.beginTransparencyLayer(0.5);
    context.endLayer();
    EXPECT_EQ_RECT(IntRect(20, 20, 30, 30), context.opaqueRegion().asRect());
    EXPECT_PIXELS_MATCH(bitmap, context.opaqueRegion().asRect());
}

#define DISPATCH1(c1, c2, op, param1) do { c1.op(param1); c2.op(param1); } while (0);
#define DISPATCH2(c1, c2, op, param1, param2) do { c1.op(param1, param2); c2.op(param1, param2); } while (0);

TEST(GraphicsContextTest, RecordingTotalMatrix)
{
    SkBitmap bitmap;
    bitmap.allocN32Pixels(400, 400);
    bitmap.eraseColor(0);
    SkCanvas canvas(bitmap);
    GraphicsContext context(&canvas);

    SkCanvas controlCanvas(400, 400);
    GraphicsContext controlContext(&controlCanvas);

    EXPECT_EQ(context.getCTM(), controlContext.getCTM());
    DISPATCH2(context, controlContext, scale, 2, 2);
    EXPECT_EQ(context.getCTM(), controlContext.getCTM());

    controlContext.save();
    context.beginRecording(FloatRect(0, 0, 200, 200));
    DISPATCH2(context, controlContext, translate, 10, 10);
    EXPECT_EQ(context.getCTM(), controlContext.getCTM());

    controlContext.save();
    context.beginRecording(FloatRect(10, 10, 100, 100));
    DISPATCH1(context, controlContext, rotate, 45);
    EXPECT_EQ(context.getCTM(), controlContext.getCTM());

    controlContext.restore();
    context.endRecording();
    EXPECT_EQ(context.getCTM(), controlContext.getCTM());

    controlContext.restore();
    context.endRecording();
    EXPECT_EQ(context.getCTM(), controlContext.getCTM());
}

TEST(GraphicsContextTest, DisplayList)
{
    FloatRect rect(0, 0, 1, 1);
    RefPtr<DisplayList> dl = adoptRef(new DisplayList(rect));

    // picture() returns 0 initially
    SkPicture* pic = dl->picture();
    EXPECT_FALSE(pic);

    // endRecording without a beginRecording does nothing
    dl->endRecording();
    pic = dl->picture();
    EXPECT_FALSE(pic);

    // Two beginRecordings in a row generate two canvases.
    // Unfortunately the new one could be allocated in the same
    // spot as the old one so ref the first one to prolong its life.
    IntSize size(1, 1);
    SkCanvas* canvas1 = dl->beginRecording(size);
    EXPECT_TRUE(canvas1);
    canvas1->ref();
    SkCanvas* canvas2 = dl->beginRecording(size);
    EXPECT_TRUE(canvas2);

    EXPECT_NE(canvas1, canvas2);
    EXPECT_EQ(1, canvas1->getRefCnt());
    canvas1->unref();

    EXPECT_TRUE(dl->isRecording());

    // picture() returns 0 during recording
    pic = dl->picture();
    EXPECT_FALSE(pic);

    // endRecording finally makes the picture accessible
    dl->endRecording();
    pic = dl->picture();
    EXPECT_TRUE(pic);
    EXPECT_EQ(1, pic->getRefCnt());
}

} // namespace
