/*
 * Copyright (C) 2011 Andreas Kling (kling@webkit.org)
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
 *
 */

#include "config.h"
#include "core/css/CSSValue.h"

#include "core/css/CSSAspectRatioValue.h"
#include "core/css/CSSBorderImageSliceValue.h"
#include "core/css/CSSCalculationValue.h"
#include "core/css/CSSCanvasValue.h"
#include "core/css/CSSCrossfadeValue.h"
#include "core/css/CSSCursorImageValue.h"
#include "core/css/CSSFilterValue.h"
#include "core/css/CSSFontFaceSrcValue.h"
#include "core/css/CSSFontFeatureValue.h"
#include "core/css/CSSFontValue.h"
#include "core/css/CSSFunctionValue.h"
#include "core/css/CSSGradientValue.h"
#include "core/css/CSSGridLineNamesValue.h"
#include "core/css/CSSGridTemplateAreasValue.h"
#include "core/css/CSSImageSetValue.h"
#include "core/css/CSSImageValue.h"
#include "core/css/CSSInheritedValue.h"
#include "core/css/CSSInitialValue.h"
#include "core/css/CSSLineBoxContainValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSShadowValue.h"
#include "core/css/CSSTimingFunctionValue.h"
#include "core/css/CSSTransformValue.h"
#include "core/css/CSSUnicodeRangeValue.h"
#include "core/css/CSSValueList.h"

namespace blink {

struct SameSizeAsCSSValue : public RefCountedWillBeGarbageCollectedFinalized<SameSizeAsCSSValue>
// VC++ 2013 doesn't support EBCO (Empty Base Class Optimization), and having
// multiple empty base classes makes the size of CSSValue bloat (Note that both
// of GarbageCollectedFinalized and ScriptWrappableBase are empty classes).
// See the following article for details.
// http://social.msdn.microsoft.com/forums/vstudio/en-US/504c6598-6076-4acf-96b6-e6acb475d302/vc-multiple-inheritance-empty-base-classes-bloats-object-size
//
// FIXME: Remove this #if directive once VC++'s issue gets fixed.
// Note that we're going to split CSSValue class into two classes; CSSOMValue
// (assumed name) which derives ScriptWrappable and CSSValue (new one) which
// doesn't derive ScriptWrappable or ScriptWrappableBase. Then, we can safely
// remove this #if directive.
#if ENABLE(OILPAN) && COMPILER(MSVC)
    , public ScriptWrappableBase
#endif
{
    uint32_t bitfields;
};

COMPILE_ASSERT(sizeof(CSSValue) <= sizeof(SameSizeAsCSSValue), CSS_value_should_stay_small);

class TextCloneCSSValue : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<TextCloneCSSValue> create(ClassType classType, const String& text)
    {
        return adoptRefWillBeNoop(new TextCloneCSSValue(classType, text));
    }

    String cssText() const { return m_cssText; }

    void traceAfterDispatch(Visitor* visitor) { CSSValue::traceAfterDispatch(visitor); }

private:
    TextCloneCSSValue(ClassType classType, const String& text)
        : CSSValue(classType, /*isCSSOMSafe*/ true)
        , m_cssText(text)
    {
        m_isTextClone = true;
    }

    String m_cssText;
};

DEFINE_CSS_VALUE_TYPE_CASTS(TextCloneCSSValue, isTextCloneCSSValue());

bool CSSValue::isImplicitInitialValue() const
{
    return m_classType == InitialClass && toCSSInitialValue(this)->isImplicit();
}

CSSValue::Type CSSValue::cssValueType() const
{
    if (isInheritedValue())
        return CSS_INHERIT;
    if (isPrimitiveValue())
        return CSS_PRIMITIVE_VALUE;
    if (isValueList())
        return CSS_VALUE_LIST;
    if (isInitialValue())
        return CSS_INITIAL;
    return CSS_CUSTOM;
}

bool CSSValue::hasFailedOrCanceledSubresources() const
{
    // This should get called for internal instances only.
    ASSERT(!isCSSOMSafe());

    if (isValueList())
        return toCSSValueList(this)->hasFailedOrCanceledSubresources();
    if (classType() == FontFaceSrcClass)
        return toCSSFontFaceSrcValue(this)->hasFailedOrCanceledSubresources();
    if (classType() == ImageClass)
        return toCSSImageValue(this)->hasFailedOrCanceledSubresources();
    if (classType() == CrossfadeClass)
        return toCSSCrossfadeValue(this)->hasFailedOrCanceledSubresources();
    if (classType() == ImageSetClass)
        return toCSSImageSetValue(this)->hasFailedOrCanceledSubresources();

    return false;
}

