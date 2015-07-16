/*
 * Copyright (C) 2007 Alexey Proskuryakov <ap@nypop.com>.
 * Copyright (C) 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2009 Jeff Schiller <codedread@gmail.com>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_CSS_CSSPRIMITIVEVALUEMAPPINGS_H_
#define SKY_ENGINE_CORE_CSS_CSSPRIMITIVEVALUEMAPPINGS_H_

#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/core/css/CSSCalculationValue.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/css/CSSPrimitiveValueMappings.h"
#include "sky/engine/core/css/CSSToLengthConversionData.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "sky/engine/platform/Length.h"
#include "sky/engine/platform/fonts/FontDescription.h"
#include "sky/engine/platform/fonts/FontSmoothingMode.h"
#include "sky/engine/platform/fonts/TextRenderingMode.h"
#include "sky/engine/platform/graphics/GraphicsTypes.h"
#include "sky/engine/platform/graphics/Path.h"
#include "sky/engine/platform/text/TextDirection.h"
#include "sky/engine/platform/text/UnicodeBidi.h"
#include "sky/engine/wtf/MathExtras.h"

namespace blink {

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(short i)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_NUMBER;
    m_value.num = static_cast<double>(i);
}

template<> inline CSSPrimitiveValue::operator short() const
{
    ASSERT(isNumber());
    return clampTo<short>(getDoubleValue());
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(unsigned short i)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_NUMBER;
    m_value.num = static_cast<double>(i);
}

template<> inline CSSPrimitiveValue::operator unsigned short() const
{
    ASSERT(isNumber());
    return clampTo<unsigned short>(getDoubleValue());
}

template<> inline CSSPrimitiveValue::operator int() const
{
    ASSERT(isNumber());
    return clampTo<int>(getDoubleValue());
}

template<> inline CSSPrimitiveValue::operator unsigned() const
{
    ASSERT(isNumber());
    return clampTo<unsigned>(getDoubleValue());
}


template<> inline CSSPrimitiveValue::CSSPrimitiveValue(float i)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_NUMBER;
    m_value.num = static_cast<double>(i);
}

template<> inline CSSPrimitiveValue::operator float() const
{
    ASSERT(isNumber());
    return clampTo<float>(getDoubleValue());
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(ColumnFill columnFill)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (columnFill) {
    case ColumnFillAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case ColumnFillBalance:
        m_value.valueID = CSSValueBalance;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator ColumnFill() const
{
    if (m_primitiveUnitType == CSS_VALUE_ID) {
        if (m_value.valueID == CSSValueBalance)
            return ColumnFillBalance;
        if (m_value.valueID == CSSValueAuto)
            return ColumnFillAuto;
    }
    ASSERT_NOT_REACHED();
    return ColumnFillBalance;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBorderStyle e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case BNONE:
        m_value.valueID = CSSValueNone;
        break;
    case BHIDDEN:
        m_value.valueID = CSSValueHidden;
        break;
    case INSET:
        m_value.valueID = CSSValueInset;
        break;
    case GROOVE:
        m_value.valueID = CSSValueGroove;
        break;
    case RIDGE:
        m_value.valueID = CSSValueRidge;
        break;
    case OUTSET:
        m_value.valueID = CSSValueOutset;
        break;
    case DOTTED:
        m_value.valueID = CSSValueDotted;
        break;
    case DASHED:
        m_value.valueID = CSSValueDashed;
        break;
    case SOLID:
        m_value.valueID = CSSValueSolid;
        break;
    case DOUBLE:
        m_value.valueID = CSSValueDouble;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBorderStyle() const
{
    ASSERT(isValueID());
    if (m_value.valueID == CSSValueAuto) // Valid for CSS outline-style
        return DOTTED;
    return (EBorderStyle)(m_value.valueID - CSSValueNone);
}

template<> inline CSSPrimitiveValue::operator OutlineIsAuto() const
{
    if (m_value.valueID == CSSValueAuto)
        return AUTO_ON;
    return AUTO_OFF;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(CompositeOperator e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case CompositeClear:
        m_value.valueID = CSSValueClear;
        break;
    case CompositeCopy:
        m_value.valueID = CSSValueCopy;
        break;
    case CompositeSourceOver:
        m_value.valueID = CSSValueSourceOver;
        break;
    case CompositeSourceIn:
        m_value.valueID = CSSValueSourceIn;
        break;
    case CompositeSourceOut:
        m_value.valueID = CSSValueSourceOut;
        break;
    case CompositeSourceAtop:
        m_value.valueID = CSSValueSourceAtop;
        break;
    case CompositeDestinationOver:
        m_value.valueID = CSSValueDestinationOver;
        break;
    case CompositeDestinationIn:
        m_value.valueID = CSSValueDestinationIn;
        break;
    case CompositeDestinationOut:
        m_value.valueID = CSSValueDestinationOut;
        break;
    case CompositeDestinationAtop:
        m_value.valueID = CSSValueDestinationAtop;
        break;
    case CompositeXOR:
        m_value.valueID = CSSValueXor;
        break;
    case CompositePlusDarker:
        m_value.valueID = CSSValuePlusDarker;
        break;
    case CompositePlusLighter:
        m_value.valueID = CSSValuePlusLighter;
        break;
    case CompositeDifference:
        ASSERT_NOT_REACHED();
        break;
    }
}

template<> inline CSSPrimitiveValue::operator CompositeOperator() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueClear:
        return CompositeClear;
    case CSSValueCopy:
        return CompositeCopy;
    case CSSValueSourceOver:
        return CompositeSourceOver;
    case CSSValueSourceIn:
        return CompositeSourceIn;
    case CSSValueSourceOut:
        return CompositeSourceOut;
    case CSSValueSourceAtop:
        return CompositeSourceAtop;
    case CSSValueDestinationOver:
        return CompositeDestinationOver;
    case CSSValueDestinationIn:
        return CompositeDestinationIn;
    case CSSValueDestinationOut:
        return CompositeDestinationOut;
    case CSSValueDestinationAtop:
        return CompositeDestinationAtop;
    case CSSValueXor:
        return CompositeXOR;
    case CSSValuePlusDarker:
        return CompositePlusDarker;
    case CSSValuePlusLighter:
        return CompositePlusLighter;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return CompositeClear;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFillAttachment e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case LocalBackgroundAttachment:
        m_value.valueID = CSSValueLocal;
        break;
    case FixedBackgroundAttachment:
        m_value.valueID = CSSValueFixed;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EFillAttachment() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueLocal:
        return LocalBackgroundAttachment;
    case CSSValueFixed:
        return FixedBackgroundAttachment;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return LocalBackgroundAttachment;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFillBox e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case BorderFillBox:
        m_value.valueID = CSSValueBorderBox;
        break;
    case PaddingFillBox:
        m_value.valueID = CSSValuePaddingBox;
        break;
    case ContentFillBox:
        m_value.valueID = CSSValueContentBox;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EFillBox() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueBorder:
    case CSSValueBorderBox:
        return BorderFillBox;
    case CSSValuePadding:
    case CSSValuePaddingBox:
        return PaddingFillBox;
    case CSSValueContent:
    case CSSValueContentBox:
        return ContentFillBox;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return BorderFillBox;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFillRepeat e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case RepeatFill:
        m_value.valueID = CSSValueRepeat;
        break;
    case NoRepeatFill:
        m_value.valueID = CSSValueNoRepeat;
        break;
    case RoundFill:
        m_value.valueID = CSSValueRound;
        break;
    case SpaceFill:
        m_value.valueID = CSSValueSpace;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EFillRepeat() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueRepeat:
        return RepeatFill;
    case CSSValueNoRepeat:
        return NoRepeatFill;
    case CSSValueRound:
        return RoundFill;
    case CSSValueSpace:
        return SpaceFill;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return RepeatFill;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxPack e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case Start:
        m_value.valueID = CSSValueStart;
        break;
    case Center:
        m_value.valueID = CSSValueCenter;
        break;
    case End:
        m_value.valueID = CSSValueEnd;
        break;
    case Justify:
        m_value.valueID = CSSValueJustify;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxPack() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueStart:
        return Start;
    case CSSValueEnd:
        return End;
    case CSSValueCenter:
        return Center;
    case CSSValueJustify:
        return Justify;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return Justify;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxAlignment e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case BSTRETCH:
        m_value.valueID = CSSValueStretch;
        break;
    case BSTART:
        m_value.valueID = CSSValueStart;
        break;
    case BCENTER:
        m_value.valueID = CSSValueCenter;
        break;
    case BEND:
        m_value.valueID = CSSValueEnd;
        break;
    case BBASELINE:
        m_value.valueID = CSSValueBaseline;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxAlignment() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueStretch:
        return BSTRETCH;
    case CSSValueStart:
        return BSTART;
    case CSSValueEnd:
        return BEND;
    case CSSValueCenter:
        return BCENTER;
    case CSSValueBaseline:
        return BBASELINE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return BSTRETCH;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxDecorationBreak e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case DSLICE:
        m_value.valueID = CSSValueSlice;
        break;
    case DCLONE:
        m_value.valueID = CSSValueClone;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxDecorationBreak() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueSlice:
        return DSLICE;
    case CSSValueClone:
        return DCLONE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return DSLICE;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(BackgroundEdgeOrigin e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TopEdge:
        m_value.valueID = CSSValueTop;
        break;
    case RightEdge:
        m_value.valueID = CSSValueRight;
        break;
    case BottomEdge:
        m_value.valueID = CSSValueBottom;
        break;
    case LeftEdge:
        m_value.valueID = CSSValueLeft;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator BackgroundEdgeOrigin() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueTop:
        return TopEdge;
    case CSSValueRight:
        return RightEdge;
    case CSSValueBottom:
        return BottomEdge;
    case CSSValueLeft:
        return LeftEdge;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TopEdge;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxSizing e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case BORDER_BOX:
        m_value.valueID = CSSValueBorderBox;
        break;
    case CONTENT_BOX:
        m_value.valueID = CSSValueContentBox;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxSizing() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueBorderBox:
        return BORDER_BOX;
    case CSSValueContentBox:
        return CONTENT_BOX;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return BORDER_BOX;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxDirection e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case BNORMAL:
        m_value.valueID = CSSValueNormal;
        break;
    case BREVERSE:
        m_value.valueID = CSSValueReverse;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxDirection() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNormal:
        return BNORMAL;
    case CSSValueReverse:
        return BREVERSE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return BNORMAL;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxLines e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case SINGLE:
        m_value.valueID = CSSValueSingle;
        break;
    case MULTIPLE:
        m_value.valueID = CSSValueMultiple;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxLines() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueSingle:
        return SINGLE;
    case CSSValueMultiple:
        return MULTIPLE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return SINGLE;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EBoxOrient e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case HORIZONTAL:
        m_value.valueID = CSSValueHorizontal;
        break;
    case VERTICAL:
        m_value.valueID = CSSValueVertical;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EBoxOrient() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueHorizontal:
    case CSSValueInlineAxis:
        return HORIZONTAL;
    case CSSValueVertical:
    case CSSValueBlockAxis:
        return VERTICAL;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return HORIZONTAL;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EDisplay e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case INLINE:
        m_value.valueID = CSSValueInline;
        break;
    case PARAGRAPH:
        m_value.valueID = CSSValueParagraph;
        break;
    case FLEX:
        m_value.valueID = CSSValueFlex;
        break;
    case INLINE_FLEX:
        m_value.valueID = CSSValueInlineFlex;
        break;
    case NONE:
        m_value.valueID = CSSValueNone;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EDisplay() const
{
    ASSERT(isValueID());
    if (m_value.valueID == CSSValueNone)
        return NONE;

    EDisplay display = static_cast<EDisplay>(m_value.valueID - CSSValueInline);
    ASSERT(display >= INLINE && display <= NONE);
    return display;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EJustifyContent e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case JustifyFlexStart:
        m_value.valueID = CSSValueFlexStart;
        break;
    case JustifyFlexEnd:
        m_value.valueID = CSSValueFlexEnd;
        break;
    case JustifyCenter:
        m_value.valueID = CSSValueCenter;
        break;
    case JustifySpaceBetween:
        m_value.valueID = CSSValueSpaceBetween;
        break;
    case JustifySpaceAround:
        m_value.valueID = CSSValueSpaceAround;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EJustifyContent() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueFlexStart:
        return JustifyFlexStart;
    case CSSValueFlexEnd:
        return JustifyFlexEnd;
    case CSSValueCenter:
        return JustifyCenter;
    case CSSValueSpaceBetween:
        return JustifySpaceBetween;
    case CSSValueSpaceAround:
        return JustifySpaceAround;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return JustifyFlexStart;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFlexDirection e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case FlowRow:
        m_value.valueID = CSSValueRow;
        break;
    case FlowRowReverse:
        m_value.valueID = CSSValueRowReverse;
        break;
    case FlowColumn:
        m_value.valueID = CSSValueColumn;
        break;
    case FlowColumnReverse:
        m_value.valueID = CSSValueColumnReverse;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EFlexDirection() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueRow:
        return FlowRow;
    case CSSValueRowReverse:
        return FlowRowReverse;
    case CSSValueColumn:
        return FlowColumn;
    case CSSValueColumnReverse:
        return FlowColumnReverse;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return FlowRow;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EAlignContent e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case AlignContentFlexStart:
        m_value.valueID = CSSValueFlexStart;
        break;
    case AlignContentFlexEnd:
        m_value.valueID = CSSValueFlexEnd;
        break;
    case AlignContentCenter:
        m_value.valueID = CSSValueCenter;
        break;
    case AlignContentSpaceBetween:
        m_value.valueID = CSSValueSpaceBetween;
        break;
    case AlignContentSpaceAround:
        m_value.valueID = CSSValueSpaceAround;
        break;
    case AlignContentStretch:
        m_value.valueID = CSSValueStretch;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EAlignContent() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueFlexStart:
        return AlignContentFlexStart;
    case CSSValueFlexEnd:
        return AlignContentFlexEnd;
    case CSSValueCenter:
        return AlignContentCenter;
    case CSSValueSpaceBetween:
        return AlignContentSpaceBetween;
    case CSSValueSpaceAround:
        return AlignContentSpaceAround;
    case CSSValueStretch:
        return AlignContentStretch;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return AlignContentStretch;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFlexWrap e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case FlexNoWrap:
        m_value.valueID = CSSValueNowrap;
        break;
    case FlexWrap:
        m_value.valueID = CSSValueWrap;
        break;
    case FlexWrapReverse:
        m_value.valueID = CSSValueWrapReverse;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EFlexWrap() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNowrap:
        return FlexNoWrap;
    case CSSValueWrap:
        return FlexWrap;
    case CSSValueWrapReverse:
        return FlexWrapReverse;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return FlexNoWrap;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(LineBreak e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case LineBreakAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case LineBreakLoose:
        m_value.valueID = CSSValueLoose;
        break;
    case LineBreakNormal:
        m_value.valueID = CSSValueNormal;
        break;
    case LineBreakStrict:
        m_value.valueID = CSSValueStrict;
        break;
    case LineBreakAfterWhiteSpace:
        m_value.valueID = CSSValueAfterWhiteSpace;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator LineBreak() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return LineBreakAuto;
    case CSSValueLoose:
        return LineBreakLoose;
    case CSSValueNormal:
        return LineBreakNormal;
    case CSSValueStrict:
        return LineBreakStrict;
    case CSSValueAfterWhiteSpace:
        return LineBreakAfterWhiteSpace;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return LineBreakAuto;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EOverflow e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case OVISIBLE:
        m_value.valueID = CSSValueVisible;
        break;
    case OHIDDEN:
        m_value.valueID = CSSValueHidden;
        break;
    case OAUTO:
        m_value.valueID = CSSValueAuto;
        break;
    case OOVERLAY:
        m_value.valueID = CSSValueOverlay;
        break;
    case OPAGEDX:
        m_value.valueID = CSSValueWebkitPagedX;
        break;
    case OPAGEDY:
        m_value.valueID = CSSValueWebkitPagedY;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EOverflow() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueVisible:
        return OVISIBLE;
    case CSSValueHidden:
        return OHIDDEN;
    case CSSValueAuto:
        return OAUTO;
    case CSSValueOverlay:
        return OOVERLAY;
    case CSSValueWebkitPagedX:
        return OPAGEDX;
    case CSSValueWebkitPagedY:
        return OPAGEDY;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return OVISIBLE;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EPosition e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case StaticPosition:
        m_value.valueID = CSSValueStatic;
        break;
    case AbsolutePosition:
        m_value.valueID = CSSValueAbsolute;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EPosition() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueStatic:
        return StaticPosition;
    case CSSValueAbsolute:
        return AbsolutePosition;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return StaticPosition;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(ETextAlign e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TASTART:
        m_value.valueID = CSSValueStart;
        break;
    case TAEND:
        m_value.valueID = CSSValueEnd;
        break;
    case LEFT:
        m_value.valueID = CSSValueLeft;
        break;
    case RIGHT:
        m_value.valueID = CSSValueRight;
        break;
    case CENTER:
        m_value.valueID = CSSValueCenter;
        break;
    case JUSTIFY:
        m_value.valueID = CSSValueJustify;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator ETextAlign() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueStart:
        return TASTART;
    case CSSValueEnd:
        return TAEND;
    default:
        return static_cast<ETextAlign>(m_value.valueID - CSSValueLeft);
    }
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextAlignLast e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TextAlignLastStart:
        m_value.valueID = CSSValueStart;
        break;
    case TextAlignLastEnd:
        m_value.valueID = CSSValueEnd;
        break;
    case TextAlignLastLeft:
        m_value.valueID = CSSValueLeft;
        break;
    case TextAlignLastRight:
        m_value.valueID = CSSValueRight;
        break;
    case TextAlignLastCenter:
        m_value.valueID = CSSValueCenter;
        break;
    case TextAlignLastJustify:
        m_value.valueID = CSSValueJustify;
        break;
    case TextAlignLastAuto:
        m_value.valueID = CSSValueAuto;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextAlignLast() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return TextAlignLastAuto;
    case CSSValueStart:
        return TextAlignLastStart;
    case CSSValueEnd:
        return TextAlignLastEnd;
    case CSSValueLeft:
        return TextAlignLastLeft;
    case CSSValueRight:
        return TextAlignLastRight;
    case CSSValueCenter:
        return TextAlignLastCenter;
    case CSSValueJustify:
        return TextAlignLastJustify;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextAlignLastAuto;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextJustify e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TextJustifyAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case TextJustifyNone:
        m_value.valueID = CSSValueNone;
        break;
    case TextJustifyInterWord:
        m_value.valueID = CSSValueInterWord;
        break;
    case TextJustifyDistribute:
        m_value.valueID = CSSValueDistribute;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextJustify() const
{
    switch (m_value.valueID) {
    case CSSValueAuto:
        return TextJustifyAuto;
    case CSSValueNone:
        return TextJustifyNone;
    case CSSValueInterWord:
        return TextJustifyInterWord;
    case CSSValueDistribute:
        return TextJustifyDistribute;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextJustifyAuto;
}

template<> inline CSSPrimitiveValue::operator TextDecoration() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNone:
        return TextDecorationNone;
    case CSSValueUnderline:
        return TextDecorationUnderline;
    case CSSValueOverline:
        return TextDecorationOverline;
    case CSSValueLineThrough:
        return TextDecorationLineThrough;
    case CSSValueBlink:
        return TextDecorationBlink;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextDecorationNone;
}

template<> inline CSSPrimitiveValue::operator TextDecorationStyle() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueSolid:
        return TextDecorationStyleSolid;
    case CSSValueDouble:
        return TextDecorationStyleDouble;
    case CSSValueDotted:
        return TextDecorationStyleDotted;
    case CSSValueDashed:
        return TextDecorationStyleDashed;
    case CSSValueWavy:
        return TextDecorationStyleWavy;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextDecorationStyleSolid;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextUnderlinePosition e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TextUnderlinePositionAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case TextUnderlinePositionUnder:
        m_value.valueID = CSSValueUnder;
        break;
    }

    // FIXME: Implement support for 'under left' and 'under right' values.
}

template<> inline CSSPrimitiveValue::operator TextUnderlinePosition() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return TextUnderlinePositionAuto;
    case CSSValueUnder:
        return TextUnderlinePositionUnder;
    default:
        break;
    }

    // FIXME: Implement support for 'under left' and 'under right' values.

    ASSERT_NOT_REACHED();
    return TextUnderlinePositionAuto;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EUnicodeBidi e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case UBNormal:
        m_value.valueID = CSSValueNormal;
        break;
    case Embed:
        m_value.valueID = CSSValueEmbed;
        break;
    case Override:
        m_value.valueID = CSSValueBidiOverride;
        break;
    case Isolate:
        m_value.valueID = CSSValueWebkitIsolate;
        break;
    case IsolateOverride:
        m_value.valueID = CSSValueWebkitIsolateOverride;
        break;
    case Plaintext:
        m_value.valueID = CSSValueWebkitPlaintext;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EUnicodeBidi() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNormal:
        return UBNormal;
    case CSSValueEmbed:
        return Embed;
    case CSSValueBidiOverride:
        return Override;
    case CSSValueWebkitIsolate:
        return Isolate;
    case CSSValueWebkitIsolateOverride:
        return IsolateOverride;
    case CSSValueWebkitPlaintext:
        return Plaintext;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return UBNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EUserModify e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case READ_ONLY:
        m_value.valueID = CSSValueReadOnly;
        break;
    case READ_WRITE:
        m_value.valueID = CSSValueReadWrite;
        break;
    case READ_WRITE_PLAINTEXT_ONLY:
        m_value.valueID = CSSValueReadWritePlaintextOnly;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EUserModify() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueReadOnly:
        return READ_ONLY;
    case CSSValueReadWrite:
        return READ_WRITE;
    case CSSValueReadWritePlaintextOnly:
        return READ_WRITE_PLAINTEXT_ONLY;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return READ_ONLY;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EUserSelect e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case SELECT_NONE:
        m_value.valueID = CSSValueNone;
        break;
    case SELECT_TEXT:
        m_value.valueID = CSSValueText;
        break;
    case SELECT_ALL:
        m_value.valueID = CSSValueAll;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EUserSelect() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return SELECT_TEXT;
    case CSSValueNone:
        return SELECT_NONE;
    case CSSValueText:
        return SELECT_TEXT;
    case CSSValueAll:
        return SELECT_ALL;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return SELECT_TEXT;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EVerticalAlign a)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (a) {
    case TOP:
        m_value.valueID = CSSValueTop;
        break;
    case BOTTOM:
        m_value.valueID = CSSValueBottom;
        break;
    case MIDDLE:
        m_value.valueID = CSSValueMiddle;
        break;
    case BASELINE:
        m_value.valueID = CSSValueBaseline;
        break;
    case TEXT_BOTTOM:
        m_value.valueID = CSSValueTextBottom;
        break;
    case TEXT_TOP:
        m_value.valueID = CSSValueTextTop;
        break;
    case SUB:
        m_value.valueID = CSSValueSub;
        break;
    case SUPER:
        m_value.valueID = CSSValueSuper;
        break;
    case BASELINE_MIDDLE:
        m_value.valueID = CSSValueWebkitBaselineMiddle;
        break;
    case LENGTH:
        m_value.valueID = CSSValueInvalid;
    }
}

template<> inline CSSPrimitiveValue::operator EVerticalAlign() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueTop:
        return TOP;
    case CSSValueBottom:
        return BOTTOM;
    case CSSValueMiddle:
        return MIDDLE;
    case CSSValueBaseline:
        return BASELINE;
    case CSSValueTextBottom:
        return TEXT_BOTTOM;
    case CSSValueTextTop:
        return TEXT_TOP;
    case CSSValueSub:
        return SUB;
    case CSSValueSuper:
        return SUPER;
    case CSSValueWebkitBaselineMiddle:
        return BASELINE_MIDDLE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TOP;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EVisibility e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case VISIBLE:
        m_value.valueID = CSSValueVisible;
        break;
    case HIDDEN:
        m_value.valueID = CSSValueHidden;
        break;
    case COLLAPSE:
        m_value.valueID = CSSValueCollapse;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EVisibility() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueHidden:
        return HIDDEN;
    case CSSValueVisible:
        return VISIBLE;
    case CSSValueCollapse:
        return COLLAPSE;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return VISIBLE;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EWhiteSpace e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case NORMAL:
        m_value.valueID = CSSValueNormal;
        break;
    case PRE:
        m_value.valueID = CSSValuePre;
        break;
    case PRE_WRAP:
        m_value.valueID = CSSValuePreWrap;
        break;
    case PRE_LINE:
        m_value.valueID = CSSValuePreLine;
        break;
    case NOWRAP:
        m_value.valueID = CSSValueNowrap;
        break;
    case KHTML_NOWRAP:
        m_value.valueID = CSSValueWebkitNowrap;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EWhiteSpace() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueWebkitNowrap:
        return KHTML_NOWRAP;
    case CSSValueNowrap:
        return NOWRAP;
    case CSSValuePre:
        return PRE;
    case CSSValuePreWrap:
        return PRE_WRAP;
    case CSSValuePreLine:
        return PRE_LINE;
    case CSSValueNormal:
        return NORMAL;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return NORMAL;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EWordBreak e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case NormalWordBreak:
        m_value.valueID = CSSValueNormal;
        break;
    case BreakAllWordBreak:
        m_value.valueID = CSSValueBreakAll;
        break;
    case BreakWordBreak:
        m_value.valueID = CSSValueBreakWord;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EWordBreak() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueBreakAll:
        return BreakAllWordBreak;
    case CSSValueBreakWord:
        return BreakWordBreak;
    case CSSValueNormal:
        return NormalWordBreak;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return NormalWordBreak;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EOverflowWrap e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case NormalOverflowWrap:
        m_value.valueID = CSSValueNormal;
        break;
    case BreakOverflowWrap:
        m_value.valueID = CSSValueBreakWord;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EOverflowWrap() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueBreakWord:
        return BreakOverflowWrap;
    case CSSValueNormal:
        return NormalOverflowWrap;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return NormalOverflowWrap;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextDirection e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case LTR:
        m_value.valueID = CSSValueLtr;
        break;
    case RTL:
        m_value.valueID = CSSValueRtl;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextDirection() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueLtr:
        return LTR;
    case CSSValueRtl:
        return RTL;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return LTR;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextEmphasisPosition position)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (position) {
    case TextEmphasisPositionOver:
        m_value.valueID = CSSValueOver;
        break;
    case TextEmphasisPositionUnder:
        m_value.valueID = CSSValueUnder;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextEmphasisPosition() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueOver:
        return TextEmphasisPositionOver;
    case CSSValueUnder:
        return TextEmphasisPositionUnder;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextEmphasisPositionOver;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextOverflow overflow)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (overflow) {
    case TextOverflowClip:
        m_value.valueID = CSSValueClip;
        break;
    case TextOverflowEllipsis:
        m_value.valueID = CSSValueEllipsis;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextOverflow() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueClip:
        return TextOverflowClip;
    case CSSValueEllipsis:
        return TextOverflowEllipsis;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextOverflowClip;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextEmphasisFill fill)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (fill) {
    case TextEmphasisFillFilled:
        m_value.valueID = CSSValueFilled;
        break;
    case TextEmphasisFillOpen:
        m_value.valueID = CSSValueOpen;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextEmphasisFill() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueFilled:
        return TextEmphasisFillFilled;
    case CSSValueOpen:
        return TextEmphasisFillOpen;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextEmphasisFillFilled;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextEmphasisMark mark)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (mark) {
    case TextEmphasisMarkDot:
        m_value.valueID = CSSValueDot;
        break;
    case TextEmphasisMarkCircle:
        m_value.valueID = CSSValueCircle;
        break;
    case TextEmphasisMarkDoubleCircle:
        m_value.valueID = CSSValueDoubleCircle;
        break;
    case TextEmphasisMarkTriangle:
        m_value.valueID = CSSValueTriangle;
        break;
    case TextEmphasisMarkSesame:
        m_value.valueID = CSSValueSesame;
        break;
    case TextEmphasisMarkNone:
    case TextEmphasisMarkAuto:
    case TextEmphasisMarkCustom:
        ASSERT_NOT_REACHED();
        m_value.valueID = CSSValueNone;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextEmphasisMark() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNone:
        return TextEmphasisMarkNone;
    case CSSValueDot:
        return TextEmphasisMarkDot;
    case CSSValueCircle:
        return TextEmphasisMarkCircle;
    case CSSValueDoubleCircle:
        return TextEmphasisMarkDoubleCircle;
    case CSSValueTriangle:
        return TextEmphasisMarkTriangle;
    case CSSValueSesame:
        return TextEmphasisMarkSesame;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextEmphasisMarkNone;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextOrientation e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TextOrientationSideways:
        m_value.valueID = CSSValueSideways;
        break;
    case TextOrientationSidewaysRight:
        m_value.valueID = CSSValueSidewaysRight;
        break;
    case TextOrientationVerticalRight:
        m_value.valueID = CSSValueVerticalRight;
        break;
    case TextOrientationUpright:
        m_value.valueID = CSSValueUpright;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextOrientation() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueSideways:
        return TextOrientationSideways;
    case CSSValueSidewaysRight:
        return TextOrientationSidewaysRight;
    case CSSValueVerticalRight:
        return TextOrientationVerticalRight;
    case CSSValueUpright:
        return TextOrientationUpright;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TextOrientationVerticalRight;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EPointerEvents e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case PE_NONE:
        m_value.valueID = CSSValueNone;
        break;
    case PE_STROKE:
        m_value.valueID = CSSValueStroke;
        break;
    case PE_FILL:
        m_value.valueID = CSSValueFill;
        break;
    case PE_PAINTED:
        m_value.valueID = CSSValuePainted;
        break;
    case PE_VISIBLE:
        m_value.valueID = CSSValueVisible;
        break;
    case PE_VISIBLE_STROKE:
        m_value.valueID = CSSValueVisiblestroke;
        break;
    case PE_VISIBLE_FILL:
        m_value.valueID = CSSValueVisiblefill;
        break;
    case PE_VISIBLE_PAINTED:
        m_value.valueID = CSSValueVisiblepainted;
        break;
    case PE_AUTO:
        m_value.valueID = CSSValueAuto;
        break;
    case PE_ALL:
        m_value.valueID = CSSValueAll;
        break;
    case PE_BOUNDINGBOX:
        m_value.valueID = CSSValueBoundingBox;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EPointerEvents() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAll:
        return PE_ALL;
    case CSSValueAuto:
        return PE_AUTO;
    case CSSValueNone:
        return PE_NONE;
    case CSSValueVisiblepainted:
        return PE_VISIBLE_PAINTED;
    case CSSValueVisiblefill:
        return PE_VISIBLE_FILL;
    case CSSValueVisiblestroke:
        return PE_VISIBLE_STROKE;
    case CSSValueVisible:
        return PE_VISIBLE;
    case CSSValuePainted:
        return PE_PAINTED;
    case CSSValueFill:
        return PE_FILL;
    case CSSValueStroke:
        return PE_STROKE;
    case CSSValueBoundingBox:
        return PE_BOUNDINGBOX;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return PE_ALL;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontDescription::Kerning kerning)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (kerning) {
    case FontDescription::AutoKerning:
        m_value.valueID = CSSValueAuto;
        return;
    case FontDescription::NormalKerning:
        m_value.valueID = CSSValueNormal;
        return;
    case FontDescription::NoneKerning:
        m_value.valueID = CSSValueNone;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueAuto;
}

template<> inline CSSPrimitiveValue::operator FontDescription::Kerning() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return FontDescription::AutoKerning;
    case CSSValueNormal:
        return FontDescription::NormalKerning;
    case CSSValueNone:
        return FontDescription::NoneKerning;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return FontDescription::AutoKerning;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(ObjectFit fit)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (fit) {
    case ObjectFitFill:
        m_value.valueID = CSSValueFill;
        break;
    case ObjectFitContain:
        m_value.valueID = CSSValueContain;
        break;
    case ObjectFitCover:
        m_value.valueID = CSSValueCover;
        break;
    case ObjectFitNone:
        m_value.valueID = CSSValueNone;
        break;
    case ObjectFitScaleDown:
        m_value.valueID = CSSValueScaleDown;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator ObjectFit() const
{
    switch (m_value.valueID) {
    case CSSValueFill:
        return ObjectFitFill;
    case CSSValueContain:
        return ObjectFitContain;
    case CSSValueCover:
        return ObjectFitCover;
    case CSSValueNone:
        return ObjectFitNone;
    case CSSValueScaleDown:
        return ObjectFitScaleDown;
    default:
        ASSERT_NOT_REACHED();
        return ObjectFitFill;
    }
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EFillSizeType fillSize)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (fillSize) {
    case Contain:
        m_value.valueID = CSSValueContain;
        break;
    case Cover:
        m_value.valueID = CSSValueCover;
        break;
    case SizeNone:
        m_value.valueID = CSSValueNone;
        break;
    case SizeLength:
    default:
        ASSERT_NOT_REACHED();
    }
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontSmoothingMode smoothing)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (smoothing) {
    case AutoSmoothing:
        m_value.valueID = CSSValueAuto;
        return;
    case NoSmoothing:
        m_value.valueID = CSSValueNone;
        return;
    case Antialiased:
        m_value.valueID = CSSValueAntialiased;
        return;
    case SubpixelAntialiased:
        m_value.valueID = CSSValueSubpixelAntialiased;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueAuto;
}

template<> inline CSSPrimitiveValue::operator FontSmoothingMode() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return AutoSmoothing;
    case CSSValueNone:
        return NoSmoothing;
    case CSSValueAntialiased:
        return Antialiased;
    case CSSValueSubpixelAntialiased:
        return SubpixelAntialiased;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return AutoSmoothing;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontWeight weight)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (weight) {
    case FontWeight900:
        m_value.valueID = CSSValue900;
        return;
    case FontWeight800:
        m_value.valueID = CSSValue800;
        return;
    case FontWeight700:
        m_value.valueID = CSSValueBold;
        return;
    case FontWeight600:
        m_value.valueID = CSSValue600;
        return;
    case FontWeight500:
        m_value.valueID = CSSValue500;
        return;
    case FontWeight400:
        m_value.valueID = CSSValueNormal;
        return;
    case FontWeight300:
        m_value.valueID = CSSValue300;
        return;
    case FontWeight200:
        m_value.valueID = CSSValue200;
        return;
    case FontWeight100:
        m_value.valueID = CSSValue100;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueNormal;
}

template<> inline CSSPrimitiveValue::operator FontWeight() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueBold:
        return FontWeightBold;
    case CSSValueNormal:
        return FontWeightNormal;
    case CSSValue900:
        return FontWeight900;
    case CSSValue800:
        return FontWeight800;
    case CSSValue700:
        return FontWeight700;
    case CSSValue600:
        return FontWeight600;
    case CSSValue500:
        return FontWeight500;
    case CSSValue400:
        return FontWeight400;
    case CSSValue300:
        return FontWeight300;
    case CSSValue200:
        return FontWeight200;
    case CSSValue100:
        return FontWeight100;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return FontWeightNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontStyle italic)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (italic) {
    case FontStyleNormal:
        m_value.valueID = CSSValueNormal;
        return;
    case FontStyleItalic:
        m_value.valueID = CSSValueItalic;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueNormal;
}

template<> inline CSSPrimitiveValue::operator FontStyle() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueOblique:
    // FIXME: oblique is the same as italic for the moment...
    case CSSValueItalic:
        return FontStyleItalic;
    case CSSValueNormal:
        return FontStyleNormal;
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return FontStyleNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontStretch stretch)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (stretch) {
    case FontStretchUltraCondensed:
        m_value.valueID = CSSValueUltraCondensed;
        return;
    case FontStretchExtraCondensed:
        m_value.valueID = CSSValueExtraCondensed;
        return;
    case FontStretchCondensed:
        m_value.valueID = CSSValueCondensed;
        return;
    case FontStretchSemiCondensed:
        m_value.valueID = CSSValueSemiCondensed;
        return;
    case FontStretchNormal:
        m_value.valueID = CSSValueNormal;
        return;
    case FontStretchSemiExpanded:
        m_value.valueID = CSSValueSemiExpanded;
        return;
    case FontStretchExpanded:
        m_value.valueID = CSSValueExpanded;
        return;
    case FontStretchExtraExpanded:
        m_value.valueID = CSSValueExtraExpanded;
        return;
    case FontStretchUltraExpanded:
        m_value.valueID = CSSValueUltraExpanded;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueNormal;
}

template<> inline CSSPrimitiveValue::operator FontStretch() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueUltraCondensed:
        return FontStretchUltraCondensed;
    case CSSValueExtraCondensed:
        return FontStretchExtraCondensed;
    case CSSValueCondensed:
        return FontStretchCondensed;
    case CSSValueSemiCondensed:
        return FontStretchSemiCondensed;
    case CSSValueNormal:
        return FontStretchNormal;
    case CSSValueSemiExpanded:
        return FontStretchSemiExpanded;
    case CSSValueExpanded:
        return FontStretchExpanded;
    case CSSValueExtraExpanded:
        return FontStretchExtraExpanded;
    case CSSValueUltraExpanded:
        return FontStretchUltraExpanded;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return FontStretchNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(FontVariant smallCaps)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (smallCaps) {
    case FontVariantNormal:
        m_value.valueID = CSSValueNormal;
        return;
    case FontVariantSmallCaps:
        m_value.valueID = CSSValueSmallCaps;
        return;
    }

    ASSERT_NOT_REACHED();
    m_value.valueID = CSSValueNormal;
}

template<> inline CSSPrimitiveValue::operator FontVariant() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueSmallCaps:
        return FontVariantSmallCaps;
    case CSSValueNormal:
        return FontVariantNormal;
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return FontVariantNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TextRenderingMode e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case AutoTextRendering:
        m_value.valueID = CSSValueAuto;
        break;
    case OptimizeSpeed:
        m_value.valueID = CSSValueOptimizespeed;
        break;
    case OptimizeLegibility:
        m_value.valueID = CSSValueOptimizelegibility;
        break;
    case GeometricPrecision:
        m_value.valueID = CSSValueGeometricprecision;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TextRenderingMode() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return AutoTextRendering;
    case CSSValueOptimizespeed:
        return OptimizeSpeed;
    case CSSValueOptimizelegibility:
        return OptimizeLegibility;
    case CSSValueGeometricprecision:
        return GeometricPrecision;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return AutoTextRendering;
}

template<> inline CSSPrimitiveValue::operator Order() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueLogical:
        return LogicalOrder;
    case CSSValueVisual:
        return VisualOrder;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return LogicalOrder;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(Order e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case LogicalOrder:
        m_value.valueID = CSSValueLogical;
        break;
    case VisualOrder:
        m_value.valueID = CSSValueVisual;
        break;
    }
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(blink::WebBlendMode blendMode)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (blendMode) {
    case blink::WebBlendModeNormal:
        m_value.valueID = CSSValueNormal;
        break;
    case blink::WebBlendModeMultiply:
        m_value.valueID = CSSValueMultiply;
        break;
    case blink::WebBlendModeScreen:
        m_value.valueID = CSSValueScreen;
        break;
    case blink::WebBlendModeOverlay:
        m_value.valueID = CSSValueOverlay;
        break;
    case blink::WebBlendModeDarken:
        m_value.valueID = CSSValueDarken;
        break;
    case blink::WebBlendModeLighten:
        m_value.valueID = CSSValueLighten;
        break;
    case blink::WebBlendModeColorDodge:
        m_value.valueID = CSSValueColorDodge;
        break;
    case blink::WebBlendModeColorBurn:
        m_value.valueID = CSSValueColorBurn;
        break;
    case blink::WebBlendModeHardLight:
        m_value.valueID = CSSValueHardLight;
        break;
    case blink::WebBlendModeSoftLight:
        m_value.valueID = CSSValueSoftLight;
        break;
    case blink::WebBlendModeDifference:
        m_value.valueID = CSSValueDifference;
        break;
    case blink::WebBlendModeExclusion:
        m_value.valueID = CSSValueExclusion;
        break;
    case blink::WebBlendModeHue:
        m_value.valueID = CSSValueHue;
        break;
    case blink::WebBlendModeSaturation:
        m_value.valueID = CSSValueSaturation;
        break;
    case blink::WebBlendModeColor:
        m_value.valueID = CSSValueColor;
        break;
    case blink::WebBlendModeLuminosity:
        m_value.valueID = CSSValueLuminosity;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator blink::WebBlendMode() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNormal:
        return blink::WebBlendModeNormal;
    case CSSValueMultiply:
        return blink::WebBlendModeMultiply;
    case CSSValueScreen:
        return blink::WebBlendModeScreen;
    case CSSValueOverlay:
        return blink::WebBlendModeOverlay;
    case CSSValueDarken:
        return blink::WebBlendModeDarken;
    case CSSValueLighten:
        return blink::WebBlendModeLighten;
    case CSSValueColorDodge:
        return blink::WebBlendModeColorDodge;
    case CSSValueColorBurn:
        return blink::WebBlendModeColorBurn;
    case CSSValueHardLight:
        return blink::WebBlendModeHardLight;
    case CSSValueSoftLight:
        return blink::WebBlendModeSoftLight;
    case CSSValueDifference:
        return blink::WebBlendModeDifference;
    case CSSValueExclusion:
        return blink::WebBlendModeExclusion;
    case CSSValueHue:
        return blink::WebBlendModeHue;
    case CSSValueSaturation:
        return blink::WebBlendModeSaturation;
    case CSSValueColor:
        return blink::WebBlendModeColor;
    case CSSValueLuminosity:
        return blink::WebBlendModeLuminosity;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return blink::WebBlendModeNormal;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(LineCap e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case ButtCap:
        m_value.valueID = CSSValueButt;
        break;
    case RoundCap:
        m_value.valueID = CSSValueRound;
        break;
    case SquareCap:
        m_value.valueID = CSSValueSquare;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator LineCap() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueButt:
        return ButtCap;
    case CSSValueRound:
        return RoundCap;
    case CSSValueSquare:
        return SquareCap;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return ButtCap;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(LineJoin e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case MiterJoin:
        m_value.valueID = CSSValueMiter;
        break;
    case RoundJoin:
        m_value.valueID = CSSValueRound;
        break;
    case BevelJoin:
        m_value.valueID = CSSValueBevel;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator LineJoin() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueMiter:
        return MiterJoin;
    case CSSValueRound:
        return RoundJoin;
    case CSSValueBevel:
        return BevelJoin;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return MiterJoin;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(WindRule e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case RULE_NONZERO:
        m_value.valueID = CSSValueNonzero;
        break;
    case RULE_EVENODD:
        m_value.valueID = CSSValueEvenodd;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator WindRule() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNonzero:
        return RULE_NONZERO;
    case CSSValueEvenodd:
        return RULE_EVENODD;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return RULE_NONZERO;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(EImageRendering e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case ImageRenderingAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case ImageRenderingOptimizeSpeed:
        m_value.valueID = CSSValueOptimizespeed;
        break;
    case ImageRenderingOptimizeQuality:
        m_value.valueID = CSSValueOptimizequality;
        break;
    case ImageRenderingPixelated:
        m_value.valueID = CSSValuePixelated;
        break;
    case ImageRenderingOptimizeContrast:
        m_value.valueID = CSSValueWebkitOptimizeContrast;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator EImageRendering() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueAuto:
        return ImageRenderingAuto;
    case CSSValueOptimizespeed:
        return ImageRenderingOptimizeSpeed;
    case CSSValueOptimizequality:
        return ImageRenderingOptimizeQuality;
    case CSSValuePixelated:
        return ImageRenderingPixelated;
    case CSSValueWebkitOptimizeContrast:
        return ImageRenderingOptimizeContrast;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return ImageRenderingAuto;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(ETransformStyle3D e)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (e) {
    case TransformStyle3DFlat:
        m_value.valueID = CSSValueFlat;
        break;
    case TransformStyle3DPreserve3D:
        m_value.valueID = CSSValuePreserve3d;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator ETransformStyle3D() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueFlat:
        return TransformStyle3DFlat;
    case CSSValuePreserve3d:
        return TransformStyle3DPreserve3D;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TransformStyle3DFlat;
}

enum LengthConversion {
    AnyConversion = ~0,
    FixedConversion = 1 << 0,
    AutoConversion = 1 << 1,
    PercentConversion = 1 << 2,
};

template<int supported> Length CSSPrimitiveValue::convertToLength(const CSSToLengthConversionData& conversionData)
{
    if ((supported & FixedConversion) && isLength())
        return computeLength<Length>(conversionData);
    if ((supported & PercentConversion) && isPercentage())
        return Length(getDoubleValue(), Percent);
    if ((supported & AutoConversion) && getValueID() == CSSValueAuto)
        return Length(Auto);
    if ((supported & FixedConversion) && (supported & PercentConversion) && isCalculated())
        return Length(cssCalcValue()->toCalcValue(conversionData));
    ASSERT_NOT_REACHED();
    return Length(0, Fixed);
}

template<> inline CSSPrimitiveValue::operator TouchAction() const
{
    ASSERT(isValueID());
    switch (m_value.valueID) {
    case CSSValueNone:
        return TouchActionNone;
    case CSSValueAuto:
        return TouchActionAuto;
    case CSSValuePanX:
        return TouchActionPanX;
    case CSSValuePanY:
        return TouchActionPanY;
    case CSSValueManipulation:
        return TouchActionPanX | TouchActionPanY | TouchActionPinchZoom;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TouchActionNone;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(TouchActionDelay t)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (t) {
    case TouchActionDelayNone:
        m_value.valueID = CSSValueNone;
        break;
    case TouchActionDelayScript:
        m_value.valueID = CSSValueScript;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator TouchActionDelay() const
{
    switch (m_value.valueID) {
    case CSSValueNone:
        return TouchActionDelayNone;
    case CSSValueScript:
        return TouchActionDelayScript;
    default:
        break;
    }

    ASSERT_NOT_REACHED();
    return TouchActionDelayNone;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(CSSBoxType cssBox)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (cssBox) {
    case MarginBox:
        m_value.valueID = CSSValueMarginBox;
        break;
    case BorderBox:
        m_value.valueID = CSSValueBorderBox;
        break;
    case PaddingBox:
        m_value.valueID = CSSValuePaddingBox;
        break;
    case ContentBox:
        m_value.valueID = CSSValueContentBox;
        break;
    case BoxMissing:
        // The missing box should convert to a null primitive value.
        ASSERT_NOT_REACHED();
    }
}

template<> inline CSSPrimitiveValue::operator CSSBoxType() const
{
    switch (getValueID()) {
    case CSSValueMarginBox:
        return MarginBox;
    case CSSValueBorderBox:
        return BorderBox;
    case CSSValuePaddingBox:
        return PaddingBox;
    case CSSValueContentBox:
        return ContentBox;
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return ContentBox;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(ItemPosition itemPosition)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (itemPosition) {
    case ItemPositionAuto:
        m_value.valueID = CSSValueAuto;
        break;
    case ItemPositionStretch:
        m_value.valueID = CSSValueStretch;
        break;
    case ItemPositionBaseline:
        m_value.valueID = CSSValueBaseline;
        break;
    case ItemPositionLastBaseline:
        m_value.valueID = CSSValueLastBaseline;
        break;
    case ItemPositionCenter:
        m_value.valueID = CSSValueCenter;
        break;
    case ItemPositionStart:
        m_value.valueID = CSSValueStart;
        break;
    case ItemPositionEnd:
        m_value.valueID = CSSValueEnd;
        break;
    case ItemPositionSelfStart:
        m_value.valueID = CSSValueSelfStart;
        break;
    case ItemPositionSelfEnd:
        m_value.valueID = CSSValueSelfEnd;
        break;
    case ItemPositionFlexStart:
        m_value.valueID = CSSValueFlexStart;
        break;
    case ItemPositionFlexEnd:
        m_value.valueID = CSSValueFlexEnd;
        break;
    case ItemPositionLeft:
        m_value.valueID = CSSValueLeft;
        break;
    case ItemPositionRight:
        m_value.valueID = CSSValueRight;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator ItemPosition() const
{
    switch (m_value.valueID) {
    case CSSValueAuto:
        return ItemPositionAuto;
    case CSSValueStretch:
        return ItemPositionStretch;
    case CSSValueBaseline:
        return ItemPositionBaseline;
    case CSSValueLastBaseline:
        return ItemPositionLastBaseline;
    case CSSValueCenter:
        return ItemPositionCenter;
    case CSSValueStart:
        return ItemPositionStart;
    case CSSValueEnd:
        return ItemPositionEnd;
    case CSSValueSelfStart:
        return ItemPositionSelfStart;
    case CSSValueSelfEnd:
        return ItemPositionSelfEnd;
    case CSSValueFlexStart:
        return ItemPositionFlexStart;
    case CSSValueFlexEnd:
        return ItemPositionFlexEnd;
    case CSSValueLeft:
        return ItemPositionLeft;
    case CSSValueRight:
        return ItemPositionRight;
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return ItemPositionAuto;
}

template<> inline CSSPrimitiveValue::CSSPrimitiveValue(OverflowAlignment overflowAlignment)
    : CSSValue(PrimitiveClass)
{
    m_primitiveUnitType = CSS_VALUE_ID;
    switch (overflowAlignment) {
    case OverflowAlignmentDefault:
        m_value.valueID = CSSValueDefault;
        break;
    case OverflowAlignmentTrue:
        m_value.valueID = CSSValueTrue;
        break;
    case OverflowAlignmentSafe:
        m_value.valueID = CSSValueSafe;
        break;
    }
}

template<> inline CSSPrimitiveValue::operator OverflowAlignment() const
{
    switch (m_value.valueID) {
    case CSSValueTrue:
        return OverflowAlignmentTrue;
    case CSSValueSafe:
        return OverflowAlignmentSafe;
    default:
        break;
    }
    ASSERT_NOT_REACHED();
    return OverflowAlignmentTrue;
}

}

#endif  // SKY_ENGINE_CORE_CSS_CSSPRIMITIVEVALUEMAPPINGS_H_
