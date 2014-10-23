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
#include "platform/graphics/ProfilingCanvas.h"

#include "wtf/CurrentTime.h"

namespace blink {

class AutoStamper {
public:
    explicit AutoStamper(ProfilingCanvas*);
    ~AutoStamper();

private:
    ProfilingCanvas* m_profilingCanvas;
    double m_startTime;
};

AutoStamper::AutoStamper(ProfilingCanvas* profilingCanvas) : m_profilingCanvas(profilingCanvas)
{
    profilingCanvas->m_depthCount++;
    m_startTime = WTF::monotonicallyIncreasingTime();
}

AutoStamper::~AutoStamper()
{
    m_profilingCanvas->m_depthCount--;
    if (m_profilingCanvas->m_depthCount)
        return;
    double delta = WTF::monotonicallyIncreasingTime() - m_startTime;
    m_profilingCanvas->m_timings->append(delta);
}

ProfilingCanvas::ProfilingCanvas(SkBitmap bitmap) : InterceptingCanvas(bitmap)
{
}

void ProfilingCanvas::setTimings(Vector<double>* timings)
{
    m_timings = timings;
}

void ProfilingCanvas::clear(SkColor color)
{
    AutoStamper stamper(this);
    this->SkCanvas::clear(color);
}

void ProfilingCanvas::drawPaint(const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawPaint(paint);
}

void ProfilingCanvas::drawPoints(PointMode mode, size_t count, const SkPoint pts[], const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawPoints(mode, count, pts, paint);
}

void ProfilingCanvas::drawRect(const SkRect& rect, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawRect(rect, paint);
}

void ProfilingCanvas::drawOval(const SkRect& rect, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawOval(rect, paint);
}

void ProfilingCanvas::drawRRect(const SkRRect& rrect, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawRRect(rrect, paint);
}

void ProfilingCanvas::drawPath(const SkPath& path, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawPath(path, paint);
}

void ProfilingCanvas::drawBitmap(const SkBitmap& bitmap, SkScalar left, SkScalar top, const SkPaint* paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawBitmap(bitmap, left, top, paint);
}

void ProfilingCanvas::drawBitmapRectToRect(const SkBitmap& bitmap, const SkRect* src, const SkRect& dst,
    const SkPaint* paint, DrawBitmapRectFlags flags)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawBitmapRectToRect(bitmap, src, dst, paint, flags);
}

void ProfilingCanvas::drawBitmapMatrix(const SkBitmap& bitmap, const SkMatrix& m, const SkPaint* paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawBitmapMatrix(bitmap, m, paint);
}

void ProfilingCanvas::drawBitmapNine(const SkBitmap& bitmap, const SkIRect& center, const SkRect& dst, const SkPaint* paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawBitmapNine(bitmap, center, dst, paint);
}

void ProfilingCanvas::drawSprite(const SkBitmap& bitmap, int left, int top, const SkPaint* paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawSprite(bitmap, left, top, paint);
}

void ProfilingCanvas::drawVertices(VertexMode vmode, int vertexCount, const SkPoint vertices[], const SkPoint texs[],
    const SkColor colors[], SkXfermode* xmode, const uint16_t indices[], int indexCount, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawVertices(vmode, vertexCount, vertices, texs, colors, xmode, indices, indexCount, paint);
}

void ProfilingCanvas::drawData(const void* data, size_t length)
{
    AutoStamper stamper(this);
    this->SkCanvas::drawData(data, length);
}

void ProfilingCanvas::beginCommentGroup(const char* description)
{
    AutoStamper stamper(this);
    this->SkCanvas::beginCommentGroup(description);
}

void ProfilingCanvas::addComment(const char* keyword, const char* value)
{
    AutoStamper stamper(this);
    this->SkCanvas::addComment(keyword, value);
}

void ProfilingCanvas::endCommentGroup()
{
    AutoStamper stamper(this);
    this->SkCanvas::endCommentGroup();
}

void ProfilingCanvas::onDrawDRRect(const SkRRect& outer, const SkRRect& inner, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawDRRect(outer, inner, paint);
}

void ProfilingCanvas::onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawText(text, byteLength, x, y, paint);
}

void ProfilingCanvas::onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[], const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawPosText(text, byteLength, pos, paint);
}

void ProfilingCanvas::onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[], SkScalar constY, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawPosTextH(text, byteLength, xpos, constY, paint);
}

void ProfilingCanvas::onDrawTextOnPath(const void* text, size_t byteLength, const SkPath& path, const SkMatrix* matrix, const SkPaint& paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawTextOnPath(text, byteLength, path, matrix, paint);
}

void ProfilingCanvas::onPushCull(const SkRect& cullRect)
{
    AutoStamper stamper(this);
    this->SkCanvas::onPushCull(cullRect);
}

void ProfilingCanvas::onPopCull()
{
    AutoStamper stamper(this);
    this->SkCanvas::onPopCull();
}

void ProfilingCanvas::onClipRect(const SkRect& rect, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoStamper stamper(this);
    this->SkCanvas::onClipRect(rect, op, edgeStyle);
}

void ProfilingCanvas::onClipRRect(const SkRRect& rrect, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoStamper stamper(this);
    this->SkCanvas::onClipRRect(rrect, op, edgeStyle);
}

void ProfilingCanvas::onClipPath(const SkPath& path, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoStamper stamper(this);
    this->SkCanvas::onClipPath(path, op, edgeStyle);
}

void ProfilingCanvas::onClipRegion(const SkRegion& region, SkRegion::Op op)
{
    AutoStamper stamper(this);
    this->SkCanvas::onClipRegion(region, op);
}

void ProfilingCanvas::onDrawPicture(const SkPicture* picture, const SkMatrix* matrix, const SkPaint* paint)
{
    AutoStamper stamper(this);
    this->SkCanvas::onDrawPicture(picture, matrix, paint);
}

void ProfilingCanvas::didSetMatrix(const SkMatrix& matrix)
{
    AutoStamper stamper(this);
    this->SkCanvas::didSetMatrix(matrix);
}

void ProfilingCanvas::didConcat(const SkMatrix& matrix)
{
    AutoStamper stamper(this);
    this->SkCanvas::didConcat(matrix);
}

void ProfilingCanvas::willSave()
{
    AutoStamper stamper(this);
    this->SkCanvas::willSave();
}

SkCanvas::SaveLayerStrategy ProfilingCanvas::willSaveLayer(const SkRect* bounds, const SkPaint* paint, SaveFlags flags)
{
    AutoStamper stamper(this);
    return this->SkCanvas::willSaveLayer(bounds, paint, flags);
}

void ProfilingCanvas::willRestore()
{
    AutoStamper stamper(this);
    this->SkCanvas::willRestore();
}

} // namespace blink