template<class ChildClassType>
inline static bool compareCSSValues(const CSSValue& first, const CSSValue& second)
{
    return static_cast<const ChildClassType&>(first).equals(static_cast<const ChildClassType&>(second));
}

bool CSSValue::equals(const CSSValue& other) const
{
    if (m_isTextClone) {
        ASSERT(isCSSOMSafe());
        return toTextCloneCSSValue(this)->cssText() == other.cssText();
    }

    if (m_classType == other.m_classType) {
        switch (m_classType) {
        case AspectRatioClass:
            return compareCSSValues<CSSAspectRatioValue>(*this, other);
        case BorderImageSliceClass:
            return compareCSSValues<CSSBorderImageSliceValue>(*this, other);
        case CanvasClass:
            return compareCSSValues<CSSCanvasValue>(*this, other);
        case CursorImageClass:
            return compareCSSValues<CSSCursorImageValue>(*this, other);
        case FontClass:
            return compareCSSValues<CSSFontValue>(*this, other);
        case FontFaceSrcClass:
            return compareCSSValues<CSSFontFaceSrcValue>(*this, other);
        case FontFeatureClass:
            return compareCSSValues<CSSFontFeatureValue>(*this, other);
        case FunctionClass:
            return compareCSSValues<CSSFunctionValue>(*this, other);
        case LinearGradientClass:
            return compareCSSValues<CSSLinearGradientValue>(*this, other);
        case RadialGradientClass:
            return compareCSSValues<CSSRadialGradientValue>(*this, other);
        case CrossfadeClass:
            return compareCSSValues<CSSCrossfadeValue>(*this, other);
        case ImageClass:
            return compareCSSValues<CSSImageValue>(*this, other);
        case InheritedClass:
            return compareCSSValues<CSSInheritedValue>(*this, other);
        case InitialClass:
            return compareCSSValues<CSSInitialValue>(*this, other);
        case GridLineNamesClass:
            return compareCSSValues<CSSGridLineNamesValue>(*this, other);
        case GridTemplateAreasClass:
            return compareCSSValues<CSSGridTemplateAreasValue>(*this, other);
        case PrimitiveClass:
            return compareCSSValues<CSSPrimitiveValue>(*this, other);
        case ShadowClass:
            return compareCSSValues<CSSShadowValue>(*this, other);
        case CubicBezierTimingFunctionClass:
            return compareCSSValues<CSSCubicBezierTimingFunctionValue>(*this, other);
        case StepsTimingFunctionClass:
            return compareCSSValues<CSSStepsTimingFunctionValue>(*this, other);
        case UnicodeRangeClass:
            return compareCSSValues<CSSUnicodeRangeValue>(*this, other);
        case ValueListClass:
            return compareCSSValues<CSSValueList>(*this, other);
        case CSSTransformClass:
            return compareCSSValues<CSSTransformValue>(*this, other);
        case LineBoxContainClass:
            return compareCSSValues<CSSLineBoxContainValue>(*this, other);
        case CalculationClass:
            return compareCSSValues<CSSCalcValue>(*this, other);
        case ImageSetClass:
            return compareCSSValues<CSSImageSetValue>(*this, other);
        case CSSFilterClass:
            return compareCSSValues<CSSFilterValue>(*this, other);
        default:
            ASSERT_NOT_REACHED();
            return false;
        }
    } else if (m_classType == ValueListClass && other.m_classType != ValueListClass)
        return toCSSValueList(this)->equals(other);
    else if (m_classType != ValueListClass && other.m_classType == ValueListClass)
        return static_cast<const CSSValueList&>(other).equals(*this);
    return false;
}

