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

#ifndef InterceptingCanvas_h
#define InterceptingCanvas_h

#include "third_party/skia/include/core/SkCanvas.h"

namespace blink {

class InterceptingCanvas : public SkCanvas {
public:
    InterceptingCanvas(SkBitmap bitmap) : SkCanvas(bitmap), m_depthCount(0) { };
    InterceptingCanvas(int width, int height) : SkCanvas(width, height), m_depthCount(0) { };

    virtual void clear(SkColor) OVERRIDE = 0;
    virtual void drawPaint(const SkPaint&) OVERRIDE = 0;
    virtual void drawPoints(PointMode, size_t count, const SkPoint pts[], const SkPaint&) OVERRIDE = 0;
    virtual void drawRect(const SkRect&, const SkPaint&) OVERRIDE = 0;
    virtual void drawOval(const SkRect&, const SkPaint&) OVERRIDE = 0;
    virtual void drawRRect(const SkRRect&, const SkPaint&) OVERRIDE = 0;
    virtual void drawPath(const SkPath&, const SkPaint&) OVERRIDE = 0;
    virtual void drawBitmap(const SkBitmap&, SkScalar left, SkScalar top, const SkPaint* = 0) OVERRIDE = 0;
    virtual void drawBitmapRectToRect(const SkBitmap&, const SkRect* src, const SkRect& dst, const SkPaint*, DrawBitmapRectFlags) OVERRIDE = 0;
    virtual void drawBitmapMatrix(const SkBitmap&, const SkMatrix&, const SkPaint* = 0) OVERRIDE = 0;
    virtual void drawBitmapNine(const SkBitmap&, const SkIRect& center, const SkRect& dst, const SkPaint*) OVERRIDE = 0;
    virtual void drawSprite(const SkBitmap&, int left, int top, const SkPaint* = 0) OVERRIDE = 0;
    virtual void drawVertices(VertexMode vmode, int vertexCount, const SkPoint vertices[], const SkPoint texs[],
        const SkColor colors[], SkXfermode* xmode, const uint16_t indices[], int indexCount, const SkPaint&) OVERRIDE = 0;
    virtual void drawData(const void* data, size_t length) OVERRIDE = 0;
    virtual void beginCommentGroup(const char* description) OVERRIDE = 0;
    virtual void addComment(const char* keyword, const char* value) OVERRIDE = 0;
    virtual void endCommentGroup() OVERRIDE = 0;

    virtual void onDrawDRRect(const SkRRect& outer, const SkRRect& inner, const SkPaint&) OVERRIDE = 0;
    virtual void onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y, const SkPaint&) OVERRIDE = 0;
    virtual void onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[], const SkPaint&) OVERRIDE = 0;
    virtual void onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[], SkScalar constY, const SkPaint&) OVERRIDE = 0;
    virtual void onDrawTextOnPath(const void* text, size_t byteLength, const SkPath&, const SkMatrix*, const SkPaint&) OVERRIDE = 0;
    virtual void onPushCull(const SkRect& cullRect) OVERRIDE = 0;
    virtual void onPopCull() OVERRIDE = 0;
    virtual void onClipRect(const SkRect&, SkRegion::Op, ClipEdgeStyle) OVERRIDE = 0;
    virtual void onClipRRect(const SkRRect&, SkRegion::Op, ClipEdgeStyle) OVERRIDE = 0;
    virtual void onClipPath(const SkPath&, SkRegion::Op, ClipEdgeStyle) OVERRIDE = 0;
    virtual void onClipRegion(const SkRegion&, SkRegion::Op) OVERRIDE = 0;
    virtual void onDrawPicture(const SkPicture*, const SkMatrix*, const SkPaint*) OVERRIDE = 0;
    virtual void didSetMatrix(const SkMatrix&) OVERRIDE = 0;
    virtual void didConcat(const SkMatrix&) OVERRIDE = 0;
    virtual void willSave() OVERRIDE = 0;
    SaveLayerStrategy willSaveLayer(const SkRect* bounds, const SkPaint*, SaveFlags) OVERRIDE = 0;
    virtual void willRestore() OVERRIDE = 0;

protected:
    unsigned m_depthCount;
};

} // namespace blink

#endif // InterceptingCanvas_h
