// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/time/time.h"
#include "skia/ext/benchmarking_canvas.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkTLazy.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRegion.h"
#include "third_party/skia/include/core/SkString.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace {

class FlagsBuilder {
public:
  FlagsBuilder(char separator)
      : separator_(separator) {}

  void addFlag(bool flag_val, const char flag_name[]) {
    if (!flag_val)
      return;
    if (!oss_.str().empty())
      oss_ << separator_;

    oss_ << flag_name;
  }

  std::string str() const {
    return oss_.str();
  }

private:
  char separator_;
  std::ostringstream oss_;
};

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(bool b) {
  scoped_ptr<base::FundamentalValue> val(new base::FundamentalValue(b));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkScalar scalar) {
  scoped_ptr<base::FundamentalValue> val(new base::FundamentalValue(scalar));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkSize& size) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("width",  AsValue(size.width()));
  val->Set("height", AsValue(size.height()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkPoint& point) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("x", AsValue(point.x()));
  val->Set("y", AsValue(point.y()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkRect& rect) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("left", AsValue(rect.fLeft));
  val->Set("top", AsValue(rect.fTop));
  val->Set("right", AsValue(rect.fRight));
  val->Set("bottom", AsValue(rect.fBottom));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkRRect& rrect) {
  scoped_ptr<base::DictionaryValue> radii_val(new base::DictionaryValue());
  radii_val->Set("upper-left", AsValue(rrect.radii(SkRRect::kUpperLeft_Corner)));
  radii_val->Set("upper-right", AsValue(rrect.radii(SkRRect::kUpperRight_Corner)));
  radii_val->Set("lower-right", AsValue(rrect.radii(SkRRect::kLowerRight_Corner)));
  radii_val->Set("lower-left", AsValue(rrect.radii(SkRRect::kLowerLeft_Corner)));

  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("rect", AsValue(rrect.rect()));
  val->Set("radii", radii_val.Pass());

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkMatrix& matrix) {
  scoped_ptr<base::ListValue> val(new base::ListValue());
  for (int i = 0; i < 9; ++i)
    val->Append(AsValue(matrix[i]).release()); // no scoped_ptr-aware Append() variant

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkColor color) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->SetInteger("a", SkColorGetA(color));
  val->SetInteger("r", SkColorGetR(color));
  val->SetInteger("g", SkColorGetG(color));
  val->SetInteger("b", SkColorGetB(color));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkXfermode::Mode mode) {
  scoped_ptr<base::StringValue> val(
      new base::StringValue(SkXfermode::ModeName(mode)));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkCanvas::PointMode mode) {
  static const char* gModeStrings[] = { "Points", "Lines", "Polygon" };
  DCHECK_LT(static_cast<size_t>(mode), SK_ARRAY_COUNT(gModeStrings));

  scoped_ptr<base::StringValue> val(new base::StringValue(gModeStrings[mode]));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkXfermode& xfermode) {
  SkXfermode::Mode mode;
  if (xfermode.asMode(&mode))
    return AsValue(mode);

  scoped_ptr<base::StringValue> val(new base::StringValue("unknown"));
  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkColorFilter& filter) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());

  if (unsigned flags = filter.getFlags()) {
    FlagsBuilder builder('|');
    builder.addFlag(flags & SkColorFilter::kAlphaUnchanged_Flag,
                    "kAlphaUnchanged_Flag");

    val->SetString("flags", builder.str());
  }

  SkScalar color_matrix[20];
  if (filter.asColorMatrix(color_matrix)) {
    scoped_ptr<base::ListValue> color_matrix_val(new base::ListValue());
    for (unsigned i = 0; i < 20; ++i)
      color_matrix_val->Append(AsValue(color_matrix[i]).release());

    val->Set("color_matrix", color_matrix_val.Pass());
  }

  SkColor color;
  SkXfermode::Mode mode;
  if (filter.asColorMode(&color, &mode)) {
    scoped_ptr<base::DictionaryValue> color_mode_val(
        new base::DictionaryValue());
    color_mode_val->Set("color", AsValue(color));
    color_mode_val->Set("mode", AsValue(mode));

    val->Set("color_mode", color_mode_val.Pass());
  }

  if (filter.asComponentTable(nullptr)) {
    scoped_ptr<base::DictionaryValue> component_table_val(
        new base::DictionaryValue());
    // use this as a marker for now
    val->Set("component_table", component_table_val.Pass());
  }

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkImageFilter& filter) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->SetInteger("inputs", filter.countInputs());

  SkColorFilter* color_filter;
  if (filter.asColorFilter(&color_filter)) {
    val->Set("color_filter", AsValue(*color_filter));
    SkSafeUnref(color_filter); // ref'd in asColorFilter
  }

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkPaint& paint) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  SkPaint default_paint;

  if (paint.getColor() != default_paint.getColor())
    val->Set("Color", AsValue(paint.getColor()));

  if (paint.getStyle() != default_paint.getStyle()) {
    static const char* gStyleStrings[] = { "Fill", "Stroke", "StrokeFill" };
    DCHECK_LT(static_cast<size_t>(paint.getStyle()),
              SK_ARRAY_COUNT(gStyleStrings));
    val->SetString("Style", gStyleStrings[paint.getStyle()]);
  }

  if (paint.getXfermode() != default_paint.getXfermode()) {
    DCHECK(paint.getXfermode());
    val->Set("Xfermode", AsValue(*paint.getXfermode()));
  }

  if (paint.getFlags()) {
    FlagsBuilder builder('|');
    builder.addFlag(paint.isAntiAlias(), "AntiAlias");
    builder.addFlag(paint.isDither(), "Dither");
    builder.addFlag(paint.isUnderlineText(), "UnderlineText");
    builder.addFlag(paint.isStrikeThruText(), "StrikeThruText");
    builder.addFlag(paint.isFakeBoldText(), "FakeBoldText");
    builder.addFlag(paint.isLinearText(), "LinearText");
    builder.addFlag(paint.isSubpixelText(), "SubpixelText");
    builder.addFlag(paint.isDevKernText(), "DevKernText");
    builder.addFlag(paint.isLCDRenderText(), "LCDRenderText");
    builder.addFlag(paint.isEmbeddedBitmapText(), "EmbeddedBitmapText");
    builder.addFlag(paint.isAutohinted(), "Autohinted");
    builder.addFlag(paint.isVerticalText(), "VerticalText");
    builder.addFlag(paint.getFlags() & SkPaint::kGenA8FromLCD_Flag,
                    "GenA8FromLCD");

    val->SetString("Flags", builder.str());
  }

  if (paint.getFilterQuality() != default_paint.getFilterQuality()) {
    static const char* gFilterQualityStrings[] = {
        "None", "Low", "Medium", "High"};
    DCHECK_LT(static_cast<size_t>(paint.getFilterQuality()),
              SK_ARRAY_COUNT(gFilterQualityStrings));
    val->SetString("FilterLevel",
                   gFilterQualityStrings[paint.getFilterQuality()]);
  }

  if (paint.getTextSize() != default_paint.getTextSize())
    val->SetDouble("TextSize", paint.getTextSize());

  if (paint.getTextScaleX() != default_paint.getTextScaleX())
    val->SetDouble("TextScaleX", paint.getTextScaleX());

  if (paint.getTextSkewX() != default_paint.getTextSkewX())
    val->SetDouble("TextSkewX", paint.getTextSkewX());

  if (paint.getColorFilter())
    val->Set("ColorFilter", AsValue(*paint.getColorFilter()));

  if (paint.getImageFilter())
    val->Set("ImageFilter", AsValue(*paint.getImageFilter()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkCanvas::SaveFlags flags) {
  FlagsBuilder builder('|');
  builder.addFlag(flags & SkCanvas::kHasAlphaLayer_SaveFlag,
                  "kHasAlphaLayer");
  builder.addFlag(flags & SkCanvas::kFullColorLayer_SaveFlag,
                  "kFullColorLayer");
  builder.addFlag(flags & SkCanvas::kClipToLayer_SaveFlag,
                  "kClipToLayer");

  scoped_ptr<base::StringValue> val(new base::StringValue(builder.str()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(SkRegion::Op op) {
  static const char* gOpStrings[] = { "Difference",
                                      "Intersect",
                                      "Union",
                                      "XOR",
                                      "ReverseDifference",
                                      "Replace"
                                    };
  DCHECK_LT(static_cast<size_t>(op), SK_ARRAY_COUNT(gOpStrings));
  scoped_ptr<base::StringValue> val(new base::StringValue(gOpStrings[op]));
  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkRegion& region) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("bounds", AsValue(SkRect::Make(region.getBounds())));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkPicture& picture) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("cull-rect", AsValue(picture.cullRect()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkBitmap& bitmap) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("size", AsValue(SkSize::Make(bitmap.width(), bitmap.height())));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkImage& image) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("size", AsValue(SkSize::Make(image.width(), image.height())));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkTextBlob& blob) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());
  val->Set("bounds", AsValue(blob.bounds()));

  return val.Pass();
}

WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsValue(const SkPath& path) {
  scoped_ptr<base::DictionaryValue> val(new base::DictionaryValue());

  static const char* gFillStrings[] =
      { "winding", "even-odd", "inverse-winding", "inverse-even-odd" };
  DCHECK_LT(static_cast<size_t>(path.getFillType()),
      SK_ARRAY_COUNT(gFillStrings));
  val->SetString("fill-type", gFillStrings[path.getFillType()]);

  static const char* gConvexityStrings[] = { "Unknown", "Convex", "Concave" };
  DCHECK_LT(static_cast<size_t>(path.getConvexity()),
      SK_ARRAY_COUNT(gConvexityStrings));
  val->SetString("convexity", gConvexityStrings[path.getConvexity()]);

  val->SetBoolean("is-rect", path.isRect(nullptr));
  val->Set("bounds", AsValue(path.getBounds()));

  static const char* gVerbStrings[] =
      { "move", "line", "quad", "conic", "cubic", "close", "done" };
  static const int gPtsPerVerb[] = { 1, 1, 2, 2, 3, 0, 0 };
  static const int gPtOffsetPerVerb[] = { 0, 1, 1, 1, 1, 0, 0 };
  SK_COMPILE_ASSERT(
      SK_ARRAY_COUNT(gVerbStrings) == static_cast<size_t>(SkPath::kDone_Verb + 1),
      gVerbStrings_size_mismatch);
  SK_COMPILE_ASSERT(
      SK_ARRAY_COUNT(gVerbStrings) == SK_ARRAY_COUNT(gPtsPerVerb),
      gPtsPerVerb_size_mismatch);
  SK_COMPILE_ASSERT(
      SK_ARRAY_COUNT(gVerbStrings) == SK_ARRAY_COUNT(gPtOffsetPerVerb),
      gPtOffsetPerVerb_size_mismatch);

  scoped_ptr<base::ListValue> verbs_val(new base::ListValue());
  SkPath::Iter iter(const_cast<SkPath&>(path), false);
  SkPoint points[4];

  for(SkPath::Verb verb = iter.next(points, false);
      verb != SkPath::kDone_Verb; verb = iter.next(points, false)) {
      DCHECK_LT(static_cast<size_t>(verb), SK_ARRAY_COUNT(gVerbStrings));

      scoped_ptr<base::DictionaryValue> verb_val(new base::DictionaryValue());
      scoped_ptr<base::ListValue> pts_val(new base::ListValue());

      for (int i = 0; i < gPtsPerVerb[verb]; ++i)
        pts_val->Append(AsValue(points[i + gPtOffsetPerVerb[verb]]).release());

      verb_val->Set(gVerbStrings[verb], pts_val.Pass());

      if (SkPath::kConic_Verb == verb)
        verb_val->Set("weight", AsValue(iter.conicWeight()));

      verbs_val->Append(verb_val.release());
  }
  val->Set("verbs", verbs_val.Pass());

  return val.Pass();
}

