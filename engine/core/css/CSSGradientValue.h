/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSGRADIENTVALUE_H_
#define SKY_ENGINE_CORE_CSS_CSSGRADIENTVALUE_H_

#include "sky/engine/core/css/CSSImageGeneratorValue.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class FloatPoint;
class Gradient;
class TextLinkColors;

enum CSSGradientType {
    CSSDeprecatedLinearGradient,
    CSSDeprecatedRadialGradient,
    CSSPrefixedLinearGradient,
    CSSPrefixedRadialGradient,
    CSSLinearGradient,
    CSSRadialGradient
};
enum CSSGradientRepeat { NonRepeating, Repeating };

struct CSSGradientColorStop {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    CSSGradientColorStop() : m_colorIsDerivedFromElement(false) { };
    RefPtr<CSSPrimitiveValue> m_position; // percentage or length
    RefPtr<CSSPrimitiveValue> m_color;
    Color m_resolvedColor;
    bool m_colorIsDerivedFromElement;
    bool operator==(const CSSGradientColorStop& other) const
    {
        return compareCSSValuePtr(m_color, other.m_color)
            && compareCSSValuePtr(m_position, other.m_position);
    }
};

} // namespace blink


// We have to declare the VectorTraits specialization before CSSGradientValue
// declares its inline capacity vector below.
WTF_ALLOW_MOVE_AND_INIT_WITH_MEM_FUNCTIONS(blink::CSSGradientColorStop);

namespace blink {

class CSSGradientValue : public CSSImageGeneratorValue {
public:
    PassRefPtr<Image> image(RenderObject*, const IntSize&);

    void setFirstX(PassRefPtr<CSSPrimitiveValue> val) { m_firstX = val; }
    void setFirstY(PassRefPtr<CSSPrimitiveValue> val) { m_firstY = val; }
    void setSecondX(PassRefPtr<CSSPrimitiveValue> val) { m_secondX = val; }
    void setSecondY(PassRefPtr<CSSPrimitiveValue> val) { m_secondY = val; }

    void addStop(const CSSGradientColorStop& stop) { m_stops.append(stop); }

    unsigned stopCount() const { return m_stops.size(); }

    void sortStopsIfNeeded();

    bool isRepeating() const { return m_repeating; }

    CSSGradientType gradientType() const { return m_gradientType; }

    bool isFixedSize() const { return false; }
    IntSize fixedSize(const RenderObject*) const { return IntSize(); }

    bool isPending() const { return false; }
    bool knownToBeOpaque(const RenderObject*) const;

    PassRefPtr<CSSGradientValue> gradientWithStylesResolved(const TextLinkColors&, Color currentColor);

protected:
    CSSGradientValue(ClassType classType, CSSGradientRepeat repeat, CSSGradientType gradientType)
        : CSSImageGeneratorValue(classType)
        , m_stopsSorted(false)
        , m_gradientType(gradientType)
        , m_repeating(repeat == Repeating)
    {
    }

    CSSGradientValue(const CSSGradientValue& other, ClassType classType, CSSGradientType gradientType)
        : CSSImageGeneratorValue(classType)
        , m_firstX(other.m_firstX)
        , m_firstY(other.m_firstY)
        , m_secondX(other.m_secondX)
        , m_secondY(other.m_secondY)
        , m_stops(other.m_stops)
        , m_stopsSorted(other.m_stopsSorted)
        , m_gradientType(gradientType)
        , m_repeating(other.isRepeating() ? Repeating : NonRepeating)
    {
    }

    void addStops(Gradient*, const CSSToLengthConversionData&, float maxLengthForRepeat = 0);

    // Resolve points/radii to front end values.
    FloatPoint computeEndPoint(CSSPrimitiveValue*, CSSPrimitiveValue*, const CSSToLengthConversionData&, const IntSize&);

    bool isCacheable() const;

    // Points. Some of these may be null.
    RefPtr<CSSPrimitiveValue> m_firstX;
    RefPtr<CSSPrimitiveValue> m_firstY;

    RefPtr<CSSPrimitiveValue> m_secondX;
    RefPtr<CSSPrimitiveValue> m_secondY;

    // Stops
    Vector<CSSGradientColorStop, 2> m_stops;
    bool m_stopsSorted;
    CSSGradientType m_gradientType;
    bool m_repeating;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSGradientValue, isGradientValue());

class CSSLinearGradientValue : public CSSGradientValue {
public:

