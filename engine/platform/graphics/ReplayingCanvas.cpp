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
#include "platform/graphics/ReplayingCanvas.h"

#include "third_party/skia/include/core/SkBitmapDevice.h"

namespace blink {

class AutoReplayer {
public:
    explicit AutoReplayer(ReplayingCanvas*);
    ~AutoReplayer();

private:
    ReplayingCanvas* m_canvas;
};

AutoReplayer::AutoReplayer(ReplayingCanvas* replayingCanvas) : m_canvas(replayingCanvas)
{
    replayingCanvas->m_depthCount++;
}

AutoReplayer::~AutoReplayer()
{
    m_canvas->m_depthCount--;
    if (m_canvas->m_depthCount)
        return;
    m_canvas->m_stepCount++;
    m_canvas->updateInRange();
}

ReplayingCanvas::ReplayingCanvas(SkBitmap bitmap, unsigned fromStep, unsigned toStep)
    : InterceptingCanvas(bitmap), m_fromStep(fromStep), m_toStep(toStep), m_stepCount(0), m_abortDrawing(false)
{
}

void ReplayingCanvas::resetStepCount()
{
    m_stepCount = 0;
}

void ReplayingCanvas::updateInRange()
{
    if (m_abortDrawing)
        return;
    if (m_toStep && m_stepCount > m_toStep)
        m_abortDrawing = true;
    if (m_stepCount == m_fromStep)
        this->SkCanvas::clear(SkColorSetARGB(255, 255, 255, 255)); // FIXME: fill with nine patch instead.
}

bool ReplayingCanvas::abortDrawing()
{
    return m_abortDrawing;
}

void ReplayingCanvas::clear(SkColor color)
{
    AutoReplayer replayer(this);
    this->SkCanvas::clear(color);
}

void ReplayingCanvas::drawPaint(const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawPaint(paint);
}

void ReplayingCanvas::drawPoints(PointMode mode, size_t count, const SkPoint pts[], const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawPoints(mode, count, pts, paint);
}

void ReplayingCanvas::drawRect(const SkRect& rect, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawRect(rect, paint);
}

void ReplayingCanvas::drawOval(const SkRect& rect, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawOval(rect, paint);
}

void ReplayingCanvas::drawRRect(const SkRRect& rrect, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawRRect(rrect, paint);
}

void ReplayingCanvas::drawPath(const SkPath& path, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawPath(path, paint);
}

void ReplayingCanvas::drawBitmap(const SkBitmap& bitmap, SkScalar left, SkScalar top, const SkPaint* paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawBitmap(bitmap, left, top, paint);
}

void ReplayingCanvas::drawBitmapRectToRect(const SkBitmap& bitmap, const SkRect* src, const SkRect& dst,
    const SkPaint* paint, DrawBitmapRectFlags flags)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawBitmapRectToRect(bitmap, src, dst, paint, flags);
}

void ReplayingCanvas::drawBitmapMatrix(const SkBitmap& bitmap, const SkMatrix& m, const SkPaint* paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawBitmapMatrix(bitmap, m, paint);
}

void ReplayingCanvas::drawBitmapNine(const SkBitmap& bitmap, const SkIRect& center, const SkRect& dst, const SkPaint* paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawBitmapNine(bitmap, center, dst, paint);
}

void ReplayingCanvas::drawSprite(const SkBitmap& bitmap, int left, int top, const SkPaint* paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawSprite(bitmap, left, top, paint);
}

void ReplayingCanvas::drawVertices(VertexMode vmode, int vertexCount, const SkPoint vertices[], const SkPoint texs[],
    const SkColor colors[], SkXfermode* xmode, const uint16_t indices[], int indexCount, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawVertices(vmode, vertexCount, vertices, texs, colors, xmode, indices, indexCount, paint);
}

void ReplayingCanvas::drawData(const void* data, size_t length)
{
    AutoReplayer replayer(this);
    this->SkCanvas::drawData(data, length);
}

void ReplayingCanvas::beginCommentGroup(const char* description)
{
    AutoReplayer replayer(this);
    this->SkCanvas::beginCommentGroup(description);
}

void ReplayingCanvas::addComment(const char* keyword, const char* value)
{
    AutoReplayer replayer(this);
    this->SkCanvas::addComment(keyword, value);
}

void ReplayingCanvas::endCommentGroup()
{
    AutoReplayer replayer(this);
    this->SkCanvas::endCommentGroup();
}

void ReplayingCanvas::onDrawDRRect(const SkRRect& outer, const SkRRect& inner, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawDRRect(outer, inner, paint);
}

void ReplayingCanvas::onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawText(text, byteLength, x, y, paint);
}

void ReplayingCanvas::onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[], const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawPosText(text, byteLength, pos, paint);
}

void ReplayingCanvas::onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[], SkScalar constY, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawPosTextH(text, byteLength, xpos, constY, paint);
}

void ReplayingCanvas::onDrawTextOnPath(const void* text, size_t byteLength, const SkPath& path, const SkMatrix* matrix, const SkPaint& paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawTextOnPath(text, byteLength, path, matrix, paint);
}

void ReplayingCanvas::onPushCull(const SkRect& cullRect)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onPushCull(cullRect);
}

void ReplayingCanvas::onPopCull()
{
    AutoReplayer replayer(this);
    this->SkCanvas::onPopCull();
}

void ReplayingCanvas::onClipRect(const SkRect& rect, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onClipRect(rect, op, edgeStyle);
}

void ReplayingCanvas::onClipRRect(const SkRRect& rrect, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onClipRRect(rrect, op, edgeStyle);
}

void ReplayingCanvas::onClipPath(const SkPath& path, SkRegion::Op op, ClipEdgeStyle edgeStyle)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onClipPath(path, op, edgeStyle);
}

void ReplayingCanvas::onClipRegion(const SkRegion& region, SkRegion::Op op)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onClipRegion(region, op);
}

void ReplayingCanvas::onDrawPicture(const SkPicture* picture, const SkMatrix* matrix, const SkPaint* paint)
{
    AutoReplayer replayer(this);
    this->SkCanvas::onDrawPicture(picture, matrix, paint);
}

void ReplayingCanvas::didSetMatrix(const SkMatrix& matrix)
{
    AutoReplayer replayer(this);
    this->SkCanvas::didSetMatrix(matrix);
}

void ReplayingCanvas::didConcat(const SkMatrix& matrix)
{
    AutoReplayer replayer(this);
    this->SkCanvas::didConcat(matrix);
}

void ReplayingCanvas::willSave()
{
    AutoReplayer replayer(this);
    this->SkCanvas::willSave();
}

SkCanvas::SaveLayerStrategy ReplayingCanvas::willSaveLayer(const SkRect* bounds, const SkPaint* paint, SaveFlags flags)
{
    AutoReplayer replayer(this);
    // We're about to create a layer and we have not cleared the device yet.
    // Let's clear now, so it has effect on all layers.
    if (m_stepCount < m_fromStep)
        this->SkCanvas::clear(SkColorSetARGB(255, 255, 255, 255)); // FIXME: fill with nine patch instead.

    return this->SkCanvas::willSaveLayer(bounds, paint, flags);
}

void ReplayingCanvas::willRestore()
{
    AutoReplayer replayer(this);
    this->SkCanvas::willRestore();
}

} // namespace blink
