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

#ifndef LoggingCanvas_h
#define LoggingCanvas_h

#include "platform/JSONValues.h"
#include "platform/graphics/InterceptingCanvas.h"

namespace blink {

class LoggingCanvas : public InterceptingCanvas {
public:
    LoggingCanvas(int width, int height);
    PassRefPtr<JSONArray> log();

    virtual void clear(SkColor) OVERRIDE;
    virtual void drawPaint(const SkPaint&) OVERRIDE;
    virtual void drawPoints(PointMode, size_t count, const SkPoint pts[], const SkPaint&) OVERRIDE;
    virtual void drawRect(const SkRect&, const SkPaint&) OVERRIDE;
    virtual void drawOval(const SkRect&, const SkPaint&) OVERRIDE;
    virtual void drawRRect(const SkRRect&, const SkPaint&) OVERRIDE;
    virtual void drawPath(const SkPath&, const SkPaint&) OVERRIDE;
    virtual void drawBitmap(const SkBitmap&, SkScalar left, SkScalar top, const SkPaint* = 0) OVERRIDE;
    virtual void drawBitmapRectToRect(const SkBitmap&, const SkRect* src, const SkRect& dst, const SkPaint*, DrawBitmapRectFlags) OVERRIDE;
    virtual void drawBitmapMatrix(const SkBitmap&, const SkMatrix&, const SkPaint* = 0) OVERRIDE;
    virtual void drawBitmapNine(const SkBitmap&, const SkIRect& center, const SkRect& dst, const SkPaint*) OVERRIDE;
    virtual void drawSprite(const SkBitmap&, int left, int top, const SkPaint* = 0) OVERRIDE;
    virtual void drawVertices(VertexMode vmode, int vertexCount, const SkPoint vertices[], const SkPoint texs[],
        const SkColor colors[], SkXfermode* xmode, const uint16_t indices[], int indexCount, const SkPaint&) OVERRIDE;
    virtual void drawData(const void* data, size_t length) OVERRIDE;
    virtual void beginCommentGroup(const char* description) OVERRIDE;
    virtual void addComment(const char* keyword, const char* value) OVERRIDE;
    virtual void endCommentGroup() OVERRIDE;

    virtual void onDrawDRRect(const SkRRect& outer, const SkRRect& inner, const SkPaint&) OVERRIDE;
    virtual void onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y, const SkPaint&) OVERRIDE;
    virtual void onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[], const SkPaint&) OVERRIDE;
    virtual void onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[], SkScalar constY, const SkPaint&) OVERRIDE;
    virtual void onDrawTextOnPath(const void* text, size_t byteLength, const SkPath&, const SkMatrix*, const SkPaint&) OVERRIDE;
    virtual void onPushCull(const SkRect& cullRect) OVERRIDE;
    virtual void onPopCull() OVERRIDE;
    virtual void onClipRect(const SkRect&, SkRegion::Op, ClipEdgeStyle) OVERRIDE;
    virtual void onClipRRect(const SkRRect&, SkRegion::Op, ClipEdgeStyle) OVERRIDE;
    virtual void onClipPath(const SkPath&, SkRegion::Op, ClipEdgeStyle) OVERRIDE;
    virtual void onClipRegion(const SkRegion&, SkRegion::Op) OVERRIDE;
    virtual void onDrawPicture(const SkPicture*, const SkMatrix*, const SkPaint*);
    virtual void didSetMatrix(const SkMatrix&) OVERRIDE;
    virtual void didConcat(const SkMatrix&) OVERRIDE;
    virtual void willSave() OVERRIDE;
    SaveLayerStrategy willSaveLayer(const SkRect* bounds, const SkPaint*, SaveFlags) OVERRIDE;
    virtual void willRestore() OVERRIDE;

private:
    RefPtr<JSONArray> m_log;
    friend class AutoLogger;

    struct VerbParams {
        String name;
        unsigned pointCount;
        unsigned pointOffset;

        VerbParams(const String& name, unsigned pointCount, unsigned pointOffset)
            : name(name)
            , pointCount(pointCount)
            , pointOffset(pointOffset) { }
    };

    PassRefPtr<JSONObject> addItem(const String& name);
    PassRefPtr<JSONObject> addItemWithParams(const String& name);
    PassRefPtr<JSONObject> objectForSkRect(const SkRect&);
    PassRefPtr<JSONObject> objectForSkIRect(const SkIRect&);
    String pointModeName(PointMode);
    PassRefPtr<JSONObject> objectForSkPoint(const SkPoint&);
    PassRefPtr<JSONArray> arrayForSkPoints(size_t count, const SkPoint points[]);
    PassRefPtr<JSONObject> objectForSkPicture(const SkPicture&);
    PassRefPtr<JSONObject> objectForRadius(const SkRRect& rrect, SkRRect::Corner);
    String rrectTypeName(SkRRect::Type);
    String radiusName(SkRRect::Corner);
    PassRefPtr<JSONObject> objectForSkRRect(const SkRRect&);
    String fillTypeName(SkPath::FillType);
    String convexityName(SkPath::Convexity);
    String verbName(SkPath::Verb);
    VerbParams segmentParams(SkPath::Verb);
    PassRefPtr<JSONObject> objectForSkPath(const SkPath&);
    String colorTypeName(SkColorType);
    PassRefPtr<JSONObject> objectForBitmapData(const SkBitmap&);
    PassRefPtr<JSONObject> objectForSkBitmap(const SkBitmap&);
    PassRefPtr<JSONObject> objectForSkShader(const SkShader&);
    String stringForSkColor(const SkColor&);
    void appendFlagToString(String* flagsString, bool isSet, const String& name);
    String stringForSkPaintFlags(const SkPaint&);
    String filterLevelName(SkPaint::FilterLevel);
    String textAlignName(SkPaint::Align);
    String strokeCapName(SkPaint::Cap);
    String strokeJoinName(SkPaint::Join);
    String styleName(SkPaint::Style);
    String textEncodingName(SkPaint::TextEncoding);
    String hintingName(SkPaint::Hinting);
    PassRefPtr<JSONObject> objectForSkPaint(const SkPaint&);
    PassRefPtr<JSONArray> arrayForSkMatrix(const SkMatrix&);
    PassRefPtr<JSONArray> arrayForSkScalars(size_t n, const SkScalar scalars[]);
    String regionOpName(SkRegion::Op);
    String saveFlagsToString(SkCanvas::SaveFlags);
    String textEncodingCanonicalName(SkPaint::TextEncoding);
    String stringForUTFText(const void* text, size_t length, SkPaint::TextEncoding);
    String stringForText(const void* text, size_t byteLength, const SkPaint&);
};

} // namespace blink

#endif // LoggingCanvas_h