String CSSValue::cssText() const
{
    if (m_isTextClone) {
         ASSERT(isCSSOMSafe());
        return toTextCloneCSSValue(this)->cssText();
    }
    ASSERT(!isCSSOMSafe() || isSubtypeExposedToCSSOM());

    switch (classType()) {
    case AspectRatioClass:
        return toCSSAspectRatioValue(this)->customCSSText();
    case BorderImageSliceClass:
        return toCSSBorderImageSliceValue(this)->customCSSText();
    case CanvasClass:
        return toCSSCanvasValue(this)->customCSSText();
    case CursorImageClass:
        return toCSSCursorImageValue(this)->customCSSText();
    case FontClass:
        return toCSSFontValue(this)->customCSSText();
    case FontFaceSrcClass:
        return toCSSFontFaceSrcValue(this)->customCSSText();
    case FontFeatureClass:
        return toCSSFontFeatureValue(this)->customCSSText();
    case FunctionClass:
        return toCSSFunctionValue(this)->customCSSText();
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->customCSSText();
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->customCSSText();
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->customCSSText();
    case ImageClass:
        return toCSSImageValue(this)->customCSSText();
    case InheritedClass:
        return toCSSInheritedValue(this)->customCSSText();
    case InitialClass:
        return toCSSInitialValue(this)->customCSSText();
    case GridLineNamesClass:
        return toCSSGridLineNamesValue(this)->customCSSText();
    case GridTemplateAreasClass:
        return toCSSGridTemplateAreasValue(this)->customCSSText();
    case PrimitiveClass:
        return toCSSPrimitiveValue(this)->customCSSText();
    case ShadowClass:
        return toCSSShadowValue(this)->customCSSText();
    case CubicBezierTimingFunctionClass:
        return toCSSCubicBezierTimingFunctionValue(this)->customCSSText();
    case StepsTimingFunctionClass:
        return toCSSStepsTimingFunctionValue(this)->customCSSText();
    case UnicodeRangeClass:
        return toCSSUnicodeRangeValue(this)->customCSSText();
    case ValueListClass:
        return toCSSValueList(this)->customCSSText();
    case CSSTransformClass:
        return toCSSTransformValue(this)->customCSSText();
    case LineBoxContainClass:
        return toCSSLineBoxContainValue(this)->customCSSText();
    case CalculationClass:
        return toCSSCalcValue(this)->customCSSText();
    case ImageSetClass:
        return toCSSImageSetValue(this)->customCSSText();
    case CSSFilterClass:
        return toCSSFilterValue(this)->customCSSText();
    }
    ASSERT_NOT_REACHED();
    return String();
}

void CSSValue::destroy()
{
    if (m_isTextClone) {
        ASSERT(isCSSOMSafe());
        delete toTextCloneCSSValue(this);
        return;
    }
    ASSERT(!isCSSOMSafe() || isSubtypeExposedToCSSOM());

    switch (classType()) {
    case AspectRatioClass:
        delete toCSSAspectRatioValue(this);
        return;
    case BorderImageSliceClass:
        delete toCSSBorderImageSliceValue(this);
        return;
    case CanvasClass:
        delete toCSSCanvasValue(this);
        return;
    case CursorImageClass:
        delete toCSSCursorImageValue(this);
        return;
    case FontClass:
        delete toCSSFontValue(this);
        return;
    case FontFaceSrcClass:
        delete toCSSFontFaceSrcValue(this);
        return;
    case FontFeatureClass:
        delete toCSSFontFeatureValue(this);
        return;
    case FunctionClass:
        delete toCSSFunctionValue(this);
        return;
    case LinearGradientClass:
        delete toCSSLinearGradientValue(this);
        return;
    case RadialGradientClass:
        delete toCSSRadialGradientValue(this);
        return;
    case CrossfadeClass:
        delete toCSSCrossfadeValue(this);
        return;
    case ImageClass:
        delete toCSSImageValue(this);
        return;
    case InheritedClass:
        delete toCSSInheritedValue(this);
        return;
    case InitialClass:
        delete toCSSInitialValue(this);
        return;
    case GridLineNamesClass:
        delete toCSSGridLineNamesValue(this);
        return;
    case GridTemplateAreasClass:
        delete toCSSGridTemplateAreasValue(this);
        return;
    case PrimitiveClass:
        delete toCSSPrimitiveValue(this);
        return;
    case ShadowClass:
        delete toCSSShadowValue(this);
        return;
    case CubicBezierTimingFunctionClass:
        delete toCSSCubicBezierTimingFunctionValue(this);
        return;
    case StepsTimingFunctionClass:
        delete toCSSStepsTimingFunctionValue(this);
        return;
    case UnicodeRangeClass:
        delete toCSSUnicodeRangeValue(this);
        return;
    case ValueListClass:
        delete toCSSValueList(this);
        return;
    case CSSTransformClass:
        delete toCSSTransformValue(this);
        return;
    case LineBoxContainClass:
        delete toCSSLineBoxContainValue(this);
        return;
    case CalculationClass:
        delete toCSSCalcValue(this);
        return;
    case ImageSetClass:
        delete toCSSImageSetValue(this);
        return;
    case CSSFilterClass:
        delete toCSSFilterValue(this);
        return;
    }
    ASSERT_NOT_REACHED();
}

