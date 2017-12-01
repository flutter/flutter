/*
 * Copyright (C) 2003, 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"

#include "flutter/sky/engine/platform/geometry/IntRect.h"
#include "flutter/sky/engine/platform/geometry/RoundedRect.h"
#include "flutter/sky/engine/platform/graphics/Gradient.h"
#include "flutter/sky/engine/platform/graphics/skia/SkiaUtils.h"
#include "flutter/sky/engine/platform/text/BidiResolver.h"
#include "flutter/sky/engine/platform/text/TextRunIterator.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/MathExtras.h"
#include "third_party/skia/include/core/SkAnnotation.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"
#include "third_party/skia/include/effects/SkCornerPathEffect.h"
#include "third_party/skia/include/effects/SkLumaColorFilter.h"
#include "third_party/skia/include/effects/SkPictureImageFilter.h"
#include "third_party/skia/include/gpu/GrRenderTarget.h"
#include "third_party/skia/include/gpu/GrTexture.h"

namespace blink {

struct GraphicsContext::CanvasSaveState {
  CanvasSaveState(bool pendingSave, int count)
      : m_pendingSave(pendingSave), m_restoreCount(count) {}

  bool m_pendingSave;
  int m_restoreCount;
};

GraphicsContext::GraphicsContext(SkCanvas* canvas,
                                 DisabledMode disableContextOrPainting)
    : m_canvas(canvas),
      m_paintStateStack(),
      m_paintStateIndex(0),
      m_pendingCanvasSave(false)
#if ENABLE(ASSERT)
      ,
      m_layerCount(0),
      m_disableDestructionChecks(false)
#endif
      ,
      m_disabledState(disableContextOrPainting),
      m_deviceScaleFactor(1.0f),
      m_regionTrackingMode(RegionTrackingDisabled),
      m_trackTextRegion(false),
      m_accelerated(false),
      m_isCertainlyOpaque(true),
      m_antialiasHairlineImages(false),
      m_shouldSmoothFonts(true) {
  ASSERT(canvas);

  // FIXME: Do some tests to determine how many states are typically used, and
  // allocate several here.
  m_paintStateStack.append(GraphicsContextState::create());
  m_paintState = m_paintStateStack.last().get();
}

GraphicsContext::~GraphicsContext() {
#if ENABLE(ASSERT)
  if (!m_disableDestructionChecks) {
    ASSERT(!m_paintStateIndex);
    ASSERT(!m_paintState->saveCount());
    ASSERT(!m_layerCount);
    ASSERT(m_canvasStateStack.isEmpty());
  }
#endif
}

void GraphicsContext::resetCanvas(SkCanvas* canvas) {
  ASSERT(canvas);
  m_canvas = canvas;
  m_trackedRegion.reset();
}

void GraphicsContext::setRegionTrackingMode(RegionTrackingMode mode) {
  m_regionTrackingMode = mode;
  if (mode == RegionTrackingOpaque)
    m_trackedRegion.setTrackedRegionType(RegionTracker::Opaque);
  else if (mode == RegionTrackingOverwrite)
    m_trackedRegion.setTrackedRegionType(RegionTracker::Overwrite);
}

void GraphicsContext::save() {
  if (contextDisabled())
    return;

  m_paintState->incrementSaveCount();

  m_canvasStateStack.append(
      CanvasSaveState(m_pendingCanvasSave, m_canvas->getSaveCount()));
  m_pendingCanvasSave = true;
}

void GraphicsContext::restore() {
  if (contextDisabled())
    return;

  if (!m_paintStateIndex && !m_paintState->saveCount()) {
    WTF_LOG_ERROR("ERROR void GraphicsContext::restore() stack is empty");
    return;
  }

  if (m_paintState->saveCount()) {
    m_paintState->decrementSaveCount();
  } else {
    m_paintStateIndex--;
    m_paintState = m_paintStateStack[m_paintStateIndex].get();
  }

  CanvasSaveState savedState = m_canvasStateStack.last();
  m_canvasStateStack.removeLast();
  m_pendingCanvasSave = savedState.m_pendingSave;
  m_canvas->restoreToCount(savedState.m_restoreCount);
}

void GraphicsContext::saveLayer(const SkRect* bounds, const SkPaint* paint) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->saveLayer(bounds, paint);
  if (regionTrackingEnabled())
    m_trackedRegion.pushCanvasLayer(paint);
}

void GraphicsContext::restoreLayer() {
  if (contextDisabled())
    return;

  m_canvas->restore();
  if (regionTrackingEnabled())
    m_trackedRegion.popCanvasLayer(this);
}

void GraphicsContext::setStrokePattern(PassRefPtr<Pattern> pattern) {
  if (contextDisabled())
    return;

  ASSERT(pattern);
  if (!pattern) {
    setStrokeColor(Color::black);
    return;
  }
  mutableState()->setStrokePattern(pattern);
}

void GraphicsContext::setStrokeGradient(PassRefPtr<Gradient> gradient) {
  if (contextDisabled())
    return;

  ASSERT(gradient);
  if (!gradient) {
    setStrokeColor(Color::black);
    return;
  }
  mutableState()->setStrokeGradient(gradient);
}

void GraphicsContext::setFillPattern(PassRefPtr<Pattern> pattern) {
  if (contextDisabled())
    return;

  ASSERT(pattern);
  if (!pattern) {
    setFillColor(Color::black);
    return;
  }

  mutableState()->setFillPattern(pattern);
}

void GraphicsContext::setFillGradient(PassRefPtr<Gradient> gradient) {
  if (contextDisabled())
    return;

  ASSERT(gradient);
  if (!gradient) {
    setFillColor(Color::black);
    return;
  }

  mutableState()->setFillGradient(gradient);
}

void GraphicsContext::setShadow(
    const FloatSize& offset,
    float blur,
    const Color& color,
    DrawLooperBuilder::ShadowTransformMode shadowTransformMode,
    DrawLooperBuilder::ShadowAlphaMode shadowAlphaMode) {
  if (contextDisabled())
    return;

  if (!color.alpha() || (!offset.width() && !offset.height() && !blur)) {
    clearShadow();
    return;
  }

  OwnPtr<DrawLooperBuilder> drawLooperBuilder = DrawLooperBuilder::create();
  drawLooperBuilder->addShadow(offset, blur, color, shadowTransformMode,
                               shadowAlphaMode);
  drawLooperBuilder->addUnmodifiedContent();
  setDrawLooper(drawLooperBuilder.release());
}

void GraphicsContext::setDrawLooper(
    PassOwnPtr<DrawLooperBuilder> drawLooperBuilder) {
  if (contextDisabled())
    return;

  mutableState()->setDrawLooper(drawLooperBuilder->detachDrawLooper());
}

void GraphicsContext::clearDrawLooper() {
  if (contextDisabled())
    return;

  mutableState()->clearDrawLooper();
}

bool GraphicsContext::hasShadow() const {
  return !!immutableState()->drawLooper();
}

bool GraphicsContext::getTransformedClipBounds(FloatRect* bounds) const {
  if (contextDisabled())
    return false;
  SkIRect skIBounds;
  if (!m_canvas->getDeviceClipBounds(&skIBounds))
    return false;
  SkRect skBounds = SkRect::Make(skIBounds);
  *bounds = FloatRect(skBounds);
  return true;
}

SkMatrix GraphicsContext::getTotalMatrix() const {
  if (contextDisabled())
    return SkMatrix::I();

  return m_canvas->getTotalMatrix();
}

void GraphicsContext::adjustTextRenderMode(SkPaint* paint) {
  if (contextDisabled())
    return;

  if (!paint->isLCDRenderText())
    return;

  paint->setLCDRenderText(couldUseLCDRenderedText());
}

void GraphicsContext::setCompositeOperation(
    CompositeOperator compositeOperation,
    WebBlendMode blendMode) {
  if (contextDisabled())
    return;
  mutableState()->setCompositeOperation(compositeOperation, blendMode);
}

SkColorFilter* GraphicsContext::colorFilter() const {
  return immutableState()->colorFilter();
}

void GraphicsContext::setColorFilter(ColorFilterObsolete colorFilter) {}

bool GraphicsContext::readPixels(const SkImageInfo& info,
                                 void* pixels,
                                 size_t rowBytes,
                                 int x,
                                 int y) {
  if (contextDisabled())
    return false;

  return m_canvas->readPixels(info, pixels, rowBytes, x, y);
}

void GraphicsContext::setMatrix(const SkMatrix& matrix) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->setMatrix(matrix);
}

void GraphicsContext::concat(const SkMatrix& matrix) {
  if (contextDisabled())
    return;

  if (matrix.isIdentity())
    return;

  realizeCanvasSave();

  m_canvas->concat(matrix);
}

void GraphicsContext::beginTransparencyLayer(float opacity,
                                             const FloatRect* bounds) {
  beginLayer(opacity, immutableState()->compositeOperator(), bounds);
}

void GraphicsContext::beginLayer(float opacity,
                                 CompositeOperator op,
                                 const FloatRect* bounds,
                                 ColorFilterObsolete colorFilter,
                                 sk_sp<SkImageFilter> imageFilter) {
  if (contextDisabled())
    return;

  SkPaint layerPaint;
  layerPaint.setAlpha(static_cast<unsigned char>(opacity * 255));
  layerPaint.setBlendMode(
      WebCoreCompositeToSkiaComposite(op, m_paintState->blendMode()));
  layerPaint.setImageFilter(imageFilter);

  if (bounds) {
    SkRect skBounds = WebCoreFloatRectToSKRect(*bounds);
    saveLayer(&skBounds, &layerPaint);
  } else {
    saveLayer(0, &layerPaint);
  }

#if ENABLE(ASSERT)
  ++m_layerCount;
#endif
}

void GraphicsContext::endLayer() {
  if (contextDisabled())
    return;

  restoreLayer();

  ASSERT(m_layerCount > 0);
#if ENABLE(ASSERT)
  --m_layerCount;
#endif
}

void GraphicsContext::drawConvexPolygon(size_t numPoints,
                                        const FloatPoint* points,
                                        bool shouldAntialias) {
  if (contextDisabled())
    return;

  if (numPoints <= 1)
    return;

  SkPath path;
  setPathFromConvexPoints(&path, numPoints, points);

  SkPaint paint(immutableState()->fillPaint());
  paint.setAntiAlias(shouldAntialias);
  drawPath(path, paint);

  if (strokeStyle() != NoStroke)
    drawPath(path, immutableState()->strokePaint());
}

float GraphicsContext::prepareFocusRingPaint(SkPaint& paint,
                                             const Color& color,
                                             int width) const {
  paint.setAntiAlias(true);
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setColor(color.rgb());
  paint.setStrokeWidth(focusRingWidth(width));
  return 1;
}

void GraphicsContext::drawFocusRingPath(const SkPath& path,
                                        const Color& color,
                                        int width) {
  SkPaint paint;
  float cornerRadius = prepareFocusRingPaint(paint, color, width);

  paint.setPathEffect(SkCornerPathEffect::Make(SkFloatToScalar(cornerRadius)));

  // Outer path
  drawPath(path, paint);
}

void GraphicsContext::drawFocusRingRect(const SkRect& rect,
                                        const Color& color,
                                        int width) {
  SkPaint paint;
  float cornerRadius = prepareFocusRingPaint(paint, color, width);

  SkRRect rrect;
  rrect.setRectXY(rect, SkFloatToScalar(cornerRadius),
                  SkFloatToScalar(cornerRadius));

  // Outer rect
  drawRRect(rrect, paint);
}

static inline IntRect areaCastingShadowInHole(const IntRect& holeRect,
                                              int shadowBlur,
                                              int shadowSpread,
                                              const IntSize& shadowOffset) {
  IntRect bounds(holeRect);

  bounds.inflate(shadowBlur);

  if (shadowSpread < 0)
    bounds.inflate(-shadowSpread);

  IntRect offsetBounds = bounds;
  offsetBounds.move(-shadowOffset);
  return unionRect(bounds, offsetBounds);
}

void GraphicsContext::drawInnerShadow(const RoundedRect& rect,
                                      const Color& shadowColor,
                                      const IntSize shadowOffset,
                                      int shadowBlur,
                                      int shadowSpread,
                                      Edges clippedEdges) {
  if (contextDisabled())
    return;

  IntRect holeRect(rect.rect());
  holeRect.inflate(-shadowSpread);

  if (holeRect.isEmpty()) {
    if (rect.isRounded())
      fillRoundedRect(rect, shadowColor);
    else
      fillRect(rect.rect(), shadowColor);
    return;
  }

  if (clippedEdges & LeftEdge) {
    holeRect.move(-std::max(shadowOffset.width(), 0) - shadowBlur, 0);
    holeRect.setWidth(holeRect.width() + std::max(shadowOffset.width(), 0) +
                      shadowBlur);
  }
  if (clippedEdges & TopEdge) {
    holeRect.move(0, -std::max(shadowOffset.height(), 0) - shadowBlur);
    holeRect.setHeight(holeRect.height() + std::max(shadowOffset.height(), 0) +
                       shadowBlur);
  }
  if (clippedEdges & RightEdge)
    holeRect.setWidth(holeRect.width() - std::min(shadowOffset.width(), 0) +
                      shadowBlur);
  if (clippedEdges & BottomEdge)
    holeRect.setHeight(holeRect.height() - std::min(shadowOffset.height(), 0) +
                       shadowBlur);

  Color fillColor(shadowColor.red(), shadowColor.green(), shadowColor.blue(),
                  255);

  IntRect outerRect = areaCastingShadowInHole(rect.rect(), shadowBlur,
                                              shadowSpread, shadowOffset);
  RoundedRect roundedHole(holeRect, rect.radii());

  save();
  if (rect.isRounded()) {
    Path path;
    path.addRoundedRect(rect);
    clipPath(path);
    roundedHole.shrinkRadii(shadowSpread);
  } else {
    clip(rect.rect());
  }

  OwnPtr<DrawLooperBuilder> drawLooperBuilder = DrawLooperBuilder::create();
  drawLooperBuilder->addShadow(shadowOffset, shadowBlur, shadowColor,
                               DrawLooperBuilder::ShadowRespectsTransforms,
                               DrawLooperBuilder::ShadowIgnoresAlpha);
  setDrawLooper(drawLooperBuilder.release());
  fillRectWithRoundedHole(outerRect, roundedHole, fillColor);
  restore();
  clearDrawLooper();
}

void GraphicsContext::drawLine(const IntPoint& point1, const IntPoint& point2) {
  if (contextDisabled())
    return;

  StrokeStyle penStyle = strokeStyle();
  if (penStyle == NoStroke)
    return;

  FloatPoint p1 = point1;
  FloatPoint p2 = point2;
  bool isVerticalLine = (p1.x() == p2.x());
  int width = roundf(strokeThickness());

  // We know these are vertical or horizontal lines, so the length will just
  // be the sum of the displacement component vectors give or take 1 -
  // probably worth the speed up of no square root, which also won't be exact.
  FloatSize disp = p2 - p1;
  int length = SkScalarRoundToInt(disp.width() + disp.height());
  SkPaint paint(immutableState()->strokePaint(length));

  if (strokeStyle() == DottedStroke || strokeStyle() == DashedStroke) {
    // Do a rect fill of our endpoints.  This ensures we always have the
    // appearance of being a border.  We then draw the actual dotted/dashed
    // line.
    SkRect r1, r2;
    r1.set(p1.x(), p1.y(), p1.x() + width, p1.y() + width);
    r2.set(p2.x(), p2.y(), p2.x() + width, p2.y() + width);

    if (isVerticalLine) {
      r1.offset(-width / 2, 0);
      r2.offset(-width / 2, -width);
    } else {
      r1.offset(0, -width / 2);
      r2.offset(-width, -width / 2);
    }
    SkPaint fillPaint;
    fillPaint.setColor(paint.getColor());
    drawRect(r1, fillPaint);
    drawRect(r2, fillPaint);
  }

  adjustLineToPixelBoundaries(p1, p2, width, penStyle);
  SkPoint pts[2] = {p1.data(), p2.data()};

  m_canvas->drawPoints(SkCanvas::kLines_PointMode, 2, pts, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawPoints(this, SkCanvas::kLines_PointMode, 2, pts,
                                  paint);
}

void GraphicsContext::drawLineForDocumentMarker(const FloatPoint& pt,
                                                float width,
                                                DocumentMarkerLineStyle style) {
  if (contextDisabled())
    return;

  // Use 2x resources for a device scale factor of 1.5 or above.
  int deviceScaleFactor = m_deviceScaleFactor > 1.5f ? 2 : 1;

  // Create the pattern we'll use to draw the underline.
  int index = style == DocumentMarkerGrammarLineStyle ? 1 : 0;
  static SkBitmap* misspellBitmap1x[2] = {0, 0};
  static SkBitmap* misspellBitmap2x[2] = {0, 0};
  SkBitmap** misspellBitmap =
      deviceScaleFactor == 2 ? misspellBitmap2x : misspellBitmap1x;
  if (!misspellBitmap[index]) {
    // We use a 2-pixel-high misspelling indicator because that seems to be
    // what WebKit is designed for, and how much room there is in a typical
    // page for it.
    const int rowPixels =
        32 * deviceScaleFactor;  // Must be multiple of 4 for pattern below.
    const int colPixels = 2 * deviceScaleFactor;
    SkBitmap bitmap;
    bitmap.allocN32Pixels(rowPixels, colPixels);

    bitmap.eraseARGB(0, 0, 0, 0);
    if (deviceScaleFactor == 1)
      draw1xMarker(&bitmap, index);
    else if (deviceScaleFactor == 2)
      draw2xMarker(&bitmap, index);
    else
      ASSERT_NOT_REACHED();

    misspellBitmap[index] = new SkBitmap(bitmap);
  }

  SkScalar originX = WebCoreFloatToSkScalar(pt.x());

  // Offset it vertically by 1 so that there's some space under the text.
  SkScalar originY = WebCoreFloatToSkScalar(pt.y()) + 1;
  originX *= deviceScaleFactor;
  originY *= deviceScaleFactor;

  SkMatrix localMatrix;
  localMatrix.setTranslate(originX, originY);

  SkPaint paint;
  paint.setShader(SkShader::MakeBitmapShader(
      *misspellBitmap[index], SkShader::kRepeat_TileMode,
      SkShader::kRepeat_TileMode, &localMatrix));

  SkRect rect;
  rect.set(originX, originY,
           originX + WebCoreFloatToSkScalar(width) * deviceScaleFactor,
           originY + SkIntToScalar(misspellBitmap[index]->height()));

  if (deviceScaleFactor == 2) {
    save();
    scale(0.5, 0.5);
  }
  drawRect(rect, paint);
  if (deviceScaleFactor == 2)
    restore();
}

void GraphicsContext::drawLineForText(const FloatPoint& pt, float width) {
  if (contextDisabled())
    return;

  if (width <= 0)
    return;

  SkPaint paint;
  switch (strokeStyle()) {
    case NoStroke:
    case SolidStroke:
    case DoubleStroke:
    case WavyStroke: {
      int thickness = SkMax32(static_cast<int>(strokeThickness()), 1);
      SkRect r;
      r.fLeft = WebCoreFloatToSkScalar(pt.x());
      // Avoid anti-aliasing lines. Currently, these are always horizontal.
      // Round to nearest pixel to match text and other content.
      r.fTop = WebCoreFloatToSkScalar(floorf(pt.y() + 0.5f));
      r.fRight = r.fLeft + WebCoreFloatToSkScalar(width);
      r.fBottom = r.fTop + SkIntToScalar(thickness);
      paint = immutableState()->fillPaint();
      // Text lines are drawn using the stroke color.
      paint.setColor(effectiveStrokeColor());
      drawRect(r, paint);
      return;
    }
    case DottedStroke:
    case DashedStroke: {
      int y = floorf(pt.y() + std::max<float>(strokeThickness() / 2.0f, 0.5f));
      drawLine(IntPoint(pt.x(), y), IntPoint(pt.x() + width, y));
      return;
    }
  }

  ASSERT_NOT_REACHED();
}

// Draws a filled rectangle with a stroked border.
void GraphicsContext::drawRect(const IntRect& rect) {
  if (contextDisabled())
    return;

  ASSERT(!rect.isEmpty());
  if (rect.isEmpty())
    return;

  SkRect skRect = rect;
  int fillcolorNotTransparent =
      immutableState()->fillColor().rgb() & 0xFF000000;
  if (fillcolorNotTransparent)
    drawRect(skRect, immutableState()->fillPaint());

  if (immutableState()->strokeData().style() != NoStroke &&
      immutableState()->strokeData().color().alpha()) {
    // Stroke a width: 1 inset border
    SkPaint paint(immutableState()->fillPaint());
    paint.setColor(effectiveStrokeColor());
    paint.setStyle(SkPaint::kStroke_Style);
    paint.setStrokeWidth(1);

    skRect.inset(0.5f, 0.5f);
    drawRect(skRect, paint);
  }
}

void GraphicsContext::drawText(const Font& font,
                               const TextRunPaintInfo& runInfo,
                               const FloatPoint& point) {
  if (contextDisabled())
    return;

  font.drawText(this, runInfo, point);
}

void GraphicsContext::drawEmphasisMarks(const Font& font,
                                        const TextRunPaintInfo& runInfo,
                                        const AtomicString& mark,
                                        const FloatPoint& point) {
  if (contextDisabled())
    return;

  font.drawEmphasisMarks(this, runInfo, mark, point);
}

void GraphicsContext::drawBidiText(
    const Font& font,
    const TextRunPaintInfo& runInfo,
    const FloatPoint& point,
    Font::CustomFontNotReadyAction customFontNotReadyAction) {
  if (contextDisabled())
    return;

  // sub-run painting is not supported for Bidi text.
  const TextRun& run = runInfo.run;
  ASSERT((runInfo.from == 0) && (runInfo.to == run.length()));
  BidiResolver<TextRunIterator, BidiCharacterRun> bidiResolver;
  bidiResolver.setStatus(
      BidiStatus(run.direction(), run.directionalOverride()));
  bidiResolver.setPositionIgnoringNestedIsolates(TextRunIterator(&run, 0));

  // FIXME: This ownership should be reversed. We should pass BidiRunList
  // to BidiResolver in createBidiRunsForLine.
  BidiRunList<BidiCharacterRun>& bidiRuns = bidiResolver.runs();
  bidiResolver.createBidiRunsForLine(TextRunIterator(&run, run.length()));
  if (!bidiRuns.runCount())
    return;

  FloatPoint currPoint = point;
  BidiCharacterRun* bidiRun = bidiRuns.firstRun();
  while (bidiRun) {
    TextRun subrun =
        run.subRun(bidiRun->start(), bidiRun->stop() - bidiRun->start());
    bool isRTL = bidiRun->level() % 2;
    subrun.setDirection(isRTL ? RTL : LTR);
    subrun.setDirectionalOverride(bidiRun->dirOverride());

    TextRunPaintInfo subrunInfo(subrun);
    subrunInfo.bounds = runInfo.bounds;
    float runWidth = font.drawUncachedText(this, subrunInfo, currPoint,
                                           customFontNotReadyAction);

    bidiRun = bidiRun->next();
    currPoint.move(runWidth, 0);
  }

  bidiRuns.deleteRuns();
}

void GraphicsContext::drawHighlightForText(const Font& font,
                                           const TextRun& run,
                                           const FloatPoint& point,
                                           int h,
                                           const Color& backgroundColor,
                                           int from,
                                           int to) {
  if (contextDisabled())
    return;

  fillRect(font.selectionRectForText(run, point, h, from, to), backgroundColor);
}

void GraphicsContext::drawImage(
    Image* image,
    const IntPoint& p,
    CompositeOperator op,
    RespectImageOrientationEnum shouldRespectImageOrientation) {
  if (!image)
    return;
  drawImage(image, FloatRect(IntRect(p, image->size())),
            FloatRect(FloatPoint(), FloatSize(image->size())), op,
            shouldRespectImageOrientation);
}

void GraphicsContext::drawImage(
    Image* image,
    const IntRect& r,
    CompositeOperator op,
    RespectImageOrientationEnum shouldRespectImageOrientation) {
  if (!image)
    return;
  drawImage(image, FloatRect(r),
            FloatRect(FloatPoint(), FloatSize(image->size())), op,
            shouldRespectImageOrientation);
}

void GraphicsContext::drawImage(
    Image* image,
    const FloatRect& dest,
    const FloatRect& src,
    CompositeOperator op,
    RespectImageOrientationEnum shouldRespectImageOrientation) {
  drawImage(image, dest, src, op, WebBlendModeNormal,
            shouldRespectImageOrientation);
}

void GraphicsContext::drawImage(Image* image, const FloatRect& dest) {
  if (!image)
    return;
  drawImage(image, dest, FloatRect(IntRect(IntPoint(), image->size())));
}

void GraphicsContext::drawImage(
    Image* image,
    const FloatRect& dest,
    const FloatRect& src,
    CompositeOperator op,
    WebBlendMode blendMode,
    RespectImageOrientationEnum shouldRespectImageOrientation) {
  if (contextDisabled() || !image)
    return;
  image->draw(this, dest, src, op, blendMode, shouldRespectImageOrientation);
}

void GraphicsContext::drawTiledImage(Image* image,
                                     const IntRect& destRect,
                                     const IntPoint& srcPoint,
                                     const IntSize& tileSize,
                                     CompositeOperator op,
                                     WebBlendMode blendMode,
                                     const IntSize& repeatSpacing) {
  if (contextDisabled() || !image)
    return;
  image->drawTiled(this, destRect, srcPoint, tileSize, op, blendMode,
                   repeatSpacing);
}

void GraphicsContext::drawTiledImage(Image* image,
                                     const IntRect& dest,
                                     const IntRect& srcRect,
                                     const FloatSize& tileScaleFactor,
                                     Image::TileRule hRule,
                                     Image::TileRule vRule,
                                     CompositeOperator op) {
  if (contextDisabled() || !image)
    return;

  if (hRule == Image::StretchTile && vRule == Image::StretchTile) {
    // Just do a scale.
    drawImage(image, dest, srcRect, op);
    return;
  }

  image->drawTiled(this, dest, srcRect, tileScaleFactor, hRule, vRule, op);
}

void GraphicsContext::drawBitmap(const SkBitmap& bitmap,
                                 SkScalar left,
                                 SkScalar top,
                                 const SkPaint* paint) {
  if (contextDisabled())
    return;

  m_canvas->drawBitmap(bitmap, left, top, paint);

  if (regionTrackingEnabled()) {
    SkRect rect = SkRect::MakeXYWH(left, top, bitmap.width(), bitmap.height());
    m_trackedRegion.didDrawRect(this, rect, *paint, &bitmap);
  }
}

void GraphicsContext::drawBitmapRect(const SkBitmap& bitmap,
                                     const SkRect* src,
                                     const SkRect& dst,
                                     const SkPaint* paint) {
  if (contextDisabled())
    return;

  SkCanvas::SrcRectConstraint flags =
      immutableState()->shouldClampToSourceRect()
          ? SkCanvas::kStrict_SrcRectConstraint
          : SkCanvas::kFast_SrcRectConstraint;

  m_canvas->drawBitmapRect(bitmap, *src, dst, paint, flags);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawRect(this, dst, *paint, &bitmap);
}

void GraphicsContext::drawOval(const SkRect& oval, const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawOval(oval, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawBounded(this, oval, paint);
}

void GraphicsContext::drawPath(const SkPath& path, const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawPath(path, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawPath(this, path, paint);
}

void GraphicsContext::drawRect(const SkRect& rect, const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawRect(rect, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawRect(this, rect, paint, 0);
}

void GraphicsContext::drawRRect(const SkRRect& rrect, const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawRRect(rrect, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawBounded(this, rrect.rect(), paint);
}

void GraphicsContext::didDrawRect(const SkRect& rect,
                                  const SkPaint& paint,
                                  const SkBitmap* bitmap) {
  if (contextDisabled())
    return;

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawRect(this, rect, paint, bitmap);
}

void GraphicsContext::drawPosText(const void* text,
                                  size_t byteLength,
                                  const SkPoint pos[],
                                  const SkRect& textRect,
                                  const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawPosText(text, byteLength, pos, paint);
  didDrawTextInRect(textRect);

  // FIXME: compute bounds for positioned text.
  if (regionTrackingEnabled())
    m_trackedRegion.didDrawUnbounded(this, paint, RegionTracker::FillOrStroke);
}

void GraphicsContext::drawPosTextH(const void* text,
                                   size_t byteLength,
                                   const SkScalar xpos[],
                                   SkScalar constY,
                                   const SkRect& textRect,
                                   const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawPosTextH(text, byteLength, xpos, constY, paint);
  didDrawTextInRect(textRect);

  // FIXME: compute bounds for positioned text.
  if (regionTrackingEnabled())
    m_trackedRegion.didDrawUnbounded(this, paint, RegionTracker::FillOrStroke);
}

void GraphicsContext::drawTextBlob(const SkTextBlob* blob,
                                   const SkPoint& origin,
                                   const SkPaint& paint) {
  if (contextDisabled())
    return;

  m_canvas->drawTextBlob(blob, origin.x(), origin.y(), paint);

  SkRect bounds = blob->bounds();
  bounds.offset(origin);
  didDrawTextInRect(bounds);

  // FIXME: use bounds here if it helps performance.
  if (regionTrackingEnabled())
    m_trackedRegion.didDrawUnbounded(this, paint, RegionTracker::FillOrStroke);
}

void GraphicsContext::fillPath(const Path& pathToFill) {
  if (contextDisabled() || pathToFill.isEmpty())
    return;

  // Use const_cast and temporarily modify the fill type instead of copying the
  // path.
  SkPath& path = const_cast<SkPath&>(pathToFill.skPath());
  SkPath::FillType previousFillType = path.getFillType();

  SkPath::FillType temporaryFillType =
      WebCoreWindRuleToSkFillType(immutableState()->fillRule());
  path.setFillType(temporaryFillType);

  drawPath(path, immutableState()->fillPaint());

  path.setFillType(previousFillType);
}

void GraphicsContext::fillRect(const FloatRect& rect) {
  if (contextDisabled())
    return;

  SkRect r = rect;

  drawRect(r, immutableState()->fillPaint());
}

void GraphicsContext::fillRect(const FloatRect& rect, const Color& color) {
  if (contextDisabled())
    return;

  SkRect r = rect;
  SkPaint paint = immutableState()->fillPaint();
  paint.setColor(color.rgb());
  drawRect(r, paint);
}

void GraphicsContext::fillBetweenRoundedRects(const IntRect& outer,
                                              const IntSize& outerTopLeft,
                                              const IntSize& outerTopRight,
                                              const IntSize& outerBottomLeft,
                                              const IntSize& outerBottomRight,
                                              const IntRect& inner,
                                              const IntSize& innerTopLeft,
                                              const IntSize& innerTopRight,
                                              const IntSize& innerBottomLeft,
                                              const IntSize& innerBottomRight,
                                              const Color& color) {
  if (contextDisabled())
    return;

  SkVector outerRadii[4];
  SkVector innerRadii[4];
  setRadii(outerRadii, outerTopLeft, outerTopRight, outerBottomRight,
           outerBottomLeft);
  setRadii(innerRadii, innerTopLeft, innerTopRight, innerBottomRight,
           innerBottomLeft);

  SkRRect rrOuter;
  SkRRect rrInner;
  rrOuter.setRectRadii(outer, outerRadii);
  rrInner.setRectRadii(inner, innerRadii);

  SkPaint paint(immutableState()->fillPaint());
  paint.setColor(color.rgb());

  m_canvas->drawDRRect(rrOuter, rrInner, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawBounded(this, rrOuter.getBounds(), paint);
}

void GraphicsContext::fillBetweenRoundedRects(const RoundedRect& outer,
                                              const RoundedRect& inner,
                                              const Color& color) {
  fillBetweenRoundedRects(
      outer.rect(), outer.radii().topLeft(), outer.radii().topRight(),
      outer.radii().bottomLeft(), outer.radii().bottomRight(), inner.rect(),
      inner.radii().topLeft(), inner.radii().topRight(),
      inner.radii().bottomLeft(), inner.radii().bottomRight(), color);
}

void GraphicsContext::fillRoundedRect(const IntRect& rect,
                                      const IntSize& topLeft,
                                      const IntSize& topRight,
                                      const IntSize& bottomLeft,
                                      const IntSize& bottomRight,
                                      const Color& color) {
  if (contextDisabled())
    return;

  if (topLeft.width() + topRight.width() > rect.width() ||
      bottomLeft.width() + bottomRight.width() > rect.width() ||
      topLeft.height() + bottomLeft.height() > rect.height() ||
      topRight.height() + bottomRight.height() > rect.height()) {
    // Not all the radii fit, return a rect. This matches the behavior of
    // Path::createRoundedRectangle. Without this we attempt to draw a round
    // shadow for a square box.
    fillRect(rect, color);
    return;
  }

  SkVector radii[4];
  setRadii(radii, topLeft, topRight, bottomRight, bottomLeft);

  SkRRect rr;
  rr.setRectRadii(rect, radii);

  SkPaint paint(immutableState()->fillPaint());
  paint.setColor(color.rgb());

  m_canvas->drawRRect(rr, paint);

  if (regionTrackingEnabled())
    m_trackedRegion.didDrawBounded(this, rr.getBounds(), paint);
}

void GraphicsContext::fillEllipse(const FloatRect& ellipse) {
  if (contextDisabled())
    return;

  SkRect rect = ellipse;
  drawOval(rect, immutableState()->fillPaint());
}

void GraphicsContext::strokePath(const Path& pathToStroke) {
  if (contextDisabled() || pathToStroke.isEmpty())
    return;

  const SkPath& path = pathToStroke.skPath();
  drawPath(path, immutableState()->strokePaint());
}

void GraphicsContext::strokeRect(const FloatRect& rect) {
  strokeRect(rect, strokeThickness());
}

void GraphicsContext::strokeRect(const FloatRect& rect, float lineWidth) {
  if (contextDisabled())
    return;

  SkPaint paint(immutableState()->strokePaint());
  paint.setStrokeWidth(WebCoreFloatToSkScalar(lineWidth));
  // Reset the dash effect to account for the width
  immutableState()->strokeData().setupPaintDashPathEffect(&paint, 0);
  // strokerect has special rules for CSS when the rect is degenerate:
  // if width==0 && height==0, do nothing
  // if width==0 || height==0, then just draw line for the other dimension
  SkRect r(rect);
  bool validW = r.width() > 0;
  bool validH = r.height() > 0;
  if (validW && validH) {
    drawRect(r, paint);
  } else if (validW || validH) {
    // we are expected to respect the lineJoin, so we can't just call
    // drawLine -- we have to create a path that doubles back on itself.
    SkPath path;
    path.moveTo(r.fLeft, r.fTop);
    path.lineTo(r.fRight, r.fBottom);
    path.close();
    drawPath(path, paint);
  }
}

void GraphicsContext::strokeEllipse(const FloatRect& ellipse) {
  if (contextDisabled())
    return;

  drawOval(ellipse, immutableState()->strokePaint());
}

void GraphicsContext::clipRoundedRect(const RoundedRect& rect,
                                      SkClipOp clipOp) {
  if (contextDisabled())
    return;

  if (!rect.isRounded()) {
    clipRect(rect.rect(), NotAntiAliased, clipOp);
    return;
  }

  SkVector radii[4];
  RoundedRect::Radii wkRadii = rect.radii();
  setRadii(radii, wkRadii.topLeft(), wkRadii.topRight(), wkRadii.bottomRight(),
           wkRadii.bottomLeft());

  SkRRect r;
  r.setRectRadii(rect.rect(), radii);

  clipRRect(r, AntiAliased, clipOp);
}

void GraphicsContext::clipOut(const Path& pathToClip) {
  if (contextDisabled())
    return;

  // Use const_cast and temporarily toggle the inverse fill type instead of
  // copying the path.
  SkPath& path = const_cast<SkPath&>(pathToClip.skPath());
  path.toggleInverseFillType();
  clipPath(path, AntiAliased);
  path.toggleInverseFillType();
}

void GraphicsContext::clipPath(const Path& pathToClip, WindRule clipRule) {
  if (contextDisabled() || pathToClip.isEmpty())
    return;

  // Use const_cast and temporarily modify the fill type instead of copying the
  // path.
  SkPath& path = const_cast<SkPath&>(pathToClip.skPath());
  SkPath::FillType previousFillType = path.getFillType();

  SkPath::FillType temporaryFillType = WebCoreWindRuleToSkFillType(clipRule);
  path.setFillType(temporaryFillType);
  clipPath(path, AntiAliased);

  path.setFillType(previousFillType);
}

void GraphicsContext::clipConvexPolygon(size_t numPoints,
                                        const FloatPoint* points,
                                        bool antialiased) {
  if (contextDisabled())
    return;

  if (numPoints <= 1)
    return;

  SkPath path;
  setPathFromConvexPoints(&path, numPoints, points);
  clipPath(path, antialiased ? AntiAliased : NotAntiAliased);
}

void GraphicsContext::clipOutRoundedRect(const RoundedRect& rect) {
  if (contextDisabled())
    return;

  clipRoundedRect(rect, SkClipOp::kDifference);
}

void GraphicsContext::canvasClip(const Path& pathToClip, WindRule clipRule) {
  if (contextDisabled())
    return;

  // Use const_cast and temporarily modify the fill type instead of copying the
  // path.
  SkPath& path = const_cast<SkPath&>(pathToClip.skPath());
  SkPath::FillType previousFillType = path.getFillType();

  SkPath::FillType temporaryFillType = WebCoreWindRuleToSkFillType(clipRule);
  path.setFillType(temporaryFillType);
  clipPath(path);

  path.setFillType(previousFillType);
}

void GraphicsContext::clipRect(const SkRect& rect,
                               AntiAliasingMode aa,
                               SkClipOp op) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->clipRect(rect, op, aa == AntiAliased);
}

void GraphicsContext::clipPath(const SkPath& path,
                               AntiAliasingMode aa,
                               SkClipOp op) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->clipPath(path, op, aa == AntiAliased);
}

void GraphicsContext::clipRRect(const SkRRect& rect,
                                AntiAliasingMode aa,
                                SkClipOp op) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->clipRRect(rect, op, aa == AntiAliased);
}

void GraphicsContext::rotate(float angleInRadians) {
  if (contextDisabled())
    return;

  realizeCanvasSave();

  m_canvas->rotate(
      WebCoreFloatToSkScalar(angleInRadians * (180.0f / 3.14159265f)));
}

void GraphicsContext::translate(float x, float y) {
  if (contextDisabled())
    return;

  if (!x && !y)
    return;

  realizeCanvasSave();

  m_canvas->translate(WebCoreFloatToSkScalar(x), WebCoreFloatToSkScalar(y));
}

void GraphicsContext::scale(float x, float y) {
  if (contextDisabled())
    return;

  if (x == 1.0f && y == 1.0f)
    return;

  realizeCanvasSave();

  m_canvas->scale(WebCoreFloatToSkScalar(x), WebCoreFloatToSkScalar(y));
}

AffineTransform GraphicsContext::getCTM() const {
  if (contextDisabled())
    return AffineTransform();

  SkMatrix m = getTotalMatrix();
  return AffineTransform(
      SkScalarToDouble(m.getScaleX()), SkScalarToDouble(m.getSkewY()),
      SkScalarToDouble(m.getSkewX()), SkScalarToDouble(m.getScaleY()),
      SkScalarToDouble(m.getTranslateX()), SkScalarToDouble(m.getTranslateY()));
}

void GraphicsContext::fillRect(const FloatRect& rect,
                               const Color& color,
                               CompositeOperator op) {
  if (contextDisabled())
    return;

  CompositeOperator previousOperator = compositeOperation();
  setCompositeOperation(op);
  fillRect(rect, color);
  setCompositeOperation(previousOperator);
}

void GraphicsContext::fillRoundedRect(const RoundedRect& rect,
                                      const Color& color) {
  if (contextDisabled())
    return;

  if (rect.isRounded())
    fillRoundedRect(rect.rect(), rect.radii().topLeft(),
                    rect.radii().topRight(), rect.radii().bottomLeft(),
                    rect.radii().bottomRight(), color);
  else
    fillRect(rect.rect(), color);
}

void GraphicsContext::fillRectWithRoundedHole(
    const IntRect& rect,
    const RoundedRect& roundedHoleRect,
    const Color& color) {
  if (contextDisabled())
    return;

  Path path;
  path.addRect(rect);

  if (!roundedHoleRect.radii().isZero())
    path.addRoundedRect(roundedHoleRect);
  else
    path.addRect(roundedHoleRect.rect());

  WindRule oldFillRule = fillRule();
  Color oldFillColor = fillColor();

  setFillRule(RULE_EVENODD);
  setFillColor(color);

  fillPath(path);

  setFillRule(oldFillRule);
  setFillColor(oldFillColor);
}

void GraphicsContext::clearRect(const FloatRect& rect) {
  if (contextDisabled())
    return;

  SkRect r = rect;
  SkPaint paint(immutableState()->fillPaint());
  paint.setBlendMode(SkBlendMode::kClear);
  drawRect(r, paint);
}

void GraphicsContext::adjustLineToPixelBoundaries(FloatPoint& p1,
                                                  FloatPoint& p2,
                                                  float strokeWidth,
                                                  StrokeStyle penStyle) {
  // For odd widths, we add in 0.5 to the appropriate x/y so that the float
  // arithmetic works out.  For example, with a border width of 3, WebKit will
  // pass us (y1+y2)/2, e.g., (50+53)/2 = 103/2 = 51 when we want 51.5.  It is
  // always true that an even width gave us a perfect position, but an odd width
  // gave us a position that is off by exactly 0.5.
  if (penStyle == DottedStroke || penStyle == DashedStroke) {
    if (p1.x() == p2.x()) {
      p1.setY(p1.y() + strokeWidth);
      p2.setY(p2.y() - strokeWidth);
    } else {
      p1.setX(p1.x() + strokeWidth);
      p2.setX(p2.x() - strokeWidth);
    }
  }

  if (static_cast<int>(strokeWidth) % 2) {  // odd
    if (p1.x() == p2.x()) {
      // We're a vertical line.  Adjust our x.
      p1.setX(p1.x() + 0.5f);
      p2.setX(p2.x() + 0.5f);
    } else {
      // We're a horizontal line. Adjust our y.
      p1.setY(p1.y() + 0.5f);
      p2.setY(p2.y() + 0.5f);
    }
  }
}

void GraphicsContext::setPathFromConvexPoints(SkPath* path,
                                              size_t numPoints,
                                              const FloatPoint* points) {
  path->incReserve(numPoints);
  path->moveTo(WebCoreFloatToSkScalar(points[0].x()),
               WebCoreFloatToSkScalar(points[0].y()));
  for (size_t i = 1; i < numPoints; ++i) {
    path->lineTo(WebCoreFloatToSkScalar(points[i].x()),
                 WebCoreFloatToSkScalar(points[i].y()));
  }
}

void GraphicsContext::setRadii(SkVector* radii,
                               IntSize topLeft,
                               IntSize topRight,
                               IntSize bottomRight,
                               IntSize bottomLeft) {
  radii[SkRRect::kUpperLeft_Corner].set(SkIntToScalar(topLeft.width()),
                                        SkIntToScalar(topLeft.height()));
  radii[SkRRect::kUpperRight_Corner].set(SkIntToScalar(topRight.width()),
                                         SkIntToScalar(topRight.height()));
  radii[SkRRect::kLowerRight_Corner].set(SkIntToScalar(bottomRight.width()),
                                         SkIntToScalar(bottomRight.height()));
  radii[SkRRect::kLowerLeft_Corner].set(SkIntToScalar(bottomLeft.width()),
                                        SkIntToScalar(bottomLeft.height()));
}

void GraphicsContext::draw2xMarker(SkBitmap* bitmap, int index) {
  const SkPMColor lineColor = lineColors(index);
  const SkPMColor antiColor1 = antiColors1(index);
  const SkPMColor antiColor2 = antiColors2(index);

  uint32_t* row1 = bitmap->getAddr32(0, 0);
  uint32_t* row2 = bitmap->getAddr32(0, 1);
  uint32_t* row3 = bitmap->getAddr32(0, 2);
  uint32_t* row4 = bitmap->getAddr32(0, 3);

  // Pattern: X0o   o0X0o   o0
  //          XX0o o0XXX0o o0X
  //           o0XXX0o o0XXX0o
  //            o0X0o   o0X0o
  const SkPMColor row1Color[] = {lineColor, antiColor1, antiColor2, 0,
                                 0,         0,          antiColor2, antiColor1};
  const SkPMColor row2Color[] = {lineColor, lineColor,  antiColor1, antiColor2,
                                 0,         antiColor2, antiColor1, lineColor};
  const SkPMColor row3Color[] = {0,         antiColor2, antiColor1, lineColor,
                                 lineColor, lineColor,  antiColor1, antiColor2};
  const SkPMColor row4Color[] = {0,         0,          antiColor2, antiColor1,
                                 lineColor, antiColor1, antiColor2, 0};

  for (int x = 0; x < bitmap->width() + 8; x += 8) {
    int count = std::min(bitmap->width() - x, 8);
    if (count > 0) {
      memcpy(row1 + x, row1Color, count * sizeof(SkPMColor));
      memcpy(row2 + x, row2Color, count * sizeof(SkPMColor));
      memcpy(row3 + x, row3Color, count * sizeof(SkPMColor));
      memcpy(row4 + x, row4Color, count * sizeof(SkPMColor));
    }
  }
}

void GraphicsContext::draw1xMarker(SkBitmap* bitmap, int index) {
  const uint32_t lineColor = lineColors(index);
  const uint32_t antiColor = antiColors2(index);

  // Pattern: X o   o X o   o X
  //            o X o   o X o
  uint32_t* row1 = bitmap->getAddr32(0, 0);
  uint32_t* row2 = bitmap->getAddr32(0, 1);
  for (int x = 0; x < bitmap->width(); x++) {
    switch (x % 4) {
      case 0:
        row1[x] = lineColor;
        break;
      case 1:
        row1[x] = antiColor;
        row2[x] = antiColor;
        break;
      case 2:
        row2[x] = lineColor;
        break;
      case 3:
        row1[x] = antiColor;
        row2[x] = antiColor;
        break;
    }
  }
}

SkPMColor GraphicsContext::lineColors(int index) {
  static const SkPMColor colors[] = {
      SkPreMultiplyARGB(0xFF, 0xFF, 0x00, 0x00),  // Opaque red.
      SkPreMultiplyARGB(0xFF, 0xC0, 0xC0, 0xC0)   // Opaque gray.
  };

  return colors[index];
}

SkPMColor GraphicsContext::antiColors1(int index) {
  static const SkPMColor colors[] = {
      SkPreMultiplyARGB(0xB0, 0xFF, 0x00, 0x00),  // Semitransparent red.
      SkPreMultiplyARGB(0xB0, 0xC0, 0xC0, 0xC0)   // Semitransparent gray.
  };

  return colors[index];
}

SkPMColor GraphicsContext::antiColors2(int index) {
  static const SkPMColor colors[] = {
      SkPreMultiplyARGB(0x60, 0xFF, 0x00, 0x00),  // More transparent red
      SkPreMultiplyARGB(0x60, 0xC0, 0xC0, 0xC0)   // More transparent gray
  };

  return colors[index];
}

void GraphicsContext::didDrawTextInRect(const SkRect& textRect) {
  if (m_trackTextRegion)
    m_textRegion.join(textRect);
}

void GraphicsContext::preparePaintForDrawRectToRect(
    SkPaint* paint,
    const SkRect& srcRect,
    const SkRect& destRect,
    CompositeOperator compositeOp,
    WebBlendMode blendMode,
    bool isLazyDecoded,
    bool isDataComplete) const {
  paint->setBlendMode(WebCoreCompositeToSkiaComposite(compositeOp, blendMode));
  paint->setColorFilter(sk_ref_sp(this->colorFilter()));
  paint->setAlpha(this->getNormalizedAlpha());
  paint->setLooper(this->drawLooper());
  paint->setAntiAlias(shouldDrawAntiAliased(this, destRect));

  InterpolationQuality resampling;
  if (this->isAccelerated()) {
    resampling = InterpolationLow;
  } else if (isLazyDecoded) {
    resampling = InterpolationHigh;
  } else {
    // Take into account scale applied to the canvas when computing sampling
    // mode (e.g. CSS scale or page scale).
    SkRect destRectTarget = destRect;
    SkMatrix totalMatrix = this->getTotalMatrix();
    if (!(totalMatrix.getType() &
          (SkMatrix::kAffine_Mask | SkMatrix::kPerspective_Mask)))
      totalMatrix.mapRect(&destRectTarget, destRect);

    resampling = computeInterpolationQuality(
        totalMatrix, SkScalarToFloat(srcRect.width()),
        SkScalarToFloat(srcRect.height()),
        SkScalarToFloat(destRectTarget.width()),
        SkScalarToFloat(destRectTarget.height()), isDataComplete);
  }

  if (resampling == InterpolationNone) {
    // FIXME: This is to not break tests (it results in the filter bitmap flag
    // being set to true). We need to decide if we respect InterpolationNone
    // being returned from computeInterpolationQuality.
    resampling = InterpolationLow;
  }
  resampling = limitInterpolationQuality(this, resampling);
  paint->setFilterQuality(static_cast<SkFilterQuality>(resampling));
}

}  // namespace blink