template<typename T>
WARN_UNUSED_RESULT
scoped_ptr<base::Value> AsListValue(const T array[], size_t count) {
  scoped_ptr<base::ListValue> val(new base::ListValue());

  for (size_t i = 0; i < count; ++i)
    val->Append(AsValue(array[i]).release());

  return val.Pass();
}

class OverdrawXfermode : public SkXfermode {
public:
  SkPMColor xferColor(SkPMColor src, SkPMColor dst) const override {
    // This table encodes the color progression of the overdraw visualization
    static const SkPMColor gTable[] = {
      SkPackARGB32(0x00, 0x00, 0x00, 0x00),
      SkPackARGB32(0xFF, 128, 158, 255),
      SkPackARGB32(0xFF, 170, 185, 212),
      SkPackARGB32(0xFF, 213, 195, 170),
      SkPackARGB32(0xFF, 255, 192, 127),
      SkPackARGB32(0xFF, 255, 185, 85),
      SkPackARGB32(0xFF, 255, 165, 42),
      SkPackARGB32(0xFF, 255, 135, 0),
      SkPackARGB32(0xFF, 255,  95, 0),
      SkPackARGB32(0xFF, 255,  50, 0),
      SkPackARGB32(0xFF, 255,  0, 0)
    };

    size_t idx;
    if (SkColorGetR(dst) < 64) { // 0
      idx = 0;
    } else if (SkColorGetG(dst) < 25) { // 10
      idx = 9;  // cap at 9 for upcoming increment
    } else if ((SkColorGetB(dst) + 21) / 42 > 0) { // 1-6
      idx = 7 - (SkColorGetB(dst) + 21) / 42;
    } else { // 7-9
      idx = 10 - (SkColorGetG(dst) + 22) / 45;
    }

    ++idx;
    SkASSERT(idx < SK_ARRAY_COUNT(gTable));

    return gTable[idx];
  }

