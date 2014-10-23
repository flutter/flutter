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
#include "platform/graphics/LoggingCanvas.h"

#include "platform/image-encoders/skia/PNGImageEncoder.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "wtf/HexNumber.h"
#include "wtf/text/Base64.h"
#include "wtf/text/TextEncoding.h"

namespace blink {

class AutoLogger {
public:
    explicit AutoLogger(LoggingCanvas*);
    PassRefPtr<JSONObject> logItem(const String& name);
    PassRefPtr<JSONObject> logItemWithParams(const String& name);
    ~AutoLogger();

private:
    LoggingCanvas* m_canvas;
    RefPtr<JSONObject> m_logItem;
};

AutoLogger::AutoLogger(LoggingCanvas* loggingCanvas) : m_canvas(loggingCanvas)
{
    loggingCanvas->m_depthCount++;
}

PassRefPtr<JSONObject> AutoLogger::logItem(const String& name)
{
    RefPtr<JSONObject> item = JSONObject::create();
    item->setString("method", name);
    m_logItem = item;
    return item.release();
}

PassRefPtr<JSONObject> AutoLogger::logItemWithParams(const String& name)
{
    RefPtr<JSONObject> item = logItem(name);
    RefPtr<JSONObject> params = JSONObject::create();
    item->setObject("params", params);
    return params.release();
}

AutoLogger::~AutoLogger()
{
    m_canvas->m_depthCount--;
    if (!m_canvas->m_depthCount)
        m_canvas->m_log->pushObject(m_logItem);
}

LoggingCanvas::LoggingCanvas(int width, int height) : InterceptingCanvas(width, height)
{
    m_log = JSONArray::create();
}

void LoggingCanvas::clear(SkColor color)
{
    AutoLogger logger(this);
    logger.logItemWithParams("clear")->setString("color", stringForSkColor(color));
    this->SkCanvas::clear(color);
}

void LoggingCanvas::drawPaint(const SkPaint& paint)
{
    AutoLogger logger(this);
    logger.logItemWithParams("drawPaint")->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawPaint(paint);
}

void LoggingCanvas::drawPoints(PointMode mode, size_t count, const SkPoint pts[], const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawPoints");
    params->setString("pointMode", pointModeName(mode));
    params->setArray("points", arrayForSkPoints(count, pts));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawPoints(mode, count, pts, paint);
}

void LoggingCanvas::drawRect(const SkRect& rect, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawRect");
    params->setObject("rect", objectForSkRect(rect));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawRect(rect, paint);
}

void LoggingCanvas::drawOval(const SkRect& oval, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawOval");
    params->setObject("oval", objectForSkRect(oval));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawOval(oval, paint);
}

void LoggingCanvas::drawRRect(const SkRRect& rrect, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawRRect");
    params->setObject("rrect", objectForSkRRect(rrect));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawRRect(rrect, paint);
}

void LoggingCanvas::drawPath(const SkPath& path, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawPath");
    params->setObject("path", objectForSkPath(path));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawPath(path, paint);
}

void LoggingCanvas::drawBitmap(const SkBitmap& bitmap, SkScalar left, SkScalar top, const SkPaint* paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawBitmap");
    params->setNumber("left", left);
    params->setNumber("top", top);
    params->setObject("bitmap", objectForSkBitmap(bitmap));
    params->setObject("paint", objectForSkPaint(*paint));
    this->SkCanvas::drawBitmap(bitmap, left, top, paint);
}

void LoggingCanvas::drawBitmapRectToRect(const SkBitmap& bitmap, const SkRect* src, const SkRect& dst, const SkPaint* paint, DrawBitmapRectFlags flags)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawBitmapRectToRect");
    params->setObject("bitmap", objectForSkBitmap(bitmap));
    params->setObject("src", objectForSkRect(*src));
    params->setObject("dst", objectForSkRect(dst));
    params->setObject("paint", objectForSkPaint(*paint));
    params->setNumber("flags", flags);
    this->SkCanvas::drawBitmapRectToRect(bitmap, src, dst, paint, flags);
}

void LoggingCanvas::drawBitmapMatrix(const SkBitmap& bitmap, const SkMatrix& m, const SkPaint* paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawBitmapMatrix");
    params->setObject("bitmap", objectForSkBitmap(bitmap));
    params->setArray("matrix", arrayForSkMatrix(m));
    params->setObject("paint", objectForSkPaint(*paint));
    this->SkCanvas::drawBitmapMatrix(bitmap, m, paint);
}

