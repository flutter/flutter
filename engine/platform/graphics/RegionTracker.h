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

#ifndef RegionTracker_h
#define RegionTracker_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntRect.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"

namespace blink {
class GraphicsContext;

enum RegionTrackingMode {
    TrackOpaqueRegion,
    TRackOverwriteRegion
};

// This class is an encapsulation of functionality for GraphicsContext, and its methods are mirrored
// there for the outside world. It tracks paints and computes what area will be opaque.
class PLATFORM_EXPORT RegionTracker final {
public:
    RegionTracker();

    // The resulting opaque region as a single rect.
    IntRect asRect() const;

    void pushCanvasLayer(const SkPaint*);
    void popCanvasLayer(const GraphicsContext*);

    void setImageMask(const SkRect& imageOpaqueRect);

    enum RegionType {
        Opaque,
        Overwrite
    };

    // Set this to true to track regions that occlude the destination instead of only regions that produce opaque pixels.
    void setTrackedRegionType(RegionType type) { m_trackedRegionType = type; }

    enum DrawType {
        FillOnly,
        FillOrStroke
    };

    void didDrawRect(const GraphicsContext*, const SkRect&, const SkPaint&, const SkBitmap* sourceBitmap);
    void didDrawPath(const GraphicsContext*, const SkPath&, const SkPaint&);
    void didDrawPoints(const GraphicsContext*, SkCanvas::PointMode, int numPoints, const SkPoint[], const SkPaint&);
    void didDrawBounded(const GraphicsContext*, const SkRect&, const SkPaint&);
    void didDrawUnbounded(const GraphicsContext*, const SkPaint&, DrawType);

    struct CanvasLayerState {
        CanvasLayerState()
            : hasImageMask(false)
            , opaqueRect(SkRect::MakeEmpty())
        { }

        SkPaint paint;

        // An image mask is being applied to the layer.
        bool hasImageMask;
        // The opaque area in the image mask.
        SkRect imageOpaqueRect;

        SkRect opaqueRect;
    };

    void reset();

private:
    void didDraw(const GraphicsContext*, const SkRect&, const SkPaint&, const SkBitmap* sourceBitmap, bool fillsBounds, DrawType);
    void applyOpaqueRegionFromLayer(const GraphicsContext*, const SkRect& layerOpaqueRect, const SkPaint&);
    void markRectAsOpaque(const SkRect&);
    void markRectAsNonOpaque(const SkRect&);
    void markAllAsNonOpaque();

    SkRect& currentTrackingOpaqueRect();

    SkRect m_opaqueRect;
    RegionType m_trackedRegionType;

    Vector<CanvasLayerState, 3> m_canvasLayerStack;
};

} // namespace blink

#endif // RegionTracker_h