void CSSValue::finalizeGarbageCollectedObject()
{
    if (m_isTextClone) {
        ASSERT(isCSSOMSafe());
        toTextCloneCSSValue(this)->~TextCloneCSSValue();
        return;
    }
    ASSERT(!isCSSOMSafe() || isSubtypeExposedToCSSOM());

    switch (classType()) {
    case AspectRatioClass:
        toCSSAspectRatioValue(this)->~CSSAspectRatioValue();
        return;
    case BorderImageSliceClass:
        toCSSBorderImageSliceValue(this)->~CSSBorderImageSliceValue();
        return;
    case CanvasClass:
        toCSSCanvasValue(this)->~CSSCanvasValue();
        return;
    case CursorImageClass:
        toCSSCursorImageValue(this)->~CSSCursorImageValue();
        return;
    case FontClass:
        toCSSFontValue(this)->~CSSFontValue();
        return;
    case FontFaceSrcClass:
        toCSSFontFaceSrcValue(this)->~CSSFontFaceSrcValue();
        return;
    case FontFeatureClass:
        toCSSFontFeatureValue(this)->~CSSFontFeatureValue();
        return;
    case FunctionClass:
        toCSSFunctionValue(this)->~CSSFunctionValue();
        return;
    case LinearGradientClass:
        toCSSLinearGradientValue(this)->~CSSLinearGradientValue();
        return;
    case RadialGradientClass:
        toCSSRadialGradientValue(this)->~CSSRadialGradientValue();
        return;
    case CrossfadeClass:
        toCSSCrossfadeValue(this)->~CSSCrossfadeValue();
        return;
    case ImageClass:
        toCSSImageValue(this)->~CSSImageValue();
        return;
    case InheritedClass:
        toCSSInheritedValue(this)->~CSSInheritedValue();
        return;
    case InitialClass:
        toCSSInitialValue(this)->~CSSInitialValue();
        return;
    case GridLineNamesClass:
        toCSSGridLineNamesValue(this)->~CSSGridLineNamesValue();
        return;
    case GridTemplateAreasClass:
        toCSSGridTemplateAreasValue(this)->~CSSGridTemplateAreasValue();
        return;
    case PrimitiveClass:
        toCSSPrimitiveValue(this)->~CSSPrimitiveValue();
        return;
    case ShadowClass:
        toCSSShadowValue(this)->~CSSShadowValue();
        return;
    case CubicBezierTimingFunctionClass:
        toCSSCubicBezierTimingFunctionValue(this)->~CSSCubicBezierTimingFunctionValue();
        return;
    case StepsTimingFunctionClass:
        toCSSStepsTimingFunctionValue(this)->~CSSStepsTimingFunctionValue();
        return;
    case UnicodeRangeClass:
        toCSSUnicodeRangeValue(this)->~CSSUnicodeRangeValue();
        return;
    case ValueListClass:
        toCSSValueList(this)->~CSSValueList();
        return;
    case CSSTransformClass:
        toCSSTransformValue(this)->~CSSTransformValue();
        return;
    case LineBoxContainClass:
        toCSSLineBoxContainValue(this)->~CSSLineBoxContainValue();
        return;
    case CalculationClass:
        toCSSCalcValue(this)->~CSSCalcValue();
        return;
    case ImageSetClass:
        toCSSImageSetValue(this)->~CSSImageSetValue();
        return;
    case CSSFilterClass:
        toCSSFilterValue(this)->~CSSFilterValue();
        return;
    }
    ASSERT_NOT_REACHED();
}