void LoggingCanvas::drawBitmapNine(const SkBitmap& bitmap, const SkIRect& center, const SkRect& dst, const SkPaint* paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawBitmapNine");
    params->setObject("bitmap", objectForSkBitmap(bitmap));
    params->setObject("center", objectForSkIRect(center));
    params->setObject("dst", objectForSkRect(dst));
    params->setObject("paint", objectForSkPaint(*paint));
    this->SkCanvas::drawBitmapNine(bitmap, center, dst, paint);
}

void LoggingCanvas::drawSprite(const SkBitmap& bitmap, int left, int top, const SkPaint* paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawSprite");
    params->setObject("bitmap", objectForSkBitmap(bitmap));
    params->setNumber("left", left);
    params->setNumber("top", top);
    params->setObject("paint", objectForSkPaint(*paint));
    this->SkCanvas::drawSprite(bitmap, left, top, paint);
}

void LoggingCanvas::drawVertices(VertexMode vmode, int vertexCount, const SkPoint vertices[], const SkPoint texs[], const SkColor colors[], SkXfermode* xmode,
    const uint16_t indices[], int indexCount, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawVertices");
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::drawVertices(vmode, vertexCount, vertices, texs, colors, xmode, indices, indexCount, paint);
}

void LoggingCanvas::drawData(const void* data, size_t length)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawData");
    params->setNumber("length", length);
    this->SkCanvas::drawData(data, length);
}

void LoggingCanvas::beginCommentGroup(const char* description)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("beginCommentGroup");
    params->setString("description", description);
    this->SkCanvas::beginCommentGroup(description);
}

void LoggingCanvas::addComment(const char* keyword, const char* value)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("addComment");
    params->setString("key", keyword);
    params->setString("value", value);
    this->SkCanvas::addComment(keyword, value);
}

void LoggingCanvas::endCommentGroup()
{
    AutoLogger logger(this);
    logger.logItem("endCommentGroup");
    this->SkCanvas::endCommentGroup();
}

void LoggingCanvas::onDrawDRRect(const SkRRect& outer, const SkRRect& inner, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawDRRect");
    params->setObject("outer", objectForSkRRect(outer));
    params->setObject("inner", objectForSkRRect(inner));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::onDrawDRRect(outer, inner, paint);
}

void LoggingCanvas::onDrawText(const void* text, size_t byteLength, SkScalar x, SkScalar y, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawText");
    params->setString("text", stringForText(text, byteLength, paint));
    params->setNumber("x", x);
    params->setNumber("y", y);
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::onDrawText(text, byteLength, x, y, paint);
}

void LoggingCanvas::onDrawPosText(const void* text, size_t byteLength, const SkPoint pos[], const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawPosText");
    params->setString("text", stringForText(text, byteLength, paint));
    size_t pointsCount = paint.countText(text, byteLength);
    params->setArray("pos", arrayForSkPoints(pointsCount, pos));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::onDrawPosText(text, byteLength, pos, paint);
}

void LoggingCanvas::onDrawPosTextH(const void* text, size_t byteLength, const SkScalar xpos[], SkScalar constY, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawPosTextH");
    params->setString("text", stringForText(text, byteLength, paint));
    size_t pointsCount = paint.countText(text, byteLength);
    params->setArray("xpos", arrayForSkScalars(pointsCount, xpos));
    params->setNumber("constY", constY);
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::onDrawPosTextH(text, byteLength, xpos, constY, paint);
}

void LoggingCanvas::onDrawTextOnPath(const void* text, size_t byteLength, const SkPath& path, const SkMatrix* matrix, const SkPaint& paint)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("drawTextOnPath");
    params->setString("text", stringForText(text, byteLength, paint));
    params->setObject("path", objectForSkPath(path));
    params->setArray("matrix", arrayForSkMatrix(*matrix));
    params->setObject("paint", objectForSkPaint(paint));
    this->SkCanvas::onDrawTextOnPath(text, byteLength, path, matrix, paint);
}

void LoggingCanvas::onPushCull(const SkRect& cullRect)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("pushCull");
    params->setObject("cullRect", objectForSkRect(cullRect));
    this->SkCanvas::onPushCull(cullRect);
}