  Factory getFactory() const override { return NULL; }
#ifndef SK_IGNORE_TO_STRING
  void toString(SkString* str) const override { str->set("OverdrawXfermode"); }
#endif
};

} // namespace

namespace skia {

class BenchmarkingCanvas::AutoOp {
public:
  AutoOp(BenchmarkingCanvas* canvas, const char op_name[],
         const SkPaint* paint = nullptr)
      : canvas_(canvas)
      , op_record_(new base::DictionaryValue())
      , op_params_(new base::ListValue())
      // AutoOp objects are always scoped within draw call frames,
      // so the paint is guaranteed to be valid for their lifetime.
      , paint_(paint) {

    DCHECK(canvas);
    DCHECK(op_name);

    op_record_->SetString("cmd_string", op_name);
    op_record_->Set("info", op_params_);

    if (paint)
      this->addParam("paint", AsValue(*paint));

    if (canvas->flags_ & kOverdrawVisualization_Flag) {
      DCHECK(canvas->overdraw_xfermode_);

      paint_ = paint ? filtered_paint_.set(*paint) : filtered_paint_.init();
      filtered_paint_.get()->setXfermode(canvas->overdraw_xfermode_.get());
      filtered_paint_.get()->setAntiAlias(false);
    }

    start_ticks_ = base::TimeTicks::Now();
  }

  ~AutoOp() {
    base::TimeDelta ticks = base::TimeTicks::Now() - start_ticks_;
    op_record_->SetDouble("cmd_time", ticks.InMillisecondsF());

    canvas_->op_records_.Append(op_record_);
  }

  void addParam(const char name[], scoped_ptr<base::Value> value) {
    scoped_ptr<base::DictionaryValue> param(new base::DictionaryValue());
    param->Set(name, value.Pass());

    op_params_->Append(param.release());
  }

  const SkPaint* paint() const { return paint_; }

private:
  BenchmarkingCanvas* canvas_;
  base::DictionaryValue* op_record_;
  base::ListValue* op_params_;
  base::TimeTicks start_ticks_;

