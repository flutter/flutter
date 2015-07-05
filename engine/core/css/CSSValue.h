/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef SKY_ENGINE_CORE_CSS_CSSVALUE_H_
#define SKY_ENGINE_CORE_CSS_CSSVALUE_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

class ExceptionState;
class StyleSheetContents;

enum CSSTextFormattingFlags { QuoteCSSStringIfNeeded, AlwaysQuoteCSSString };

// FIXME: The current CSSValue and subclasses should be turned into internal types (StyleValue).
// The few subtypes that are actually exposed in CSSOM can be seen in the cloneForCSSOM() function.
// They should be handled by separate wrapper classes.

// Please don't expose more CSSValue types to the web.
class CSSValue : public RefCounted<CSSValue> {
public:
    enum Type {
        CSS_INHERIT = 0,
        CSS_PRIMITIVE_VALUE = 1,
        CSS_VALUE_LIST = 2,
        CSS_CUSTOM = 3,
        CSS_INITIAL = 4

    };

    // Override RefCounted's deref() to ensure operator delete is called on
    // the appropriate subclass type.
    // When oilpan is enabled the finalize method is called by the garbage
    // collector and not immediately when deref reached zero.
#if !ENABLE(OILPAN)
    void deref()
    {
        if (derefBase())
            destroy();
    }
#endif // !ENABLE(OILPAN)

    Type cssValueType() const;

    String cssText() const;
    void setCSSText(const String&, ExceptionState&) { } // FIXME: Not implemented.

    bool isPrimitiveValue() const { return m_classType == PrimitiveClass; }
    bool isValueList() const { return m_classType >= ValueListClass; }

    bool isBaseValueList() const { return m_classType == ValueListClass; }

    bool isAspectRatioValue() const { return m_classType == AspectRatioClass; }
    bool isBorderImageSliceValue() const { return m_classType == BorderImageSliceClass; }
    bool isFontFeatureValue() const { return m_classType == FontFeatureClass; }
    bool isFontValue() const { return m_classType == FontClass; }
    bool isFontFaceSrcValue() const { return m_classType == FontFaceSrcClass; }
    bool isFunctionValue() const { return m_classType == FunctionClass; }
    bool isImageGeneratorValue() const { return m_classType >= LinearGradientClass && m_classType <= RadialGradientClass; }
    bool isGradientValue() const { return m_classType >= LinearGradientClass && m_classType <= RadialGradientClass; }
    bool isImplicitInitialValue() const;
    bool isInheritedValue() const { return m_classType == InheritedClass; }
    bool isInitialValue() const { return m_classType == InitialClass; }
    bool isLinearGradientValue() const { return m_classType == LinearGradientClass; }
    bool isRadialGradientValue() const { return m_classType == RadialGradientClass; }
    bool isShadowValue() const { return m_classType == ShadowClass; }
    bool isTextCloneCSSValue() const { return m_isTextClone; }
    bool isCubicBezierTimingFunctionValue() const { return m_classType == CubicBezierTimingFunctionClass; }
    bool isStepsTimingFunctionValue() const { return m_classType == StepsTimingFunctionClass; }
    bool isTransformValue() const { return m_classType == CSSTransformClass; }
    bool isLineBoxContainValue() const { return m_classType == LineBoxContainClass; }
    bool isCalcValue() const {return m_classType == CalculationClass; }
    bool isFilterValue() const { return m_classType == CSSFilterClass; }
    bool isUnicodeRangeValue() const { return m_classType == UnicodeRangeClass; }

    bool isCSSOMSafe() const { return m_isCSSOMSafe; }
    bool isSubtypeExposedToCSSOM() const
    {
        return isPrimitiveValue() || isValueList();
    }

    PassRefPtr<CSSValue> cloneForCSSOM() const;

    bool equals(const CSSValue&) const;

protected:

    static const size_t ClassTypeBits = 6;
    enum ClassType {
        PrimitiveClass,

        // Image generator classes.
        LinearGradientClass,
        RadialGradientClass,

        // Timing function classes.
        CubicBezierTimingFunctionClass,
        StepsTimingFunctionClass,

        // Other class types.
        AspectRatioClass,
        BorderImageSliceClass,
        FontFeatureClass,
        FontClass,
        FontFaceSrcClass,
        FunctionClass,

        InheritedClass,
        InitialClass,

        ShadowClass,
        UnicodeRangeClass,
        LineBoxContainClass,
        CalculationClass,

        // List class types must appear after ValueListClass.
        ValueListClass,
        CSSFilterClass,
        CSSTransformClass,
        // Do not append non-list class types here.
    };

    static const size_t ValueListSeparatorBits = 2;
    enum ValueListSeparator {
        SpaceSeparator,
        CommaSeparator,
        SlashSeparator
    };

    ClassType classType() const { return static_cast<ClassType>(m_classType); }

    explicit CSSValue(ClassType classType, bool isCSSOMSafe = false)
        : m_isCSSOMSafe(isCSSOMSafe)
        , m_isTextClone(false)
        , m_primitiveUnitType(0)
        , m_hasCachedCSSText(false)
        , m_isQuirkValue(false)
        , m_valueListSeparator(SpaceSeparator)
        , m_classType(classType)
    {
    }

    // NOTE: This class is non-virtual for memory and performance reasons.
    // Don't go making it virtual again unless you know exactly what you're doing!

    ~CSSValue() { }

private:
    void destroy();

protected:
    unsigned m_isCSSOMSafe : 1;
    unsigned m_isTextClone : 1;
    // The bits in this section are only used by specific subclasses but kept here
    // to maximize struct packing.

    // CSSPrimitiveValue bits:
    unsigned m_primitiveUnitType : 7; // CSSPrimitiveValue::UnitType
    mutable unsigned m_hasCachedCSSText : 1;
    unsigned m_isQuirkValue : 1;

    unsigned m_valueListSeparator : ValueListSeparatorBits;

private:
    unsigned m_classType : ClassTypeBits; // ClassType
};

template<typename CSSValueType, size_t inlineCapacity>
inline bool compareCSSValueVector(const Vector<RefPtr<CSSValueType>, inlineCapacity>& firstVector, const Vector<RefPtr<CSSValueType>, inlineCapacity>& secondVector)
{
    size_t size = firstVector.size();
    if (size != secondVector.size())
        return false;

    for (size_t i = 0; i < size; i++) {
        const RefPtr<CSSValueType>& firstPtr = firstVector[i];
        const RefPtr<CSSValueType>& secondPtr = secondVector[i];
        if (firstPtr == secondPtr || (firstPtr && secondPtr && firstPtr->equals(*secondPtr)))
            continue;
        return false;
    }
    return true;
}

template<typename CSSValueType>
inline bool compareCSSValuePtr(const RefPtr<CSSValueType>& first, const RefPtr<CSSValueType>& second)
{
    return first ? second && first->equals(*second) : !second;
}

template<typename CSSValueType>
inline bool compareCSSValuePtr(const RawPtr<CSSValueType>& first, const RawPtr<CSSValueType>& second)
{
    return first ? second && first->equals(*second) : !second;
}

#define DEFINE_CSS_VALUE_TYPE_CASTS(thisType, predicate) \
    DEFINE_TYPE_CASTS(thisType, CSSValue, value, value->predicate, value.predicate)

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSVALUE_H_