void LoggingCanvas::onPopCull()
{
    AutoLogger logger(this);
    logger.logItem("popCull");
    this->SkCanvas::onPopCull();
}

void LoggingCanvas::onClipRect(const SkRect& rect, SkRegion::Op op, ClipEdgeStyle style)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("clipRect");
    params->setObject("rect", objectForSkRect(rect));
    params->setString("SkRegion::Op", regionOpName(op));
    params->setBoolean("softClipEdgeStyle", kSoft_ClipEdgeStyle == style);
    this->SkCanvas::onClipRect(rect, op, style);
}

void LoggingCanvas::onClipRRect(const SkRRect& rrect, SkRegion::Op op, ClipEdgeStyle style)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("clipRRect");
    params->setObject("rrect", objectForSkRRect(rrect));
    params->setString("SkRegion::Op", regionOpName(op));
    params->setBoolean("softClipEdgeStyle", kSoft_ClipEdgeStyle == style);
    this->SkCanvas::onClipRRect(rrect, op, style);
}

void LoggingCanvas::onClipPath(const SkPath& path, SkRegion::Op op, ClipEdgeStyle style)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("clipPath");
    params->setObject("path", objectForSkPath(path));
    params->setString("SkRegion::Op", regionOpName(op));
    params->setBoolean("softClipEdgeStyle", kSoft_ClipEdgeStyle == style);
    this->SkCanvas::onClipPath(path, op, style);
}

void LoggingCanvas::onClipRegion(const SkRegion& region, SkRegion::Op op)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("clipRegion");
    params->setString("op", regionOpName(op));
    this->SkCanvas::onClipRegion(region, op);
}

void LoggingCanvas::onDrawPicture(const SkPicture* picture, const SkMatrix* matrix, const SkPaint* paint)
{
    AutoLogger logger(this);
    logger.logItemWithParams("drawPicture")->setObject("picture", objectForSkPicture(*picture));
    this->SkCanvas::onDrawPicture(picture, matrix, paint);
}

void LoggingCanvas::didSetMatrix(const SkMatrix& matrix)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("setMatrix");
    params->setArray("matrix", arrayForSkMatrix(matrix));
    this->SkCanvas::didSetMatrix(matrix);
}

void LoggingCanvas::didConcat(const SkMatrix& matrix)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params;

    switch (matrix.getType()) {
    case SkMatrix::kTranslate_Mask:
        params = logger.logItemWithParams("translate");
        params->setNumber("dx", matrix.getTranslateX());
        params->setNumber("dy", matrix.getTranslateY());
        break;

    case SkMatrix::kScale_Mask:
        params = logger.logItemWithParams("scale");
        params->setNumber("scaleX", matrix.getScaleX());
        params->setNumber("scaleY", matrix.getScaleY());
        break;

    default:
        params = logger.logItemWithParams("concat");
        params->setArray("matrix", arrayForSkMatrix(matrix));
    }
    this->SkCanvas::didConcat(matrix);
}

void LoggingCanvas::willSave()
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItem("save");
    this->SkCanvas::willSave();
}

SkCanvas::SaveLayerStrategy LoggingCanvas::willSaveLayer(const SkRect* bounds, const SkPaint* paint, SaveFlags flags)
{
    AutoLogger logger(this);
    RefPtr<JSONObject> params = logger.logItemWithParams("saveLayer");
    if (bounds)
        params->setObject("bounds", objectForSkRect(*bounds));
    params->setObject("paint", objectForSkPaint(*paint));
    params->setString("saveFlags", saveFlagsToString(flags));
    return this->SkCanvas::willSaveLayer(bounds, paint, flags);
}

void LoggingCanvas::willRestore()
{
    AutoLogger logger(this);
    logger.logItem("restore");
    this->SkCanvas::willRestore();
}

