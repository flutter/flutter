/*
 * Copyright (C) 2006, 2007, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
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

#ifndef CanvasRenderingContext2D_h
#define CanvasRenderingContext2D_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/css/CSSFontSelectorClient.h"
#include "core/html/canvas/Canvas2DContextAttributes.h"
#include "core/html/canvas/CanvasPathMethods.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/canvas/HitRegion.h"
#include "platform/fonts/Font.h"
#include "platform/graphics/Color.h"
#include "platform/geometry/FloatSize.h"
#include "platform/graphics/GraphicsTypes.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/graphics/Path.h"
#include "platform/transforms/AffineTransform.h"
#include "wtf/HashMap.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

namespace blink { class WebLayer; }

namespace blink {

class CanvasImageSource;
class CanvasGradient;
class CanvasPattern;
class CanvasStyle;
class Path2D;
class Element;
class ExceptionState;
class FloatRect;
class GraphicsContext;
class HTMLCanvasElement;
class HTMLImageElement;
class ImageBitmap;
class ImageData;
class TextMetrics;

typedef HashMap<String, RefPtr<MutableStylePropertySet> > MutableStylePropertyMap;

class CanvasRenderingContext2D final: public CanvasRenderingContext, public ScriptWrappable, public CanvasPathMethods {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassOwnPtr<CanvasRenderingContext2D> create(HTMLCanvasElement* canvas, const Canvas2DContextAttributes* attrs)
    {
        return adoptPtr(new CanvasRenderingContext2D(canvas, attrs));
    }
    virtual ~CanvasRenderingContext2D();

    CanvasStyle* strokeStyle() const;
    void setStrokeStyle(PassRefPtr<CanvasStyle>);

    CanvasStyle* fillStyle() const;
    void setFillStyle(PassRefPtr<CanvasStyle>);

    float lineWidth() const;
    void setLineWidth(float);

    String lineCap() const;
    void setLineCap(const String&);

    String lineJoin() const;
    void setLineJoin(const String&);

    float miterLimit() const;
    void setMiterLimit(float);

    const Vector<float>& getLineDash() const;
    void setLineDash(const Vector<float>&);

    float lineDashOffset() const;
    void setLineDashOffset(float);

    float shadowOffsetX() const;
    void setShadowOffsetX(float);

    float shadowOffsetY() const;
    void setShadowOffsetY(float);

    float shadowBlur() const;
    void setShadowBlur(float);

    String shadowColor() const;
    void setShadowColor(const String&);

    float globalAlpha() const;
    void setGlobalAlpha(float);

    bool isContextLost() const;

    String globalCompositeOperation() const;
    void setGlobalCompositeOperation(const String&);

    void save() { ++m_stateStack.last()->m_unrealizedSaveCount; }
    void restore();

    void scale(float sx, float sy);
    void rotate(float angleInRadians);
    void translate(float tx, float ty);
    void transform(float m11, float m12, float m21, float m22, float dx, float dy);
    void setTransform(float m11, float m12, float m21, float m22, float dx, float dy);
    void resetTransform();

    void setStrokeColor(const String& color);
    void setStrokeColor(float grayLevel);
    void setStrokeColor(const String& color, float alpha);
    void setStrokeColor(float grayLevel, float alpha);
    void setStrokeColor(float r, float g, float b, float a);
    void setStrokeColor(float c, float m, float y, float k, float a);

    void setFillColor(const String& color);
    void setFillColor(float grayLevel);
    void setFillColor(const String& color, float alpha);
    void setFillColor(float grayLevel, float alpha);
    void setFillColor(float r, float g, float b, float a);
    void setFillColor(float c, float m, float y, float k, float a);

    void beginPath();

    void fill(const String& winding = "nonzero");
    void fill(Path2D*, const String& winding = "nonzero");
    void stroke();
    void stroke(Path2D*);
    void clip(const String& winding = "nonzero");
    void clip(Path2D*, const String& winding = "nonzero");

    bool isPointInPath(const float x, const float y, const String& winding = "nonzero");
    bool isPointInPath(Path2D*, const float x, const float y, const String& winding = "nonzero");
    bool isPointInStroke(const float x, const float y);
    bool isPointInStroke(Path2D*, const float x, const float y);

    void scrollPathIntoView();
    void scrollPathIntoView(Path2D*);

    void clearRect(float x, float y, float width, float height);
    void fillRect(float x, float y, float width, float height);
    void strokeRect(float x, float y, float width, float height);

    void setShadow(float width, float height, float blur);
    void setShadow(float width, float height, float blur, const String& color);
    void setShadow(float width, float height, float blur, float grayLevel);
    void setShadow(float width, float height, float blur, const String& color, float alpha);
    void setShadow(float width, float height, float blur, float grayLevel, float alpha);
    void setShadow(float width, float height, float blur, float r, float g, float b, float a);
    void setShadow(float width, float height, float blur, float c, float m, float y, float k, float a);

    void clearShadow();

    void drawImage(CanvasImageSource*, float x, float y, ExceptionState&);
    void drawImage(CanvasImageSource*, float x, float y, float width, float height, ExceptionState&);
    void drawImage(CanvasImageSource*, float sx, float sy, float sw, float sh, float dx, float dy, float dw, float dh, ExceptionState&);

    void drawImageFromRect(HTMLImageElement*, float sx = 0, float sy = 0, float sw = 0, float sh = 0,
                           float dx = 0, float dy = 0, float dw = 0, float dh = 0, const String& compositeOperation = emptyString());

    void setAlpha(float);

    void setCompositeOperation(const String&);

    PassRefPtr<CanvasGradient> createLinearGradient(float x0, float y0, float x1, float y1);
    PassRefPtr<CanvasGradient> createRadialGradient(float x0, float y0, float r0, float x1, float y1, float r1, ExceptionState&);
    PassRefPtr<CanvasPattern> createPattern(CanvasImageSource*, const String& repetitionType, ExceptionState&);

    PassRefPtr<ImageData> createImageData(PassRefPtr<ImageData>) const;
    PassRefPtr<ImageData> createImageData(float width, float height, ExceptionState&) const;
    PassRefPtr<ImageData> getImageData(float sx, float sy, float sw, float sh, ExceptionState&) const;
    void putImageData(ImageData*, float dx, float dy);
    void putImageData(ImageData*, float dx, float dy, float dirtyX, float dirtyY, float dirtyWidth, float dirtyHeight);

    void reset();

    String font() const;
    void setFont(const String&);

    String textAlign() const;
    void setTextAlign(const String&);

    String textBaseline() const;
    void setTextBaseline(const String&);

    String direction() const;
    void setDirection(const String&);

    void fillText(const String& text, float x, float y);
    void fillText(const String& text, float x, float y, float maxWidth);
    void strokeText(const String& text, float x, float y);
    void strokeText(const String& text, float x, float y, float maxWidth);
    PassRefPtr<TextMetrics> measureText(const String& text);

    LineCap getLineCap() const { return state().m_lineCap; }
    LineJoin getLineJoin() const { return state().m_lineJoin; }

    bool imageSmoothingEnabled() const;
    void setImageSmoothingEnabled(bool);

    PassRefPtr<Canvas2DContextAttributes> getContextAttributes() const;

    void drawFocusIfNeeded(Element*);
    void drawFocusIfNeeded(Path2D*, Element*);

    void addHitRegion(ExceptionState&);
    void addHitRegion(const Dictionary&, ExceptionState&);
    void removeHitRegion(const String& id);
    void clearHitRegions();
    HitRegion* hitRegionAtPoint(const LayoutPoint&);
    unsigned hitRegionsCount() const;

    void loseContext();
    void restoreContext();

    virtual void trace(Visitor*) override;

private:
    enum Direction {
        DirectionInherit,
        DirectionRTL,
        DirectionLTR
    };

    class State final : public CSSFontSelectorClient {
    public:
        State();
        virtual ~State();

        State(const State&);
        State& operator=(const State&);

        // CSSFontSelectorClient implementation
        virtual void fontsNeedUpdate(CSSFontSelector*) override;

        virtual void trace(Visitor*) override;

        unsigned m_unrealizedSaveCount;

        String m_unparsedStrokeColor;
        String m_unparsedFillColor;
        RefPtr<CanvasStyle> m_strokeStyle;
        RefPtr<CanvasStyle> m_fillStyle;
        float m_lineWidth;
        LineCap m_lineCap;
        LineJoin m_lineJoin;
        float m_miterLimit;
        FloatSize m_shadowOffset;
        float m_shadowBlur;
        RGBA32 m_shadowColor;
        float m_globalAlpha;
        CompositeOperator m_globalComposite;
        blink::WebBlendMode m_globalBlend;
        AffineTransform m_transform;
        bool m_invertibleCTM;
        Vector<float> m_lineDash;
        float m_lineDashOffset;
        bool m_imageSmoothingEnabled;

        // Text state.
        TextAlign m_textAlign;
        TextBaseline m_textBaseline;
        Direction m_direction;

        String m_unparsedFont;
        Font m_font;
        bool m_realizedFont;

        bool m_hasClip;
    };

    CanvasRenderingContext2D(HTMLCanvasElement*, const Canvas2DContextAttributes* attrs);

    State& modifiableState() { ASSERT(!state().m_unrealizedSaveCount); return *m_stateStack.last(); }
    const State& state() const { return *m_stateStack.last(); }

    void applyLineDash() const;
    void setShadow(const FloatSize& offset, float blur, RGBA32 color);
    void applyShadow();
    bool shouldDrawShadows() const;

    void dispatchContextLostEvent(Timer<CanvasRenderingContext2D>*);
    void dispatchContextRestoredEvent(Timer<CanvasRenderingContext2D>*);
    void tryRestoreContextEvent(Timer<CanvasRenderingContext2D>*);

    bool computeDirtyRect(const FloatRect& localBounds, FloatRect*);
    bool computeDirtyRect(const FloatRect& localBounds, const FloatRect& transformedClipBounds, FloatRect*);
    void didDraw(const FloatRect&);

    GraphicsContext* drawingContext() const;

    void unwindStateStack();
    void realizeSaves(GraphicsContext*);

    void applyStrokePattern();
    void applyFillPattern();

    void drawImageInternal(CanvasImageSource*, float sx, float sy, float sw, float sh, float dx, float dy, float dw, float dh, ExceptionState&, CompositeOperator, blink::WebBlendMode, GraphicsContext* = 0);

    void fillInternal(const Path&, const String& windingRuleString);
    void strokeInternal(const Path&);
    void clipInternal(const Path&, const String& windingRuleString);

    bool isPointInPathInternal(const Path&, const float x, const float y, const String& windingRuleString);
    bool isPointInStrokeInternal(const Path&, const float x, const float y);

    void scrollPathIntoViewInternal(const Path&);

    void drawTextInternal(const String& text, float x, float y, bool fill, float maxWidth = 0, bool useMaxWidth = false);

    const Font& accessFont();
    int getFontBaseline(const FontMetrics&) const;

    void clearCanvas();
    bool rectContainsTransformedRect(const FloatRect&, const FloatRect&) const;

    void inflateStrokeRect(FloatRect&) const;

    template<class T> void fullCanvasCompositedFill(const T&);
    template<class T> void fullCanvasCompositedStroke(const T&);
    template<class T> void fullCanvasCompositedDrawImage(T*, const FloatRect&, const FloatRect&, CompositeOperator);

    void drawFocusIfNeededInternal(const Path&, Element*);
    bool focusRingCallIsValid(const Path&, Element*);
    void drawFocusRing(const Path&);

    void addHitRegionInternal(const HitRegionOptions&, ExceptionState&);
    bool hasClip() { return state().m_hasClip; }

    void validateStateStack();

    virtual bool is2d() const override { return true; }
    virtual bool isAccelerated() const override;
    virtual bool hasAlpha() const override { return m_hasAlpha; }
    virtual void setIsHidden(bool) override;

    virtual bool isTransformInvertible() const override { return state().m_invertibleCTM; }

    virtual blink::WebLayer* platformLayer() const override;
    TextDirection toTextDirection(Direction, RenderStyle** computedStyle = nullptr) const;

    Vector<OwnPtr<State> > m_stateStack;
    OwnPtr<HitRegionManager> m_hitRegionManager;
    bool m_hasAlpha;
    bool m_isContextLost;
    bool m_contextRestorable;
    Canvas2DContextStorage m_storageMode;
    MutableStylePropertyMap m_fetchedFonts;
    unsigned m_tryRestoreContextAttemptCount;
    Timer<CanvasRenderingContext2D> m_dispatchContextLostEventTimer;
    Timer<CanvasRenderingContext2D> m_dispatchContextRestoredEventTimer;
    Timer<CanvasRenderingContext2D> m_tryRestoreContextEventTimer;
};

DEFINE_TYPE_CASTS(CanvasRenderingContext2D, CanvasRenderingContext, context, context->is2d(), context.is2d());

} // namespace blink

#endif // CanvasRenderingContext2D_h