void CSSValue::trace(Visitor* visitor)
{
    if (m_isTextClone) {
        ASSERT(isCSSOMSafe());
        toTextCloneCSSValue(this)->traceAfterDispatch(visitor);
        return;
    }
    ASSERT(!isCSSOMSafe() || isSubtypeExposedToCSSOM());

    switch (classType()) {
    case AspectRatioClass:
        toCSSAspectRatioValue(this)->traceAfterDispatch(visitor);
        return;
    case BorderImageSliceClass:
        toCSSBorderImageSliceValue(this)->traceAfterDispatch(visitor);
        return;
    case CanvasClass:
        toCSSCanvasValue(this)->traceAfterDispatch(visitor);
        return;
    case CursorImageClass:
        toCSSCursorImageValue(this)->traceAfterDispatch(visitor);
        return;
    case FontClass:
        toCSSFontValue(this)->traceAfterDispatch(visitor);
        return;
    case FontFaceSrcClass:
        toCSSFontFaceSrcValue(this)->traceAfterDispatch(visitor);
        return;
    case FontFeatureClass:
        toCSSFontFeatureValue(this)->traceAfterDispatch(visitor);
        return;
    case FunctionClass:
        toCSSFunctionValue(this)->traceAfterDispatch(visitor);
        return;
    case LinearGradientClass:
        toCSSLinearGradientValue(this)->traceAfterDispatch(visitor);
        return;
    case RadialGradientClass:
        toCSSRadialGradientValue(this)->traceAfterDispatch(visitor);
        return;
    case CrossfadeClass:
        toCSSCrossfadeValue(this)->traceAfterDispatch(visitor);
        return;
    case ImageClass:
        toCSSImageValue(this)->traceAfterDispatch(visitor);
        return;
    case InheritedClass:
        toCSSInheritedValue(this)->traceAfterDispatch(visitor);
        return;
    case InitialClass:
        toCSSInitialValue(this)->traceAfterDispatch(visitor);
        return;
    case GridLineNamesClass:
        toCSSGridLineNamesValue(this)->traceAfterDispatch(visitor);
        return;
    case GridTemplateAreasClass:
        toCSSGridTemplateAreasValue(this)->traceAfterDispatch(visitor);
        return;
    case PrimitiveClass:
        toCSSPrimitiveValue(this)->traceAfterDispatch(visitor);
        return;
    case ShadowClass:
        toCSSShadowValue(this)->traceAfterDispatch(visitor);
        return;
    case CubicBezierTimingFunctionClass:
        toCSSCubicBezierTimingFunctionValue(this)->traceAfterDispatch(visitor);
        return;
    case StepsTimingFunctionClass:
        toCSSStepsTimingFunctionValue(this)->traceAfterDispatch(visitor);
        return;
    case UnicodeRangeClass:
        toCSSUnicodeRangeValue(this)->traceAfterDispatch(visitor);
        return;
    case ValueListClass:
        toCSSValueList(this)->traceAfterDispatch(visitor);
        return;
    case CSSTransformClass:
        toCSSTransformValue(this)->traceAfterDispatch(visitor);
        return;
    case LineBoxContainClass:
        toCSSLineBoxContainValue(this)->traceAfterDispatch(visitor);
        return;
    case CalculationClass:
        toCSSCalcValue(this)->traceAfterDispatch(visitor);
        return;
    case ImageSetClass:
        toCSSImageSetValue(this)->traceAfterDispatch(visitor);
        return;
    case CSSFilterClass:
        toCSSFilterValue(this)->traceAfterDispatch(visitor);
        return;
    }
    ASSERT_NOT_REACHED();
}

PassRefPtrWillBeRawPtr<CSSValue> CSSValue::cloneForCSSOM() const
{
    switch (classType()) {
    case PrimitiveClass:
        return toCSSPrimitiveValue(this)->cloneForCSSOM();
    case ValueListClass:
        return toCSSValueList(this)->cloneForCSSOM();
    case ImageClass:
    case CursorImageClass:
        return toCSSImageValue(this)->cloneForCSSOM();
    case CSSFilterClass:
        return toCSSFilterValue(this)->cloneForCSSOM();
    case CSSTransformClass:
        return toCSSTransformValue(this)->cloneForCSSOM();
    case ImageSetClass:
        return toCSSImageSetValue(this)->cloneForCSSOM();
    default:
        ASSERT(!isSubtypeExposedToCSSOM());
        return TextCloneCSSValue::create(classType(), cssText());
    }
}

}