PassRefPtr<JSONArray> LoggingCanvas::log()
{
    return m_log;
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkRect(const SkRect& rect)
{
    RefPtr<JSONObject> rectItem = JSONObject::create();
    rectItem->setNumber("left", rect.left());
    rectItem->setNumber("top", rect.top());
    rectItem->setNumber("right", rect.right());
    rectItem->setNumber("bottom", rect.bottom());
    return rectItem.release();
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkIRect(const SkIRect& rect)
{
    RefPtr<JSONObject> rectItem = JSONObject::create();
    rectItem->setNumber("left", rect.left());
    rectItem->setNumber("top", rect.top());
    rectItem->setNumber("right", rect.right());
    rectItem->setNumber("bottom", rect.bottom());
    return rectItem.release();
}

String LoggingCanvas::pointModeName(PointMode mode)
{
    switch (mode) {
    case SkCanvas::kPoints_PointMode: return "Points";
    case SkCanvas::kLines_PointMode: return "Lines";
    case SkCanvas::kPolygon_PointMode: return "Polygon";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkPoint(const SkPoint& point)
{
    RefPtr<JSONObject> pointItem = JSONObject::create();
    pointItem->setNumber("x", point.x());
    pointItem->setNumber("y", point.y());
    return pointItem.release();
}

PassRefPtr<JSONArray> LoggingCanvas::arrayForSkPoints(size_t count, const SkPoint points[])
{
    RefPtr<JSONArray> pointsArrayItem = JSONArray::create();
    for (size_t i = 0; i < count; ++i)
        pointsArrayItem->pushObject(objectForSkPoint(points[i]));
    return pointsArrayItem.release();
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkPicture(const SkPicture& picture)
{
    RefPtr<JSONObject> pictureItem = JSONObject::create();
    pictureItem->setNumber("width", picture.width());
    pictureItem->setNumber("height", picture.height());
    return pictureItem.release();
}

PassRefPtr<JSONObject> LoggingCanvas::objectForRadius(const SkRRect& rrect, SkRRect::Corner corner)
{
    RefPtr<JSONObject> radiusItem = JSONObject::create();
    SkVector radius = rrect.radii(corner);
    radiusItem->setNumber("xRadius", radius.x());
    radiusItem->setNumber("yRadius", radius.y());
    return radiusItem.release();
}

String LoggingCanvas::rrectTypeName(SkRRect::Type type)
{
    switch (type) {
    case SkRRect::kEmpty_Type: return "Empty";
    case SkRRect::kRect_Type: return "Rect";
    case SkRRect::kOval_Type: return "Oval";
    case SkRRect::kSimple_Type: return "Simple";
    case SkRRect::kNinePatch_Type: return "Nine-patch";
    case SkRRect::kComplex_Type: return "Complex";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::radiusName(SkRRect::Corner corner)
{
    switch (corner) {
    case SkRRect::kUpperLeft_Corner: return "upperLeftRadius";
    case SkRRect::kUpperRight_Corner: return "upperRightRadius";
    case SkRRect::kLowerRight_Corner: return "lowerRightRadius";
    case SkRRect::kLowerLeft_Corner: return "lowerLeftRadius";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    }
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkRRect(const SkRRect& rrect)
{
    RefPtr<JSONObject> rrectItem = JSONObject::create();
    rrectItem->setString("type", rrectTypeName(rrect.type()));
    rrectItem->setNumber("left", rrect.rect().left());
    rrectItem->setNumber("top", rrect.rect().top());
    rrectItem->setNumber("right", rrect.rect().right());
    rrectItem->setNumber("bottom", rrect.rect().bottom());
    for (int i = 0; i < 4; ++i)
        rrectItem->setObject(radiusName((SkRRect::Corner) i), objectForRadius(rrect, (SkRRect::Corner) i));
    return rrectItem.release();
}

String LoggingCanvas::fillTypeName(SkPath::FillType type)
{
    switch (type) {
    case SkPath::kWinding_FillType: return "Winding";
    case SkPath::kEvenOdd_FillType: return "EvenOdd";
    case SkPath::kInverseWinding_FillType: return "InverseWinding";
    case SkPath::kInverseEvenOdd_FillType: return "InverseEvenOdd";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::convexityName(SkPath::Convexity convexity)
{
    switch (convexity) {
    case SkPath::kUnknown_Convexity: return "Unknown";
    case SkPath::kConvex_Convexity: return "Convex";
    case SkPath::kConcave_Convexity: return "Concave";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::verbName(SkPath::Verb verb)
{
    switch (verb) {
    case SkPath::kMove_Verb: return "Move";
    case SkPath::kLine_Verb: return "Line";
    case SkPath::kQuad_Verb: return "Quad";
    case SkPath::kConic_Verb: return "Conic";
    case SkPath::kCubic_Verb: return "Cubic";
    case SkPath::kClose_Verb: return "Close";
    case SkPath::kDone_Verb: return "Done";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

LoggingCanvas::VerbParams LoggingCanvas::segmentParams(SkPath::Verb verb)
{
    switch (verb) {
    case SkPath::kMove_Verb: return VerbParams("Move", 1, 0);
    case SkPath::kLine_Verb: return VerbParams("Line", 1, 1);
    case SkPath::kQuad_Verb: return VerbParams("Quad", 2, 1);
    case SkPath::kConic_Verb: return VerbParams("Conic", 2, 1);
    case SkPath::kCubic_Verb: return VerbParams("Cubic", 3, 1);
    case SkPath::kClose_Verb: return VerbParams("Close", 0, 0);
    case SkPath::kDone_Verb: return VerbParams("Done", 0, 0);
    default:
        ASSERT_NOT_REACHED();
        return VerbParams("?", 0, 0);
    };
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkPath(const SkPath& path)
{
    RefPtr<JSONObject> pathItem = JSONObject::create();
    pathItem->setString("fillType", fillTypeName(path.getFillType()));
    pathItem->setString("convexity", convexityName(path.getConvexity()));
    pathItem->setBoolean("isRect", path.isRect(0));
    SkPath::Iter iter(path, false);
    SkPoint points[4];
    RefPtr<JSONArray> pathPointsArray = JSONArray::create();
    for (SkPath::Verb verb = iter.next(points, false); verb != SkPath::kDone_Verb; verb = iter.next(points, false)) {
        VerbParams verbParams = segmentParams(verb);
        RefPtr<JSONObject> pathPointItem = JSONObject::create();
        pathPointItem->setString("verb", verbParams.name);
        ASSERT(verbParams.pointCount + verbParams.pointOffset <= WTF_ARRAY_LENGTH(points));
        pathPointItem->setArray("points", arrayForSkPoints(verbParams.pointCount, points + verbParams.pointOffset));
        if (SkPath::kConic_Verb == verb)
            pathPointItem->setNumber("conicWeight", iter.conicWeight());
        pathPointsArray->pushObject(pathPointItem);
    }
    pathItem->setArray("pathPoints", pathPointsArray);
    pathItem->setObject("bounds", objectForSkRect(path.getBounds()));
    return pathItem.release();
}

String LoggingCanvas::colorTypeName(SkColorType colorType)
{
    switch (colorType) {
    case kUnknown_SkColorType: return "None";
    case kAlpha_8_SkColorType: return "A8";
    case kIndex_8_SkColorType: return "Index8";
    case kRGB_565_SkColorType: return "RGB565";
    case kARGB_4444_SkColorType: return "ARGB4444";
    case kN32_SkColorType: return "ARGB8888";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

PassRefPtr<JSONObject> LoggingCanvas::objectForBitmapData(const SkBitmap& bitmap)
{
    RefPtr<JSONObject> dataItem = JSONObject::create();
    Vector<unsigned char> output;
    PNGImageEncoder::encode(bitmap, &output);
    dataItem->setString("base64", WTF::base64Encode(reinterpret_cast<char*>(output.data()), output.size()));
    dataItem->setString("mimeType", "image/png");
    return dataItem.release();
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkBitmap(const SkBitmap& bitmap)
{
    RefPtr<JSONObject> bitmapItem = JSONObject::create();
    bitmapItem->setNumber("width", bitmap.width());
    bitmapItem->setNumber("height", bitmap.height());
    bitmapItem->setString("config", colorTypeName(bitmap.colorType()));
    bitmapItem->setBoolean("opaque", bitmap.isOpaque());
    bitmapItem->setBoolean("immutable", bitmap.isImmutable());
    bitmapItem->setBoolean("volatile", bitmap.isVolatile());
    bitmapItem->setNumber("genID", bitmap.getGenerationID());
    bitmapItem->setObject("data", objectForBitmapData(bitmap));
    return bitmapItem.release();
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkShader(const SkShader& shader)
{
    RefPtr<JSONObject> shaderItem = JSONObject::create();
    const SkMatrix localMatrix = shader.getLocalMatrix();
    if (!localMatrix.isIdentity())
        shaderItem->setArray("localMatrix", arrayForSkMatrix(localMatrix));
    return shaderItem.release();
}

String LoggingCanvas::stringForSkColor(const SkColor& color)
{
    String colorString = "#";
    appendUnsignedAsHex(color, colorString);
    return colorString;
}

void LoggingCanvas::appendFlagToString(String* flagsString, bool isSet, const String& name)
{
    if (!isSet)
        return;
    if (flagsString->length())
        flagsString->append("|");
    flagsString->append(name);
}

String LoggingCanvas::stringForSkPaintFlags(const SkPaint& paint)
{
    if (!paint.getFlags())
        return "none";
    String flagsString = "";
    appendFlagToString(&flagsString, paint.isAntiAlias(), "AntiAlias");
    appendFlagToString(&flagsString, paint.isDither(), "Dither");
    appendFlagToString(&flagsString, paint.isUnderlineText(), "UnderlinText");
    appendFlagToString(&flagsString, paint.isStrikeThruText(), "StrikeThruText");
    appendFlagToString(&flagsString, paint.isFakeBoldText(), "FakeBoldText");
    appendFlagToString(&flagsString, paint.isLinearText(), "LinearText");
    appendFlagToString(&flagsString, paint.isSubpixelText(), "SubpixelText");
    appendFlagToString(&flagsString, paint.isDevKernText(), "DevKernText");
    appendFlagToString(&flagsString, paint.isLCDRenderText(), "LCDRenderText");
    appendFlagToString(&flagsString, paint.isEmbeddedBitmapText(), "EmbeddedBitmapText");
    appendFlagToString(&flagsString, paint.isAutohinted(), "Autohinted");
    appendFlagToString(&flagsString, paint.isVerticalText(), "VerticalText");
    appendFlagToString(&flagsString, paint.getFlags() & SkPaint::kGenA8FromLCD_Flag, "GenA8FromLCD");
    return flagsString;
}

String LoggingCanvas::filterLevelName(SkPaint::FilterLevel filterLevel)
{
    switch (filterLevel) {
    case SkPaint::kNone_FilterLevel: return "None";
    case SkPaint::kLow_FilterLevel: return "Low";
    case SkPaint::kMedium_FilterLevel: return "Medium";
    case SkPaint::kHigh_FilterLevel: return "High";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::textAlignName(SkPaint::Align align)
{
    switch (align) {
    case SkPaint::kLeft_Align: return "Left";
    case SkPaint::kCenter_Align: return "Center";
    case SkPaint::kRight_Align: return "Right";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::strokeCapName(SkPaint::Cap cap)
{
    switch (cap) {
    case SkPaint::kButt_Cap: return "Butt";
    case SkPaint::kRound_Cap: return "Round";
    case SkPaint::kSquare_Cap: return "Square";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::strokeJoinName(SkPaint::Join join)
{
    switch (join) {
    case SkPaint::kMiter_Join: return "Miter";
    case SkPaint::kRound_Join: return "Round";
    case SkPaint::kBevel_Join: return "Bevel";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::styleName(SkPaint::Style style)
{
    switch (style) {
    case SkPaint::kFill_Style: return "Fill";
    case SkPaint::kStroke_Style: return "Stroke";
    case SkPaint::kStrokeAndFill_Style: return "StrokeAndFill";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::textEncodingName(SkPaint::TextEncoding encoding)
{
    switch (encoding) {
    case SkPaint::kUTF8_TextEncoding: return "UTF-8";
    case SkPaint::kUTF16_TextEncoding: return "UTF-16";
    case SkPaint::kUTF32_TextEncoding: return "UTF-32";
    case SkPaint::kGlyphID_TextEncoding: return "GlyphID";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

String LoggingCanvas::hintingName(SkPaint::Hinting hinting)
{
    switch (hinting) {
    case SkPaint::kNo_Hinting: return "None";
    case SkPaint::kSlight_Hinting: return "Slight";
    case SkPaint::kNormal_Hinting: return "Normal";
    case SkPaint::kFull_Hinting: return "Full";
    default:
        ASSERT_NOT_REACHED();
        return "?";
    };
}

PassRefPtr<JSONObject> LoggingCanvas::objectForSkPaint(const SkPaint& paint)
{
    RefPtr<JSONObject> paintItem = JSONObject::create();
    paintItem->setNumber("textSize", paint.getTextSize());
    paintItem->setNumber("textScaleX", paint.getTextScaleX());
    paintItem->setNumber("textSkewX", paint.getTextSkewX());
    if (SkShader* shader = paint.getShader())
        paintItem->setObject("shader", objectForSkShader(*shader));
    paintItem->setString("color", stringForSkColor(paint.getColor()));
    paintItem->setNumber("strokeWidth", paint.getStrokeWidth());
    paintItem->setNumber("strokeMiter", paint.getStrokeMiter());
    paintItem->setString("flags", stringForSkPaintFlags(paint));
    paintItem->setString("filterLevel", filterLevelName(paint.getFilterLevel()));
    paintItem->setString("textAlign", textAlignName(paint.getTextAlign()));
    paintItem->setString("strokeCap", strokeCapName(paint.getStrokeCap()));
    paintItem->setString("strokeJoin", strokeJoinName(paint.getStrokeJoin()));
    paintItem->setString("styleName", styleName(paint.getStyle()));
    paintItem->setString("textEncoding", textEncodingName(paint.getTextEncoding()));
    paintItem->setString("hinting", hintingName(paint.getHinting()));
    return paintItem.release();
}

PassRefPtr<JSONArray> LoggingCanvas::arrayForSkMatrix(const SkMatrix& matrix)
{
    RefPtr<JSONArray> matrixArray = JSONArray::create();
    for (int i = 0; i < 9; ++i)
        matrixArray->pushNumber(matrix[i]);
    return matrixArray.release();
}

PassRefPtr<JSONArray> LoggingCanvas::arrayForSkScalars(size_t n, const SkScalar scalars[])
{
    RefPtr<JSONArray> scalarsArray = JSONArray::create();
    for (size_t i = 0; i < n; ++i)
        scalarsArray->pushNumber(scalars[i]);
    return scalarsArray.release();
}

String LoggingCanvas::regionOpName(SkRegion::Op op)
{
    switch (op) {
    case SkRegion::kDifference_Op: return "kDifference_Op";
    case SkRegion::kIntersect_Op: return "kIntersect_Op";
    case SkRegion::kUnion_Op: return "kUnion_Op";
    case SkRegion::kXOR_Op: return "kXOR_Op";
    case SkRegion::kReverseDifference_Op: return "kReverseDifference_Op";
    case SkRegion::kReplace_Op: return "kReplace_Op";
    default: return "Unknown type";
    };
}

String LoggingCanvas::saveFlagsToString(SkCanvas::SaveFlags flags)
{
    String flagsString = "";
    if (flags & SkCanvas::kHasAlphaLayer_SaveFlag)
        flagsString.append("kHasAlphaLayer_SaveFlag ");
    if (flags & SkCanvas::kFullColorLayer_SaveFlag)
        flagsString.append("kFullColorLayer_SaveFlag ");
    if (flags & SkCanvas::kClipToLayer_SaveFlag)
        flagsString.append("kClipToLayer_SaveFlag ");
    return flagsString;
}

String LoggingCanvas::textEncodingCanonicalName(SkPaint::TextEncoding encoding)
{
    String name = textEncodingName(encoding);
    if (encoding == SkPaint::kUTF16_TextEncoding || encoding == SkPaint::kUTF32_TextEncoding)
        name.append("LE");
    return name;
}

String LoggingCanvas::stringForUTFText(const void* text, size_t length, SkPaint::TextEncoding encoding)
{
    return WTF::TextEncoding(textEncodingCanonicalName(encoding)).decode((const char*)text, length);
}

String LoggingCanvas::stringForText(const void* text, size_t byteLength, const SkPaint& paint)
{
    SkPaint::TextEncoding encoding = paint.getTextEncoding();
    switch (encoding) {
    case SkPaint::kUTF8_TextEncoding:
    case SkPaint::kUTF16_TextEncoding:
    case SkPaint::kUTF32_TextEncoding:
        return stringForUTFText(text, byteLength, encoding);
    case SkPaint::kGlyphID_TextEncoding: {
        WTF::Vector<SkUnichar> dataVector(byteLength / 2);
        SkUnichar* textData = dataVector.data();
        paint.glyphsToUnichars(static_cast<const uint16_t*>(text), byteLength / 2, textData);
        return WTF::UTF32LittleEndianEncoding().decode(reinterpret_cast<const char*>(textData), byteLength * 2);
    }
    default:
        ASSERT_NOT_REACHED();
        return "?";
    }
}

} // namespace blink