    static PassRefPtr<CSSLinearGradientValue> create(CSSGradientRepeat repeat, CSSGradientType gradientType = CSSLinearGradient)
    {
        return adoptRef(new CSSLinearGradientValue(repeat, gradientType));
    }

    void setAngle(PassRefPtr<CSSPrimitiveValue> val) { m_angle = val; }

    String customCSSText() const;

    // Create the gradient for a given size.
    PassRefPtr<Gradient> createGradient(const CSSToLengthConversionData&, const IntSize&);

    PassRefPtr<CSSLinearGradientValue> clone() const
    {
        return adoptRef(new CSSLinearGradientValue(*this));
    }

    bool equals(const CSSLinearGradientValue&) const;

private:
    CSSLinearGradientValue(CSSGradientRepeat repeat, CSSGradientType gradientType = CSSLinearGradient)
        : CSSGradientValue(LinearGradientClass, repeat, gradientType)
    {
    }

    explicit CSSLinearGradientValue(const CSSLinearGradientValue& other)
        : CSSGradientValue(other, LinearGradientClass, other.gradientType())
        , m_angle(other.m_angle)
    {
    }

    RefPtr<CSSPrimitiveValue> m_angle; // may be null.
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSLinearGradientValue, isLinearGradientValue());

class CSSRadialGradientValue : public CSSGradientValue {
public:
    static PassRefPtr<CSSRadialGradientValue> create(CSSGradientRepeat repeat, CSSGradientType gradientType = CSSRadialGradient)
    {
        return adoptRef(new CSSRadialGradientValue(repeat, gradientType));
    }

    PassRefPtr<CSSRadialGradientValue> clone() const
    {
        return adoptRef(new CSSRadialGradientValue(*this));
    }

    String customCSSText() const;

    void setFirstRadius(PassRefPtr<CSSPrimitiveValue> val) { m_firstRadius = val; }
    void setSecondRadius(PassRefPtr<CSSPrimitiveValue> val) { m_secondRadius = val; }

    void setShape(PassRefPtr<CSSPrimitiveValue> val) { m_shape = val; }
    void setSizingBehavior(PassRefPtr<CSSPrimitiveValue> val) { m_sizingBehavior = val; }

    void setEndHorizontalSize(PassRefPtr<CSSPrimitiveValue> val) { m_endHorizontalSize = val; }
    void setEndVerticalSize(PassRefPtr<CSSPrimitiveValue> val) { m_endVerticalSize = val; }

    // Create the gradient for a given size.
    PassRefPtr<Gradient> createGradient(const CSSToLengthConversionData&, const IntSize&);

    bool equals(const CSSRadialGradientValue&) const;

private:
    CSSRadialGradientValue(CSSGradientRepeat repeat, CSSGradientType gradientType = CSSRadialGradient)
        : CSSGradientValue(RadialGradientClass, repeat, gradientType)
    {
    }

    explicit CSSRadialGradientValue(const CSSRadialGradientValue& other)
        : CSSGradientValue(other, RadialGradientClass, other.gradientType())
        , m_firstRadius(other.m_firstRadius)
        , m_secondRadius(other.m_secondRadius)
        , m_shape(other.m_shape)
        , m_sizingBehavior(other.m_sizingBehavior)
        , m_endHorizontalSize(other.m_endHorizontalSize)
        , m_endVerticalSize(other.m_endVerticalSize)
    {
    }


    // Resolve points/radii to front end values.
    float resolveRadius(CSSPrimitiveValue*, const CSSToLengthConversionData&, float* widthOrHeight = 0);

    // These may be null for non-deprecated gradients.
    RefPtr<CSSPrimitiveValue> m_firstRadius;
    RefPtr<CSSPrimitiveValue> m_secondRadius;

    // The below are only used for non-deprecated gradients. Any of them may be null.
    RefPtr<CSSPrimitiveValue> m_shape;
    RefPtr<CSSPrimitiveValue> m_sizingBehavior;

    RefPtr<CSSPrimitiveValue> m_endHorizontalSize;
    RefPtr<CSSPrimitiveValue> m_endVerticalSize;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSRadialGradientValue, isRadialGradientValue());

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSGRADIENTVALUE_H_
