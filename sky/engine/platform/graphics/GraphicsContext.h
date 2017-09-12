/*
 * Copyright (C) 2003, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2008-2009 Torch Mobile, Inc.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_PLATFORM_GRAPHICS_GRAPHICSCONTEXT_H_
#define SKY_ENGINE_PLATFORM_GRAPHICS_GRAPHICSCONTEXT_H_

#include "flutter/sky/engine/platform/PlatformExport.h"
#include "flutter/sky/engine/platform/fonts/Font.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/platform/graphics/DashArray.h"
#include "flutter/sky/engine/platform/graphics/DrawLooperBuilder.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContextState.h"
#include "flutter/sky/engine/platform/graphics/ImageFilter.h"
#include "flutter/sky/engine/platform/graphics/ImageOrientation.h"
#include "flutter/sky/engine/platform/graphics/RegionTracker.h"
#include "flutter/sky/engine/platform/graphics/skia/SkiaUtils.h"
#include "flutter/sky/engine/wtf/FastAllocBase.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/Noncopyable.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"

class SkBitmap;
class SkPaint;
class SkPath;
class SkRRect;
class SkTextBlob;
struct SkRect;

namespace blink {

class KURL;

class PLATFORM_EXPORT GraphicsContext {
  WTF_MAKE_NONCOPYABLE(GraphicsContext);
  WTF_MAKE_FAST_ALLOCATED;

 public:
  enum AntiAliasingMode { NotAntiAliased, AntiAliased };
  enum AccessMode { ReadOnly, ReadWrite };

  enum DisabledMode {
    NothingDisabled = 0,  // Run as normal.
    FullyDisabled = 1  // Do absolutely minimal work to remove the cost of the
                       // context from performance tests.
  };

  explicit GraphicsContext(SkCanvas*, DisabledMode = NothingDisabled);
  ~GraphicsContext();

  // Returns the canvas used for painting. Must not be called if painting is
  // disabled. Accessing the backing canvas this way flushes all queued save
  // ops, so it should be avoided. Use the corresponding draw/matrix/clip
  // methods instead.
  SkCanvas* canvas() {
    // Flush any pending saves.
    realizeCanvasSave();

    return m_canvas;
  }
  const SkCanvas* canvas() const { return m_canvas; }

  void resetCanvas(SkCanvas*);

  bool contextDisabled() const { return m_disabledState; }

  // ---------- State management methods -----------------
  void save();
  void restore();
  unsigned saveCount() { return m_canvasStateStack.size(); }
#if ENABLE(ASSERT)
  void disableDestructionChecks() { m_disableDestructionChecks = true; }
#endif

  void saveLayer(const SkRect* bounds, const SkPaint*);
  void restoreLayer();

  bool hasStroke() const {
    return strokeStyle() != NoStroke && strokeThickness() > 0;
  }

  float strokeThickness() const {
    return immutableState()->strokeData().thickness();
  }
  void setStrokeThickness(float thickness) {
    mutableState()->setStrokeThickness(thickness);
  }

  StrokeStyle strokeStyle() const {
    return immutableState()->strokeData().style();
  }
  void setStrokeStyle(StrokeStyle style) {
    mutableState()->setStrokeStyle(style);
  }

  Color strokeColor() const { return immutableState()->strokeData().color(); }
  void setStrokeColor(const Color& color) {
    mutableState()->setStrokeColor(color);
  }
  SkColor effectiveStrokeColor() const {
    return immutableState()->effectiveStrokeColor();
  }

  Pattern* strokePattern() const {
    return immutableState()->strokeData().pattern();
  }
  void setStrokePattern(PassRefPtr<Pattern>);

  Gradient* strokeGradient() const {
    return immutableState()->strokeData().gradient();
  }
  void setStrokeGradient(PassRefPtr<Gradient>);

  void setLineCap(LineCap cap) { mutableState()->setLineCap(cap); }
  void setLineDash(const DashArray& dashes, float dashOffset) {
    mutableState()->setLineDash(dashes, dashOffset);
  }
  void setLineJoin(LineJoin join) { mutableState()->setLineJoin(join); }
  void setMiterLimit(float limit) { mutableState()->setMiterLimit(limit); }

  WindRule fillRule() const { return immutableState()->fillRule(); }
  void setFillRule(WindRule fillRule) { mutableState()->setFillRule(fillRule); }

  Color fillColor() const { return immutableState()->fillColor(); }
  void setFillColor(const Color& color) { mutableState()->setFillColor(color); }
  SkColor effectiveFillColor() const {
    return immutableState()->effectiveFillColor();
  }

  void setFillPattern(PassRefPtr<Pattern>);
  Pattern* fillPattern() const { return immutableState()->fillPattern(); }

  void setFillGradient(PassRefPtr<Gradient>);
  Gradient* fillGradient() const { return immutableState()->fillGradient(); }

  const sk_sp<SkDrawLooper>& drawLooper() const {
    return immutableState()->drawLooper();
  }

  bool getTransformedClipBounds(FloatRect* bounds) const;
  SkMatrix getTotalMatrix() const;

  void setShouldAntialias(bool antialias) {
    mutableState()->setShouldAntialias(antialias);
  }
  bool shouldAntialias() const { return immutableState()->shouldAntialias(); }

  // Disable the anti-aliasing optimization for scales/multiple-of-90-degrees
  // rotations of thin ("hairline") images.
  // Note: This will only be reliable when the device pixel scale/ratio is
  // fixed (e.g. when drawing to context backed by an ImageBuffer).
  void disableAntialiasingOptimizationForHairlineImages() {
    m_antialiasHairlineImages = true;
  }
  bool shouldAntialiasHairlineImages() const {
    return m_antialiasHairlineImages;
  }

  void setShouldClampToSourceRect(bool clampToSourceRect) {
    mutableState()->setShouldClampToSourceRect(clampToSourceRect);
  }
  bool shouldClampToSourceRect() const {
    return immutableState()->shouldClampToSourceRect();
  }

  // FIXME: the setter is only used once, at construction time; convert to a
  // constructor param, and possibly consolidate with other flags
  // (paintDisabled, isPrinting, ...)
  void setShouldSmoothFonts(bool smoothFonts) {
    m_shouldSmoothFonts = smoothFonts;
  }

  // Turn off LCD text for the paint if not supported on this context.
  void adjustTextRenderMode(SkPaint*);
  bool couldUseLCDRenderedText() const {
    return m_isCertainlyOpaque && m_shouldSmoothFonts;
  }

  void setTextDrawingMode(TextDrawingModeFlags mode) {
    mutableState()->setTextDrawingMode(mode);
  }
  TextDrawingModeFlags textDrawingMode() const {
    return immutableState()->textDrawingMode();
  }

  void setAlphaAsFloat(float alpha) { mutableState()->setAlphaAsFloat(alpha); }
  int getNormalizedAlpha() const {
    int alpha = immutableState()->alpha();
    return alpha > 255 ? 255 : alpha;
  }

  void setImageInterpolationQuality(InterpolationQuality quality) {
    mutableState()->setInterpolationQuality(quality);
  }
  InterpolationQuality imageInterpolationQuality() const {
    return immutableState()->interpolationQuality();
  }

  void setCompositeOperation(CompositeOperator,
                             WebBlendMode = WebBlendModeNormal);
  CompositeOperator compositeOperation() const {
    return immutableState()->compositeOperator();
  }
  WebBlendMode blendModeOperation() const {
    return immutableState()->blendMode();
  }

  // Speicy the device scale factor which may change the way document markers
  // and fonts are rendered.
  void setDeviceScaleFactor(float factor) { m_deviceScaleFactor = factor; }
  float deviceScaleFactor() const { return m_deviceScaleFactor; }

  // If true we are (most likely) rendering to a web page and the
  // canvas has been prepared with an opaque background. If false,
  // the canvas may have transparency (as is the case when rendering
  // to a canvas object).
  void setCertainlyOpaque(bool isOpaque) { m_isCertainlyOpaque = isOpaque; }

  bool isAccelerated() const { return m_accelerated; }
  void setAccelerated(bool accelerated) { m_accelerated = accelerated; }

  // The opaque region is empty until tracking is turned on.
  // It is never clerared by the context.
  enum RegionTrackingMode {
    RegionTrackingDisabled = 0,
    RegionTrackingOpaque,
    RegionTrackingOverwrite
  };
  void setRegionTrackingMode(RegionTrackingMode);
  bool regionTrackingEnabled() {
    return m_regionTrackingMode != RegionTrackingDisabled;
  }
  const RegionTracker& opaqueRegion() const { return m_trackedRegion; }

  // The text region is empty until tracking is turned on.
  // It is never clerared by the context.
  void setTrackTextRegion(bool track) { m_trackTextRegion = track; }
  const SkRect& textRegion() const { return m_textRegion; }

  SkColorFilter* colorFilter() const;
  void setColorFilter(ColorFilterObsolete);
  // ---------- End state management methods -----------------

  // Get the contents of the image buffer
  bool readPixels(const SkImageInfo&,
                  void* pixels,
                  size_t rowBytes,
                  int x,
                  int y);

  // Get the current fill style.
  const SkPaint& fillPaint() const { return immutableState()->fillPaint(); }

  // Get the current stroke style.
  const SkPaint& strokePaint() const { return immutableState()->strokePaint(); }

  // These draw methods will do both stroking and filling.
  // FIXME: ...except drawRect(), which fills properly but always strokes
  // using a 1-pixel stroke inset from the rect borders (of the correct
  // stroke color).
  void drawRect(const IntRect&);
  void drawLine(const IntPoint&, const IntPoint&);
  void drawConvexPolygon(size_t numPoints,
                         const FloatPoint*,
                         bool shouldAntialias = false);

  void fillPath(const Path&);
  void strokePath(const Path&);

  void fillEllipse(const FloatRect&);
  void strokeEllipse(const FloatRect&);

  void fillRect(const FloatRect&);
  void fillRect(const FloatRect&, const Color&);
  void fillRect(const FloatRect&, const Color&, CompositeOperator);
  void fillRoundedRect(const IntRect&,
                       const IntSize& topLeft,
                       const IntSize& topRight,
                       const IntSize& bottomLeft,
                       const IntSize& bottomRight,
                       const Color&);
  void fillRoundedRect(const RoundedRect&, const Color&);

  void clearRect(const FloatRect&);

  void strokeRect(const FloatRect&);
  void strokeRect(const FloatRect&, float lineWidth);

  void fillBetweenRoundedRects(const IntRect&,
                               const IntSize& outerTopLeft,
                               const IntSize& outerTopRight,
                               const IntSize& outerBottomLeft,
                               const IntSize& outerBottomRight,
                               const IntRect&,
                               const IntSize& innerTopLeft,
                               const IntSize& innerTopRight,
                               const IntSize& innerBottomLeft,
                               const IntSize& innerBottomRight,
                               const Color&);
  void fillBetweenRoundedRects(const RoundedRect&,
                               const RoundedRect&,
                               const Color&);

  void drawImage(Image*,
                 const IntPoint&,
                 CompositeOperator = CompositeSourceOver,
                 RespectImageOrientationEnum = DoNotRespectImageOrientation);
  void drawImage(Image*,
                 const IntRect&,
                 CompositeOperator = CompositeSourceOver,
                 RespectImageOrientationEnum = DoNotRespectImageOrientation);
  void drawImage(Image*, const FloatRect& destRect);
  void drawImage(Image*,
                 const FloatRect& destRect,
                 const FloatRect& srcRect,
                 CompositeOperator = CompositeSourceOver,
                 RespectImageOrientationEnum = DoNotRespectImageOrientation);
  void drawImage(Image*,
                 const FloatRect& destRect,
                 const FloatRect& srcRect,
                 CompositeOperator,
                 WebBlendMode,
                 RespectImageOrientationEnum = DoNotRespectImageOrientation);

  void drawTiledImage(Image*,
                      const IntRect& destRect,
                      const IntPoint& srcPoint,
                      const IntSize& tileSize,
                      CompositeOperator = CompositeSourceOver,
                      WebBlendMode = WebBlendModeNormal,
                      const IntSize& repeatSpacing = IntSize());
  void drawTiledImage(Image*,
                      const IntRect& destRect,
                      const IntRect& srcRect,
                      const FloatSize& tileScaleFactor,
                      Image::TileRule hRule = Image::StretchTile,
                      Image::TileRule vRule = Image::StretchTile,
                      CompositeOperator = CompositeSourceOver);

  void drawBitmap(const SkBitmap&, SkScalar, SkScalar, const SkPaint* = 0);
  void drawBitmapRect(const SkBitmap&,
                      const SkRect*,
                      const SkRect&,
                      const SkPaint* = 0);
  void drawOval(const SkRect&, const SkPaint&);
  void drawPath(const SkPath&, const SkPaint&);
  // After drawing directly to the context's canvas, use this function to notify
  // the context so it can track the opaque region.
  // FIXME: this is still needed only because ImageSkia::paintSkBitmap() may
  // need to notify for a
  //        smaller rect than the one drawn to, due to its clipping logic.
  void didDrawRect(const SkRect&, const SkPaint&, const SkBitmap* = 0);
  void drawRect(const SkRect&, const SkPaint&);
  void drawPosText(const void* text,
                   size_t byteLength,
                   const SkPoint pos[],
                   const SkRect& textRect,
                   const SkPaint&);
  void drawPosTextH(const void* text,
                    size_t byteLength,
                    const SkScalar xpos[],
                    SkScalar constY,
                    const SkRect& textRect,
                    const SkPaint&);
  void drawTextBlob(const SkTextBlob*, const SkPoint& origin, const SkPaint&);

  void clip(const IntRect& rect) { clipRect(rect); }
  void clip(const FloatRect& rect) { clipRect(rect); }
  void clipRoundedRect(const RoundedRect&, SkClipOp = SkClipOp::kIntersect);
  void clipOut(const IntRect& rect) {
    clipRect(rect, NotAntiAliased, SkClipOp::kDifference);
  }
  void clipOutRoundedRect(const RoundedRect&);
  void clipPath(const Path&, WindRule = RULE_EVENODD);
  void clipConvexPolygon(size_t numPoints,
                         const FloatPoint*,
                         bool antialias = true);
  void clipRect(const SkRect&,
                AntiAliasingMode = NotAntiAliased,
                SkClipOp = SkClipOp::kIntersect);

  void drawText(const Font&, const TextRunPaintInfo&, const FloatPoint&);
  void drawEmphasisMarks(const Font&,
                         const TextRunPaintInfo&,
                         const AtomicString& mark,
                         const FloatPoint&);
  void drawBidiText(
      const Font&,
      const TextRunPaintInfo&,
      const FloatPoint&,
      Font::CustomFontNotReadyAction = Font::DoNotPaintIfFontNotReady);
  void drawHighlightForText(const Font&,
                            const TextRun&,
                            const FloatPoint&,
                            int h,
                            const Color& backgroundColor,
                            int from = 0,
                            int to = -1);

  void drawLineForText(const FloatPoint&, float width);
  enum DocumentMarkerLineStyle {
    DocumentMarkerSpellingLineStyle,
    DocumentMarkerGrammarLineStyle
  };
  void drawLineForDocumentMarker(const FloatPoint&,
                                 float width,
                                 DocumentMarkerLineStyle);

  void beginTransparencyLayer(float opacity, const FloatRect* = 0);
  void beginLayer(float opacity,
                  CompositeOperator,
                  const FloatRect* = 0,
                  ColorFilterObsolete = ColorFilterNone,
                  sk_sp<SkImageFilter> = 0);
  void endLayer();

  bool hasShadow() const;
  void setShadow(const FloatSize& offset,
                 float blur,
                 const Color&,
                 DrawLooperBuilder::ShadowTransformMode =
                     DrawLooperBuilder::ShadowRespectsTransforms,
                 DrawLooperBuilder::ShadowAlphaMode =
                     DrawLooperBuilder::ShadowRespectsAlpha);
  void clearShadow() { clearDrawLooper(); }

  // It is assumed that this draw looper is used only for shadows
  // (i.e. a draw looper is set if and only if there is a shadow).
  // The builder passed into this method will be destroyed.
  void setDrawLooper(PassOwnPtr<DrawLooperBuilder>);
  void clearDrawLooper();

  enum Edge {
    NoEdge = 0,
    TopEdge = 1 << 1,
    RightEdge = 1 << 2,
    BottomEdge = 1 << 3,
    LeftEdge = 1 << 4
  };
  typedef unsigned Edges;
  void drawInnerShadow(const RoundedRect&,
                       const Color& shadowColor,
                       const IntSize shadowOffset,
                       int shadowBlur,
                       int shadowSpread,
                       Edges clippedEdges = NoEdge);

  // This clip function is used only by <canvas> code. It allows
  // implementations to handle clipping on the canvas differently since
  // the discipline is different.
  void canvasClip(const Path&, WindRule = RULE_EVENODD);
  void clipOut(const Path&);

  // ---------- Transformation methods -----------------
  // Note that the getCTM method returns only the current transform from Blink's
  // perspective, which is not the final transform used to place content on
  // screen. It cannot be relied upon for testing where a point will appear on
  // screen or how large it will be.
  AffineTransform getCTM() const;
  void concatCTM(const AffineTransform& affine) {
    concat(affineTransformToSkMatrix(affine));
  }
  void setCTM(const AffineTransform& affine) {
    setMatrix(affineTransformToSkMatrix(affine));
  }
  void setMatrix(const SkMatrix&);

  void scale(float x, float y);
  void rotate(float angleInRadians);
  void translate(float x, float y);

  // This function applies the device scale factor to the context, making the
  // context capable of acting as a base-level context for a HiDPI environment.
  void applyDeviceScaleFactor(float deviceScaleFactor) {
    scale(deviceScaleFactor, deviceScaleFactor);
  }
  // ---------- End transformation methods -----------------

  static void adjustLineToPixelBoundaries(FloatPoint& p1,
                                          FloatPoint& p2,
                                          float strokeWidth,
                                          StrokeStyle);

  void preparePaintForDrawRectToRect(SkPaint*,
                                     const SkRect& srcRect,
                                     const SkRect& destRect,
                                     CompositeOperator,
                                     WebBlendMode,
                                     bool isLazyDecoded = false,
                                     bool isDataComplete = true) const;

  static int focusRingOutsetExtent(int offset, int width) {
    return focusRingOutset(offset) + (focusRingWidth(width) + 1) / 2;
  }

 private:
  const GraphicsContextState* immutableState() const { return m_paintState; }

  GraphicsContextState* mutableState() {
    realizePaintSave();
    return m_paintState;
  }

  static void setPathFromConvexPoints(SkPath*, size_t, const FloatPoint*);
  static void setRadii(SkVector*, IntSize, IntSize, IntSize, IntSize);

  static inline int focusRingOutset(int offset) { return 0; }
  static inline int focusRingWidth(int width) { return 1; }
  static SkPMColor lineColors(int);
  static SkPMColor antiColors1(int);
  static SkPMColor antiColors2(int);
  static void draw1xMarker(SkBitmap*, int);
  static void draw2xMarker(SkBitmap*, int);

  // Helpers for drawing a focus ring (drawFocusRing)
  float prepareFocusRingPaint(SkPaint&, const Color&, int width) const;
  void drawFocusRingPath(const SkPath&, const Color&, int width);
  void drawFocusRingRect(const SkRect&, const Color&, int width);

  // SkCanvas wrappers.
  void clipPath(const SkPath&,
                AntiAliasingMode = NotAntiAliased,
                SkClipOp = SkClipOp::kIntersect);
  void clipRRect(const SkRRect&,
                 AntiAliasingMode = NotAntiAliased,
                 SkClipOp = SkClipOp::kIntersect);
  void concat(const SkMatrix&);
  void drawRRect(const SkRRect&, const SkPaint&);

  // Apply deferred paint state saves
  void realizePaintSave() {
    if (contextDisabled())
      return;

    if (m_paintState->saveCount()) {
      m_paintState->decrementSaveCount();
      ++m_paintStateIndex;
      if (m_paintStateStack.size() == m_paintStateIndex) {
        m_paintStateStack.append(
            GraphicsContextState::createAndCopy(*m_paintState));
        m_paintState = m_paintStateStack[m_paintStateIndex].get();
      } else {
        GraphicsContextState* priorPaintState = m_paintState;
        m_paintState = m_paintStateStack[m_paintStateIndex].get();
        m_paintState->copy(*priorPaintState);
      }
    }
  }

  // Apply deferred canvas state saves
  void realizeCanvasSave() {
    if (!m_pendingCanvasSave || contextDisabled())
      return;

    m_canvas->save();
    m_pendingCanvasSave = false;
  }

  void didDrawTextInRect(const SkRect& textRect);

  void fillRectWithRoundedHole(const IntRect&,
                               const RoundedRect& roundedHoleRect,
                               const Color&);

  // null indicates painting is contextDisabled. Never delete this object.
  SkCanvas* m_canvas;

  // Paint states stack. Enables local drawing state change with
  // save()/restore() calls. This state controls the appearance of drawn
  // content. We do not delete from this stack to avoid memory churn.
  Vector<OwnPtr<GraphicsContextState>> m_paintStateStack;
  // Current index on the stack. May not be the last thing on the stack.
  unsigned m_paintStateIndex;
  // Raw pointer to the current state.
  GraphicsContextState* m_paintState;

  // Currently pending save flags for Skia Canvas state.
  // Canvas state includes the canavs, it's matrix and clips. Think of it as
  // _where_ the draw operations will happen.
  struct CanvasSaveState;
  Vector<CanvasSaveState> m_canvasStateStack;
  bool m_pendingCanvasSave;

#if ENABLE(ASSERT)
  unsigned m_layerCount;
  bool m_disableDestructionChecks;
#endif
  // Tracks the region painted opaque via the GraphicsContext.
  RegionTracker m_trackedRegion;

  // Tracks the region where text is painted via the GraphicsContext.
  SkRect m_textRegion;

  unsigned m_disabledState;

  float m_deviceScaleFactor;

  // Activation for the above region tracking features
  unsigned m_regionTrackingMode : 2;
  bool m_trackTextRegion : 1;

  bool m_accelerated : 1;
  bool m_isCertainlyOpaque : 1;
  bool m_antialiasHairlineImages : 1;
  bool m_shouldSmoothFonts : 1;
};

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_GRAPHICS_GRAPHICSCONTEXT_H_
