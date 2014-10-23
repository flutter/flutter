/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#include "platform/graphics/RegionTracker.h"

#include "platform/graphics/GraphicsContext.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkShader.h"

namespace blink {

RegionTracker::RegionTracker()
    : m_opaqueRect(SkRect::MakeEmpty())
    , m_trackedRegionType(Opaque)
{
}

void RegionTracker::reset()
{
    ASSERT(m_canvasLayerStack.isEmpty());
    m_opaqueRect = SkRect::MakeEmpty();
}

IntRect RegionTracker::asRect() const
{
    // Returns the largest enclosed rect.
    // TODO: actually, this logic looks like its returning the smallest.
    //       to return largest, shouldn't we take floor of left/top
    //       and the ceil of right/bottom?
    int left = SkScalarCeilToInt(m_opaqueRect.fLeft);
    int top = SkScalarCeilToInt(m_opaqueRect.fTop);
    int right = SkScalarFloorToInt(m_opaqueRect.fRight);
    int bottom = SkScalarFloorToInt(m_opaqueRect.fBottom);
    return IntRect(left, top, right-left, bottom-top);
}

// Returns true if the xfermode will force the dst to be opaque, regardless of the current dst.
static inline bool xfermodeIsOpaque(const SkPaint& paint, bool srcIsOpaque)
{
    if (!srcIsOpaque)
        return false;

    SkXfermode* xfermode = paint.getXfermode();
    if (!xfermode)
        return true; // default to kSrcOver_Mode
    SkXfermode::Mode mode;
    if (!xfermode->asMode(&mode))
        return false;

    switch (mode) {
    case SkXfermode::kSrc_Mode: // source
    case SkXfermode::kSrcOver_Mode: // source + dest - source*dest
    case SkXfermode::kDstOver_Mode: // source + dest - source*dest
    case SkXfermode::kDstATop_Mode: // source
    case SkXfermode::kPlus_Mode: // source+dest
    default: // the rest are all source + dest - source*dest
        return true;
    case SkXfermode::kClear_Mode: // 0
    case SkXfermode::kDst_Mode: // dest
    case SkXfermode::kSrcIn_Mode: // source * dest
    case SkXfermode::kDstIn_Mode: // dest * source
    case SkXfermode::kSrcOut_Mode: // source * (1-dest)
    case SkXfermode::kDstOut_Mode: // dest * (1-source)
    case SkXfermode::kSrcATop_Mode: // dest
    case SkXfermode::kXor_Mode: // source + dest - 2*(source*dest)
        return false;
    }
}

static inline bool xfermodeIsOverwrite(const SkPaint& paint)
{
    SkXfermode* xfermode = paint.getXfermode();
    if (!xfermode)
        return false; // default to kSrcOver_Mode
    SkXfermode::Mode mode;
    if (!xfermode->asMode(&mode))
        return false;
    switch (mode) {
    case SkXfermode::kSrc_Mode:
    case SkXfermode::kClear_Mode:
        return true;
    default:
        return false;
    }
}

// Returns true if the xfermode will keep the dst opaque, assuming the dst is already opaque.
static inline bool xfermodePreservesOpaque(const SkPaint& paint, bool srcIsOpaque)
{
    SkXfermode* xfermode = paint.getXfermode();
    if (!xfermode)
        return true; // default to kSrcOver_Mode
    SkXfermode::Mode mode;
    if (!xfermode->asMode(&mode))
        return false;

    switch (mode) {
    case SkXfermode::kDst_Mode: // dest
    case SkXfermode::kSrcOver_Mode: // source + dest - source*dest
    case SkXfermode::kDstOver_Mode: // source + dest - source*dest
    case SkXfermode::kSrcATop_Mode: // dest
    case SkXfermode::kPlus_Mode: // source+dest
    default: // the rest are all source + dest - source*dest
        return true;
    case SkXfermode::kClear_Mode: // 0
    case SkXfermode::kSrcOut_Mode: // source * (1-dest)
    case SkXfermode::kDstOut_Mode: // dest * (1-source)
    case SkXfermode::kXor_Mode: // source + dest - 2*(source*dest)
        return false;
    case SkXfermode::kSrc_Mode: // source
    case SkXfermode::kSrcIn_Mode: // source * dest
    case SkXfermode::kDstIn_Mode: // dest * source
    case SkXfermode::kDstATop_Mode: // source
        return srcIsOpaque;
    }
}

// Returns true if all pixels painted will be opaque.
static inline bool paintIsOpaque(const SkPaint& paint, RegionTracker::DrawType drawType, const SkBitmap* bitmap)
{
    if (paint.getAlpha() < 0xFF)
        return false;
    bool checkFillOnly = drawType != RegionTracker::FillOrStroke;
    if (!checkFillOnly && paint.getStyle() != SkPaint::kFill_Style && paint.isAntiAlias())
        return false;
    SkShader* shader = paint.getShader();
    if (shader && !shader->isOpaque())
        return false;
    if (bitmap && !bitmap->isOpaque())
        return false;
    if (paint.getLooper())
        return false;
    if (paint.getImageFilter())
        return false;
    if (paint.getMaskFilter())
        return false;
    SkColorFilter* colorFilter = paint.getColorFilter();
    if (colorFilter && !(colorFilter->getFlags() & SkColorFilter::kAlphaUnchanged_Flag))
        return false;
    return true;
}

// Returns true if there is a rectangular clip, with the result in |deviceClipRect|.
static inline bool getDeviceClipAsRect(const GraphicsContext* context, SkRect& deviceClipRect)
{
    // Get the current clip in device coordinate space.
    if (!context->canvas()->isClipRect()) {
        deviceClipRect.setEmpty();
        return false;
    }

    SkIRect deviceClipIRect;
    if (context->canvas()->getClipDeviceBounds(&deviceClipIRect))
        deviceClipRect.set(deviceClipIRect);
    else
        deviceClipRect.setEmpty();

    return true;
}

void RegionTracker::pushCanvasLayer(const SkPaint* paint)
{
    CanvasLayerState state;
    if (paint)
        state.paint = *paint;
    m_canvasLayerStack.append(state);
}

void RegionTracker::popCanvasLayer(const GraphicsContext* context)
{
    ASSERT(!m_canvasLayerStack.isEmpty());
    if (m_canvasLayerStack.isEmpty())
        return;

    const CanvasLayerState& canvasLayer = m_canvasLayerStack.last();
    SkRect layerOpaqueRect = canvasLayer.opaqueRect;
    SkPaint layerPaint = canvasLayer.paint;

    // Apply the image mask.
    if (canvasLayer.hasImageMask && !layerOpaqueRect.intersect(canvasLayer.imageOpaqueRect))
        layerOpaqueRect.setEmpty();

    m_canvasLayerStack.removeLast();

    applyOpaqueRegionFromLayer(context, layerOpaqueRect, layerPaint);
}

void RegionTracker::setImageMask(const SkRect& imageOpaqueRect)
{
    ASSERT(!m_canvasLayerStack.isEmpty());
    m_canvasLayerStack.last().hasImageMask = true;
    m_canvasLayerStack.last().imageOpaqueRect = imageOpaqueRect;
}

void RegionTracker::didDrawRect(const GraphicsContext* context, const SkRect& fillRect, const SkPaint& paint, const SkBitmap* sourceBitmap)
{
    // Any stroking may put alpha in pixels even if the filling part does not.
    if (paint.getStyle() != SkPaint::kFill_Style) {
        bool fillsBounds = false;

        if (!paint.canComputeFastBounds()) {
            didDrawUnbounded(context, paint, FillOrStroke);
        } else {
            SkRect strokeRect;
            strokeRect = paint.computeFastBounds(fillRect, &strokeRect);
            didDraw(context, strokeRect, paint, sourceBitmap, fillsBounds, FillOrStroke);
        }
    }

    bool fillsBounds = paint.getStyle() != SkPaint::kStroke_Style;
    didDraw(context, fillRect, paint, sourceBitmap, fillsBounds, FillOnly);
}

void RegionTracker::didDrawPath(const GraphicsContext* context, const SkPath& path, const SkPaint& paint)
{
    SkRect rect;
    if (path.isRect(&rect)) {
        didDrawRect(context, rect, paint, 0);
        return;
    }

    bool fillsBounds = false;

    if (!paint.canComputeFastBounds()) {
        didDrawUnbounded(context, paint, FillOrStroke);
    } else {
        rect = paint.computeFastBounds(path.getBounds(), &rect);
        didDraw(context, rect, paint, 0, fillsBounds, FillOrStroke);
    }
}

void RegionTracker::didDrawPoints(const GraphicsContext* context, SkCanvas::PointMode mode, int numPoints, const SkPoint points[], const SkPaint& paint)
{
    if (!numPoints)
        return;

    SkRect rect;
    rect.fLeft = points[0].fX;
    rect.fRight = points[0].fX + 1;
    rect.fTop = points[0].fY;
    rect.fBottom = points[0].fY + 1;

    for (int i = 1; i < numPoints; ++i) {
        rect.fLeft = std::min(rect.fLeft, points[i].fX);
        rect.fRight = std::max(rect.fRight, points[i].fX + 1);
        rect.fTop = std::min(rect.fTop, points[i].fY);
        rect.fBottom = std::max(rect.fBottom, points[i].fY + 1);
    }

    bool fillsBounds = false;

    if (!paint.canComputeFastBounds()) {
        didDrawUnbounded(context, paint, FillOrStroke);
    } else {
        rect = paint.computeFastBounds(rect, &rect);
        didDraw(context, rect, paint, 0, fillsBounds, FillOrStroke);
    }
}

void RegionTracker::didDrawBounded(const GraphicsContext* context, const SkRect& bounds, const SkPaint& paint)
{
    bool fillsBounds = false;

    if (!paint.canComputeFastBounds()) {
        didDrawUnbounded(context, paint, FillOrStroke);
    } else {
        SkRect rect;
        rect = paint.computeFastBounds(bounds, &rect);
        didDraw(context, rect, paint, 0, fillsBounds, FillOrStroke);
    }
}

void RegionTracker::didDraw(const GraphicsContext* context, const SkRect& rect, const SkPaint& paint, const SkBitmap* sourceBitmap, bool fillsBounds, DrawType drawType)
{
    SkRect targetRect = rect;

    // Apply the transform to device coordinate space.
    SkMatrix canvasTransform = context->canvas()->getTotalMatrix();
    if (!canvasTransform.mapRect(&targetRect))
        fillsBounds = false;

    // Apply the current clip.
    SkRect deviceClipRect;
    if (!getDeviceClipAsRect(context, deviceClipRect))
        fillsBounds = false;
    else if (!targetRect.intersect(deviceClipRect))
        return;

    if (m_trackedRegionType == Overwrite && fillsBounds && xfermodeIsOverwrite(paint)) {
        markRectAsOpaque(targetRect);
        return;
    }

    bool drawsOpaque = paintIsOpaque(paint, drawType, sourceBitmap);
    bool xfersOpaque = xfermodeIsOpaque(paint, drawsOpaque);

    if (fillsBounds && xfersOpaque) {
        markRectAsOpaque(targetRect);
    } else if (m_trackedRegionType == Opaque && !xfermodePreservesOpaque(paint, drawsOpaque)) {
        markRectAsNonOpaque(targetRect);
    }
}

void RegionTracker::didDrawUnbounded(const GraphicsContext* context, const SkPaint& paint, DrawType drawType)
{
    bool drawsOpaque = paintIsOpaque(paint, drawType, 0);
    bool preservesOpaque = xfermodePreservesOpaque(paint, drawsOpaque);

    if (preservesOpaque)
        return;

    SkRect deviceClipRect;
    getDeviceClipAsRect(context, deviceClipRect);
    markRectAsNonOpaque(deviceClipRect);
}

void RegionTracker::applyOpaqueRegionFromLayer(const GraphicsContext* context, const SkRect& layerOpaqueRect, const SkPaint& paint)
{
    SkRect deviceClipRect;
    bool deviceClipIsARect = getDeviceClipAsRect(context, deviceClipRect);

    if (deviceClipIsARect && deviceClipRect.isEmpty())
        return;

    SkRect sourceOpaqueRect = layerOpaqueRect;
    // Save the opaque area in the destination, so we can preserve the parts of it under the source opaque area if possible.
    SkRect destinationOpaqueRect = currentTrackingOpaqueRect();

    bool outsideSourceOpaqueRectPreservesOpaque = xfermodePreservesOpaque(paint, false);
    if (!outsideSourceOpaqueRectPreservesOpaque) {
        if (!deviceClipIsARect) {
            markAllAsNonOpaque();
            return;
        }
        markRectAsNonOpaque(deviceClipRect);
    }

    if (!deviceClipIsARect)
        return;
    if (!sourceOpaqueRect.intersect(deviceClipRect))
        return;

    bool sourceOpaqueRectDrawsOpaque = paintIsOpaque(paint, FillOnly, 0);
    bool sourceOpaqueRectXfersOpaque = xfermodeIsOpaque(paint, sourceOpaqueRectDrawsOpaque);
    bool sourceOpaqueRectPreservesOpaque = xfermodePreservesOpaque(paint, sourceOpaqueRectDrawsOpaque);

    // If the layer's opaque area is being drawn opaque in the layer below, then mark it opaque. Otherwise,
    // if it preserves opaque then keep the intersection of the two.
    if (sourceOpaqueRectXfersOpaque)
        markRectAsOpaque(sourceOpaqueRect);
    else if (sourceOpaqueRectPreservesOpaque && sourceOpaqueRect.intersect(destinationOpaqueRect))
        markRectAsOpaque(sourceOpaqueRect);
}

void RegionTracker::markRectAsOpaque(const SkRect& rect)
{
    // We want to keep track of an opaque region but bound its complexity at a constant size.
    // We keep track of the largest rectangle seen by area. If we can add the new rect to this
    // rectangle then we do that, as that is the cheapest way to increase the area returned
    // without increasing the complexity.

    SkRect& opaqueRect = currentTrackingOpaqueRect();

    if (rect.isEmpty())
        return;
    if (opaqueRect.contains(rect))
        return;
    if (rect.contains(opaqueRect)) {
        opaqueRect = rect;
        return;
    }

    if (rect.fTop <= opaqueRect.fTop && rect.fBottom >= opaqueRect.fBottom) {
        if (rect.fLeft < opaqueRect.fLeft && rect.fRight >= opaqueRect.fLeft)
            opaqueRect.fLeft = rect.fLeft;
        if (rect.fRight > opaqueRect.fRight && rect.fLeft <= opaqueRect.fRight)
            opaqueRect.fRight = rect.fRight;
    } else if (rect.fLeft <= opaqueRect.fLeft && rect.fRight >= opaqueRect.fRight) {
        if (rect.fTop < opaqueRect.fTop && rect.fBottom >= opaqueRect.fTop)
            opaqueRect.fTop = rect.fTop;
        if (rect.fBottom > opaqueRect.fBottom && rect.fTop <= opaqueRect.fBottom)
            opaqueRect.fBottom = rect.fBottom;
    }

    long opaqueArea = (long)opaqueRect.width() * (long)opaqueRect.height();
    long area = (long)rect.width() * (long)rect.height();
    if (area > opaqueArea)
        opaqueRect = rect;
}

void RegionTracker::markRectAsNonOpaque(const SkRect& rect)
{
    // We want to keep as much of the current opaque rectangle as we can, so find the one largest
    // rectangle inside m_opaqueRect that does not intersect with |rect|.

    SkRect& opaqueRect = currentTrackingOpaqueRect();

    if (!SkRect::Intersects(rect, opaqueRect))
        return;
    if (rect.contains(opaqueRect)) {
        markAllAsNonOpaque();
        return;
    }

    int deltaLeft = rect.fLeft - opaqueRect.fLeft;
    int deltaRight = opaqueRect.fRight - rect.fRight;
    int deltaTop = rect.fTop - opaqueRect.fTop;
    int deltaBottom = opaqueRect.fBottom - rect.fBottom;

    // horizontal is the larger of the two rectangles to the left or to the right of |rect| and inside opaqueRect.
    // vertical is the larger of the two rectangles above or below |rect| and inside opaqueRect.
    SkRect horizontal = opaqueRect;
    if (deltaTop > deltaBottom)
        horizontal.fBottom = rect.fTop;
    else
        horizontal.fTop = rect.fBottom;
    SkRect vertical = opaqueRect;
    if (deltaLeft > deltaRight)
        vertical.fRight = rect.fLeft;
    else
        vertical.fLeft = rect.fRight;

    if ((long)horizontal.width() * (long)horizontal.height() > (long)vertical.width() * (long)vertical.height())
        opaqueRect = horizontal;
    else
        opaqueRect = vertical;
}

void RegionTracker::markAllAsNonOpaque()
{
    SkRect& opaqueRect = currentTrackingOpaqueRect();
    opaqueRect.setEmpty();
}

SkRect& RegionTracker::currentTrackingOpaqueRect()
{
    // If we are drawing into a canvas layer, then track the opaque rect in that layer.
    return m_canvasLayerStack.isEmpty() ? m_opaqueRect : m_canvasLayerStack.last().opaqueRect;
}

} // namespace blink