  const SkPaint* paint_;
  SkTLazy<SkPaint> filtered_paint_;
};

BenchmarkingCanvas::BenchmarkingCanvas(SkCanvas* canvas, unsigned flags)
    : INHERITED(canvas->imageInfo().width(),
                canvas->imageInfo().height())
    , flags_(flags) {
  addCanvas(canvas);

  if (flags & kOverdrawVisualization_Flag)
    overdraw_xfermode_ = AdoptRef(new OverdrawXfermode);
}

BenchmarkingCanvas::~BenchmarkingCanvas() {
}

size_t BenchmarkingCanvas::CommandCount() const {
  return op_records_.GetSize();
}

const base::ListValue& BenchmarkingCanvas::Commands() const {
  return op_records_;
}

double BenchmarkingCanvas::GetTime(size_t index) {
  const base::DictionaryValue* op;
  if (!op_records_.GetDictionary(index, &op))
    return 0;

  double t;
  if (!op->GetDouble("cmd_time", &t))
    return 0;

  return t;
}

void BenchmarkingCanvas::willSave() {
  AutoOp op(this, "Save");

  INHERITED::willSave();
}

SkCanvas::SaveLayerStrategy BenchmarkingCanvas::willSaveLayer(const SkRect* rect,
                                                              const SkPaint* paint,
                                                              SaveFlags flags) {
  AutoOp op(this, "SaveLayer", paint);
  if (rect)
    op.addParam("bounds", AsValue(*rect));
  if (flags)
    op.addParam("flags", AsValue(flags));

  return INHERITED::willSaveLayer(rect, op.paint(), flags);
}

void BenchmarkingCanvas::willRestore() {
  AutoOp op(this, "Restore");

  INHERITED::willRestore();
}

void BenchmarkingCanvas::didConcat(const SkMatrix& m) {
  AutoOp op(this, "Concat");
  op.addParam("matrix", AsValue(m));

  INHERITED::didConcat(m);
}

void BenchmarkingCanvas::didSetMatrix(const SkMatrix& m) {
  AutoOp op(this, "SetMatrix");
  op.addParam("matrix", AsValue(m));

  INHERITED::didSetMatrix(m);
}

void BenchmarkingCanvas::onClipRect(const SkRect& rect,
                                    SkRegion::Op region_op,
                                    SkCanvas::ClipEdgeStyle style) {
  AutoOp op(this, "ClipRect");
  op.addParam("rect", AsValue(rect));
  op.addParam("op", AsValue(region_op));
  op.addParam("anti-alias", AsValue(style == kSoft_ClipEdgeStyle));

  INHERITED::onClipRect(rect, region_op, style);
}

void BenchmarkingCanvas::onClipRRect(const SkRRect& rrect,
                                     SkRegion::Op region_op,
                                     SkCanvas::ClipEdgeStyle style) {
  AutoOp op(this, "ClipRRect");
  op.addParam("rrect", AsValue(rrect));
  op.addParam("op", AsValue(region_op));
  op.addParam("anti-alias", AsValue(style == kSoft_ClipEdgeStyle));

  INHERITED::onClipRRect(rrect, region_op, style);
}

void BenchmarkingCanvas::onClipPath(const SkPath& path,
                                    SkRegion::Op region_op,
                                    SkCanvas::ClipEdgeStyle style) {
  AutoOp op(this, "ClipPath");
  op.addParam("path", AsValue(path));
  op.addParam("op", AsValue(region_op));
  op.addParam("anti-alias", AsValue(style == kSoft_ClipEdgeStyle));

  INHERITED::onClipPath(path, region_op, style);
}

void BenchmarkingCanvas::onClipRegion(const SkRegion& region,
                                      SkRegion::Op region_op) {
  AutoOp op(this, "ClipRegion");
  op.addParam("region", AsValue(region));
  op.addParam("op", AsValue(region_op));

  INHERITED::onClipRegion(region, region_op);
}

void BenchmarkingCanvas::onDrawPaint(const SkPaint& paint) {
  AutoOp op(this, "DrawPaint", &paint);

  INHERITED::onDrawPaint(*op.paint());
}

void BenchmarkingCanvas::onDrawPoints(PointMode mode, size_t count,
                                      const SkPoint pts[], const SkPaint& paint) {
  AutoOp op(this, "DrawPoints", &paint);
  op.addParam("mode", AsValue(mode));
  op.addParam("points", AsListValue(pts, count));

  INHERITED::onDrawPoints(mode, count, pts, *op.paint());
}

void BenchmarkingCanvas::onDrawRect(const SkRect& rect, const SkPaint& paint) {
  AutoOp op(this, "DrawRect", &paint);
  op.addParam("rect", AsValue(rect));

  INHERITED::onDrawRect(rect, *op.paint());
}

void BenchmarkingCanvas::onDrawOval(const SkRect& rect, const SkPaint& paint) {
  AutoOp op(this, "DrawOval", &paint);
  op.addParam("rect", AsValue(rect));

  INHERITED::onDrawOval(rect, *op.paint());
}

void BenchmarkingCanvas::onDrawRRect(const SkRRect& rrect, const SkPaint& paint) {
  AutoOp op(this, "DrawRRect", &paint);
  op.addParam("rrect", AsValue(rrect));

  INHERITED::onDrawRRect(rrect, *op.paint());
}

void BenchmarkingCanvas::onDrawDRRect(const SkRRect& outer, const SkRRect& inner,
                                      const SkPaint& paint) {
  AutoOp op(this, "DrawDRRect", &paint);
  op.addParam("outer", AsValue(outer));
  op.addParam("inner", AsValue(inner));

  INHERITED::onDrawDRRect(outer, inner, *op.paint());
}

void BenchmarkingCanvas::onDrawPath(const SkPath& path, const SkPaint& paint) {
  AutoOp op(this, "DrawPath", &paint);
  op.addParam("path", AsValue(path));

  INHERITED::onDrawPath(path, *op.paint());
}

void BenchmarkingCanvas::onDrawPicture(const SkPicture* picture,
                                       const SkMatrix* matrix,
                                       const SkPaint* paint) {
  DCHECK(picture);
  AutoOp op(this, "DrawPicture", paint);
  op.addParam("picture", AsValue(picture));
  if (matrix)
    op.addParam("matrix", AsValue(*matrix));

  INHERITED::onDrawPicture(picture, matrix, op.paint());
}

void BenchmarkingCanvas::onDrawBitmap(const SkBitmap& bitmap,
                                      SkScalar left,
                                      SkScalar top,
                                      const SkPaint* paint) {
  AutoOp op(this, "DrawBitmap", paint);
  op.addParam("bitmap", AsValue(bitmap));
  op.addParam("left", AsValue(left));
  op.addParam("top", AsValue(top));

  INHERITED::onDrawBitmap(bitmap, left, top, op.paint());
}

void BenchmarkingCanvas::onDrawBitmapRect(const SkBitmap& bitmap,
                                          const SkRect* src,
                                          const SkRect& dst,
                                          const SkPaint* paint,
                                          DrawBitmapRectFlags flags) {
  AutoOp op(this, "DrawBitmapRect", paint);
  op.addParam("bitmap", AsValue(bitmap));
  if (src)
    op.addParam("src", AsValue(*src));
  op.addParam("dst", AsValue(dst));

  INHERITED::onDrawBitmapRect(bitmap, src, dst, op.paint(), flags);
}

void BenchmarkingCanvas::onDrawImage(const SkImage* image,
                                     SkScalar left,
                                     SkScalar top,
                                     const SkPaint* paint) {
  DCHECK(image);
  AutoOp op(this, "DrawImage", paint);
  op.addParam("image", AsValue(*image));
  op.addParam("left", AsValue(left));
  op.addParam("top", AsValue(top));

  INHERITED::onDrawImage(image, left, top, op.paint());
}

void BenchmarkingCanvas::onDrawImageRect(const SkImage* image, const SkRect* src,
                                         const SkRect& dst, const SkPaint* paint) {
  DCHECK(image);
  AutoOp op(this, "DrawImageRect", paint);
  op.addParam("image", AsValue(*image));
  if (src)
    op.addParam("src", AsValue(*src));
  op.addParam("dst", AsValue(dst));

  INHERITED::onDrawImageRect(image, src, dst, op.paint());
}

void BenchmarkingCanvas::onDrawBitmapNine(const SkBitmap& bitmap,
                                          const SkIRect& center,
                                          const SkRect& dst,
                                          const SkPaint* paint) {
  AutoOp op(this, "DrawBitmapNine", paint);
  op.addParam("bitmap", AsValue(bitmap));
  op.addParam("center", AsValue(SkRect::Make(center)));
  op.addParam("dst", AsValue(dst));

  INHERITED::onDrawBitmapNine(bitmap, center, dst, op.paint());
}

void BenchmarkingCanvas::onDrawSprite(const SkBitmap& bitmap, int left, int top,
                                      const SkPaint* paint)  {
  AutoOp op(this, "DrawSprite", paint);
  op.addParam("bitmap", AsValue(bitmap));
  op.addParam("left", AsValue(SkIntToScalar(left)));
  op.addParam("top", AsValue(SkIntToScalar(top)));

  INHERITED::onDrawSprite(bitmap, left, top, op.paint());
}

void BenchmarkingCanvas::onDrawText(const void* text, size_t byteLength,
                                    SkScalar x, SkScalar y,
                                    const SkPaint& paint) {
  AutoOp op(this, "DrawText", &paint);
  op.addParam("count", AsValue(SkIntToScalar(paint.countText(text, byteLength))));
  op.addParam("x", AsValue(x));
  op.addParam("y", AsValue(y));

  INHERITED::onDrawText(text, byteLength, x, y, *op.paint());
}

void BenchmarkingCanvas::onDrawPosText(const void* text, size_t byteLength,
                                       const SkPoint pos[], const SkPaint& paint) {
  AutoOp op(this, "DrawPosText", &paint);

  int count = paint.countText(text, byteLength);
  op.addParam("count", AsValue(SkIntToScalar(count)));
  op.addParam("pos", AsListValue(pos, count));

  INHERITED::onDrawPosText(text, byteLength, pos, *op.paint());
}

void BenchmarkingCanvas::onDrawPosTextH(const void* text, size_t byteLength,
                                        const SkScalar xpos[], SkScalar constY,
                                        const SkPaint& paint)  {
  AutoOp op(this, "DrawPosTextH", &paint);
  op.addParam("constY", AsValue(constY));

  int count = paint.countText(text, byteLength);
  op.addParam("count", AsValue(SkIntToScalar(count)));
  op.addParam("pos", AsListValue(xpos, count));

  INHERITED::onDrawPosTextH(text, byteLength, xpos, constY, *op.paint());
}

void BenchmarkingCanvas::onDrawTextOnPath(const void* text, size_t byteLength,
                                          const SkPath& path, const SkMatrix* matrix,
                                          const SkPaint& paint) {
  AutoOp op(this, "DrawTextOnPath", &paint);
  op.addParam("count", AsValue(SkIntToScalar(paint.countText(text, byteLength))));
  op.addParam("path", AsValue(path));
  if (matrix)
    op.addParam("matrix", AsValue(*matrix));

  INHERITED::onDrawTextOnPath(text, byteLength, path, matrix, *op.paint());
}

void BenchmarkingCanvas::onDrawTextBlob(const SkTextBlob* blob, SkScalar x, SkScalar y,
                                        const SkPaint& paint) {
  DCHECK(blob);
  AutoOp op(this, "DrawTextBlob", &paint);
  op.addParam("blob", AsValue(*blob));
  op.addParam("x", AsValue(x));
  op.addParam("y", AsValue(y));

  INHERITED::onDrawTextBlob(blob, x, y, *op.paint());
}

} // namespace skia
