/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
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

#include "sky/engine/core/css/parser/BisonCSSParser.h"

#include <limits.h>
#include "gen/sky/core/CSSValueKeywords.h"
#include "gen/sky/core/StylePropertyShorthand.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/css/CSSAspectRatioValue.h"
#include "sky/engine/core/css/CSSBasicShapes.h"
#include "sky/engine/core/css/CSSBorderImage.h"
#include "sky/engine/core/css/CSSCrossfadeValue.h"
#include "sky/engine/core/css/CSSFontFaceSrcValue.h"
#include "sky/engine/core/css/CSSFontFeatureValue.h"
#include "sky/engine/core/css/CSSFunctionValue.h"
#include "sky/engine/core/css/CSSGradientValue.h"
#include "sky/engine/core/css/CSSImageSetValue.h"
#include "sky/engine/core/css/CSSImageValue.h"
#include "sky/engine/core/css/CSSInheritedValue.h"
#include "sky/engine/core/css/CSSInitialValue.h"
#include "sky/engine/core/css/CSSLineBoxContainValue.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/css/CSSPropertySourceData.h"
#include "sky/engine/core/css/CSSSelector.h"
#include "sky/engine/core/css/CSSShadowValue.h"
#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/css/CSSTimingFunctionValue.h"
#include "sky/engine/core/css/CSSTransformValue.h"
#include "sky/engine/core/css/CSSUnicodeRangeValue.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/CSSValuePool.h"
#include "sky/engine/core/css/HashTools.h"
#include "sky/engine/core/css/Pair.h"
#include "sky/engine/core/css/Rect.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/css/parser/CSSParserIdioms.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/FrameConsole.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/core/rendering/RenderTheme.h"
#include "sky/engine/platform/FloatConversion.h"
#include "sky/engine/wtf/BitArray.h"
#include "sky/engine/wtf/HexNumber.h"
#include "sky/engine/wtf/text/StringBuffer.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/text/StringImpl.h"
#include "sky/engine/wtf/text/TextEncoding.h"

#define YYDEBUG 0

#if YYDEBUG > 0
extern int cssyydebug;
#endif

int cssyyparse(blink::BisonCSSParser*);

using namespace WTF;

namespace blink {

static const unsigned INVALID_NUM_PARSED_PROPERTIES = UINT_MAX;

BisonCSSParser::BisonCSSParser(const CSSParserContext& context)
    : m_context(context)
    , m_id(CSSPropertyInvalid)
    , m_styleSheet(nullptr)
    , m_supportsCondition(false)
    , m_selectorListForParseSelector(0)
    , m_numParsedPropertiesBeforeMarginBox(INVALID_NUM_PARSED_PROPERTIES)
    , m_hadSyntacticallyValidCSSRule(false)
    , m_ignoreErrors(false)
    , m_defaultNamespace(starAtom)
    , m_observer(0)
    , m_source(0)
    , m_ruleHeaderType(CSSRuleSourceData::UNKNOWN_RULE)
    , m_allowImportRules(true)
    , m_allowNamespaceDeclarations(true)
    , m_inViewport(false)
    , m_tokenizer(*this)
{
#if YYDEBUG > 0
    cssyydebug = 1;
#endif
}

BisonCSSParser::~BisonCSSParser()
{
    clearProperties();

    deleteAllValues(m_floatingSelectors);
    deleteAllValues(m_floatingSelectorVectors);
    deleteAllValues(m_floatingValueLists);
    deleteAllValues(m_floatingFunctions);
}

void BisonCSSParser::setupParser(const char* prefix, unsigned prefixLength, const String& string, const char* suffix, unsigned suffixLength)
{
    m_tokenizer.setupTokenizer(prefix, prefixLength, string, suffix, suffixLength);
    m_ruleHasHeader = true;
}

void BisonCSSParser::parseSheet(StyleSheetContents* sheet, const String& string)
{
    setStyleSheet(sheet);
    m_defaultNamespace = starAtom; // Reset the default namespace.
    m_ignoreErrors = false;
    m_tokenizer.m_lineNumber = 0;
    m_source = &string;
    m_tokenizer.m_internal = false;
    setupParser("", string, "");
    cssyyparse(this);
    sheet->shrinkToFit();
    m_source = 0;
    m_rule = nullptr;
    m_lineEndings.clear();
    m_ignoreErrors = false;
    m_tokenizer.m_internal = true;
}

PassRefPtr<StyleRuleBase> BisonCSSParser::parseRule(StyleSheetContents* sheet, const String& string)
{
    setStyleSheet(sheet);
    m_allowNamespaceDeclarations = false;
    setupParser("@-internal-rule ", string, "");
    cssyyparse(this);
    return m_rule.release();
}

bool BisonCSSParser::parseSupportsCondition(const String& string)
{
    m_supportsCondition = false;
    setupParser("@-internal-supports-condition ", string, "");
    cssyyparse(this);
    return m_supportsCondition;
}

static inline bool isColorPropertyID(CSSPropertyID propertyId)
{
    switch (propertyId) {
    case CSSPropertyColor:
    case CSSPropertyBackgroundColor:
    case CSSPropertyBorderBottomColor:
    case CSSPropertyBorderLeftColor:
    case CSSPropertyBorderRightColor:
    case CSSPropertyBorderTopColor:
    case CSSPropertyOutlineColor:
    case CSSPropertyWebkitBorderAfterColor:
    case CSSPropertyWebkitBorderBeforeColor:
    case CSSPropertyWebkitBorderEndColor:
    case CSSPropertyWebkitBorderStartColor:
    case CSSPropertyWebkitTextEmphasisColor:
    case CSSPropertyWebkitTextFillColor:
    case CSSPropertyWebkitTextStrokeColor:
    case CSSPropertyTextDecorationColor:
        return true;
    default:
        return false;
    }
}

static bool parseColorValue(MutableStylePropertySet* declaration, CSSPropertyID propertyId, const String& string, CSSParserMode cssParserMode)
{
    ASSERT(!string.isEmpty());
    bool quirksMode = isQuirksModeBehavior(cssParserMode);
    if (!isColorPropertyID(propertyId))
        return false;
    CSSParserString cssString;
    cssString.init(string);
    CSSValueID valueID = cssValueKeywordID(cssString);
    bool validPrimitive = false;
    if (valueID == CSSValueCurrentcolor)
        validPrimitive = true;

    if (validPrimitive) {
        RefPtr<CSSValue> value = cssValuePool().createIdentifierValue(valueID);
        declaration->addParsedProperty(CSSProperty(propertyId, value.release()));
        return true;
    }
    RGBA32 color;
    if (!CSSPropertyParser::fastParseColor(color, string, !quirksMode && string[0] != '#'))
        return false;
    RefPtr<CSSValue> value = cssValuePool().createColorValue(color);
    declaration->addParsedProperty(CSSProperty(propertyId, value.release()));
    return true;
}

static inline bool isSimpleLengthPropertyID(CSSPropertyID propertyId, bool& acceptsNegativeNumbers)
{
    switch (propertyId) {
    case CSSPropertyFontSize:
    case CSSPropertyHeight:
    case CSSPropertyWidth:
    case CSSPropertyMinHeight:
    case CSSPropertyMinWidth:
    case CSSPropertyPaddingBottom:
    case CSSPropertyPaddingLeft:
    case CSSPropertyPaddingRight:
    case CSSPropertyPaddingTop:
    case CSSPropertyWebkitLogicalWidth:
    case CSSPropertyWebkitLogicalHeight:
    case CSSPropertyWebkitMinLogicalWidth:
    case CSSPropertyWebkitMinLogicalHeight:
    case CSSPropertyWebkitPaddingAfter:
    case CSSPropertyWebkitPaddingBefore:
    case CSSPropertyWebkitPaddingEnd:
    case CSSPropertyWebkitPaddingStart:
        acceptsNegativeNumbers = false;
        return true;
    case CSSPropertyBottom:
    case CSSPropertyLeft:
    case CSSPropertyMarginBottom:
    case CSSPropertyMarginLeft:
    case CSSPropertyMarginRight:
    case CSSPropertyMarginTop:
    case CSSPropertyRight:
    case CSSPropertyTop:
    case CSSPropertyWebkitMarginAfter:
    case CSSPropertyWebkitMarginBefore:
    case CSSPropertyWebkitMarginEnd:
    case CSSPropertyWebkitMarginStart:
        acceptsNegativeNumbers = true;
        return true;
    default:
        return false;
    }
}

template <typename CharacterType>
static inline bool parseSimpleLength(const CharacterType* characters, unsigned length, CSSPrimitiveValue::UnitType& unit, double& number)
{
    if (length > 2 && (characters[length - 2] | 0x20) == 'p' && (characters[length - 1] | 0x20) == 'x') {
        length -= 2;
        unit = CSSPrimitiveValue::CSS_PX;
    } else if (length > 1 && characters[length - 1] == '%') {
        length -= 1;
        unit = CSSPrimitiveValue::CSS_PERCENTAGE;
    }

    // We rely on charactersToDouble for validation as well. The function
    // will set "ok" to "false" if the entire passed-in character range does
    // not represent a double.
    bool ok;
    number = charactersToDouble(characters, length, &ok);
    return ok;
}

static bool parseSimpleLengthValue(MutableStylePropertySet* declaration, CSSPropertyID propertyId, const String& string, CSSParserMode cssParserMode)
{
    ASSERT(!string.isEmpty());
    bool acceptsNegativeNumbers = false;

    // In @viewport, width and height are shorthands, not simple length values.
    if (isCSSViewportParsingEnabledForMode(cssParserMode) || !isSimpleLengthPropertyID(propertyId, acceptsNegativeNumbers))
        return false;

    unsigned length = string.length();
    double number;
    CSSPrimitiveValue::UnitType unit = CSSPrimitiveValue::CSS_NUMBER;

    if (string.is8Bit()) {
        if (!parseSimpleLength(string.characters8(), length, unit, number))
            return false;
    } else {
        if (!parseSimpleLength(string.characters16(), length, unit, number))
            return false;
    }

    if (unit == CSSPrimitiveValue::CSS_NUMBER) {
        bool quirksMode = isQuirksModeBehavior(cssParserMode);
        if (number && !quirksMode)
            return false;
        unit = CSSPrimitiveValue::CSS_PX;
    }
    if (number < 0 && !acceptsNegativeNumbers)
        return false;

    RefPtr<CSSValue> value = cssValuePool().createValue(number, unit);
    declaration->addParsedProperty(CSSProperty(propertyId, value.release()));
    return true;
}

bool isValidKeywordPropertyAndValue(CSSPropertyID propertyId, CSSValueID valueID, const CSSParserContext& parserContext)
{
    if (valueID == CSSValueInvalid)
        return false;

    switch (propertyId) {
    case CSSPropertyBackgroundRepeatX: // repeat | no-repeat
    case CSSPropertyBackgroundRepeatY: // repeat | no-repeat
        return valueID == CSSValueRepeat || valueID == CSSValueNoRepeat;
    case CSSPropertyBorderTopStyle: // <border-style>
    case CSSPropertyBorderRightStyle: // Defined as: none | hidden | dotted | dashed |
    case CSSPropertyBorderBottomStyle: // solid | double | groove | ridge | inset | outset
    case CSSPropertyBorderLeftStyle:
    case CSSPropertyWebkitBorderAfterStyle:
    case CSSPropertyWebkitBorderBeforeStyle:
    case CSSPropertyWebkitBorderEndStyle:
    case CSSPropertyWebkitBorderStartStyle:
        return valueID >= CSSValueNone && valueID <= CSSValueDouble;
    case CSSPropertyBoxSizing:
        return valueID == CSSValueBorderBox || valueID == CSSValueContentBox;
    case CSSPropertyDirection: // ltr | rtl
        return valueID == CSSValueLtr || valueID == CSSValueRtl;
    case CSSPropertyDisplay:
        // inline | block | list-item | inline-block | table |
        // inline-table | table-row-group | table-header-group | table-footer-group | table-row |
        // table-column-group | table-column | table-cell | table-caption | -webkit-box | -webkit-inline-box | none
        // flex | inline-flex
        return (valueID >= CSSValueInline && valueID <= CSSValueInlineFlex) || valueID == CSSValueNone;
    case CSSPropertyFontStyle: // normal | italic | oblique
        return valueID == CSSValueNormal || valueID == CSSValueItalic || valueID == CSSValueOblique;
    case CSSPropertyFontStretch: // normal | ultra-condensed | extra-condensed | condensed | semi-condensed | semi-expanded | expanded | extra-expanded | ultra-expanded
        return valueID == CSSValueNormal || (valueID >= CSSValueUltraCondensed && valueID <= CSSValueUltraExpanded);
    case CSSPropertyImageRendering: // auto | optimizeContrast | pixelated
        return valueID == CSSValueAuto || valueID == CSSValueWebkitOptimizeContrast || (RuntimeEnabledFeatures::imageRenderingPixelatedEnabled() && valueID == CSSValuePixelated);
    case CSSPropertyObjectFit:
        ASSERT(RuntimeEnabledFeatures::objectFitPositionEnabled());
        return valueID == CSSValueFill || valueID == CSSValueContain || valueID == CSSValueCover || valueID == CSSValueNone || valueID == CSSValueScaleDown;
    case CSSPropertyOutlineStyle: // (<border-style> except hidden) | auto
        return valueID == CSSValueAuto || valueID == CSSValueNone || (valueID >= CSSValueInset && valueID <= CSSValueDouble);
    case CSSPropertyOverflowWrap: // normal | break-word
    case CSSPropertyWordWrap:
        return valueID == CSSValueNormal || valueID == CSSValueBreakWord;
    case CSSPropertyOverflowX: // visible | hidden | auto | overlay
        return valueID == CSSValueVisible || valueID == CSSValueHidden || valueID == CSSValueAuto || valueID == CSSValueOverlay;
    case CSSPropertyOverflowY: // visible | hidden | auto | overlay | -webkit-paged-x | -webkit-paged-y
        return valueID == CSSValueVisible || valueID == CSSValueHidden || valueID == CSSValueAuto || valueID == CSSValueOverlay || valueID == CSSValueWebkitPagedX || valueID == CSSValueWebkitPagedY;
    case CSSPropertyPointerEvents:
        // none | visiblePainted | visibleFill | visibleStroke | visible |
        // painted | fill | stroke | auto | all | bounding-box
        return valueID == CSSValueVisible || valueID == CSSValueNone || valueID == CSSValueAll || valueID == CSSValueAuto || (valueID >= CSSValueVisiblepainted && valueID <= CSSValueBoundingBox);
    case CSSPropertyPosition: // static | absolute
        return valueID == CSSValueStatic || valueID == CSSValueAbsolute;
    case CSSPropertyTextAlignLast:
        // auto | start | end | left | right | center | justify
        ASSERT(RuntimeEnabledFeatures::css3TextEnabled());
        return (valueID >= CSSValueLeft && valueID <= CSSValueJustify) || valueID == CSSValueStart || valueID == CSSValueEnd || valueID == CSSValueAuto;
    case CSSPropertyTextDecorationStyle:
        // solid | double | dotted | dashed | wavy
        ASSERT(RuntimeEnabledFeatures::css3TextDecorationsEnabled());
        return valueID == CSSValueSolid || valueID == CSSValueDouble || valueID == CSSValueDotted || valueID == CSSValueDashed || valueID == CSSValueWavy;
    case CSSPropertyTextJustify:
        // auto | none | inter-word | distribute
        ASSERT(RuntimeEnabledFeatures::css3TextEnabled());
        return valueID == CSSValueInterWord || valueID == CSSValueDistribute || valueID == CSSValueAuto || valueID == CSSValueNone;
    case CSSPropertyTextOverflow: // clip | ellipsis
        return valueID == CSSValueClip || valueID == CSSValueEllipsis;
    case CSSPropertyTextRendering: // auto | optimizeSpeed | optimizeLegibility | geometricPrecision
        return valueID == CSSValueAuto || valueID == CSSValueOptimizespeed || valueID == CSSValueOptimizelegibility || valueID == CSSValueGeometricprecision;
    case CSSPropertyUnicodeBidi:
        return valueID == CSSValueNormal || valueID == CSSValueEmbed
            || valueID == CSSValueBidiOverride || valueID == CSSValueWebkitIsolate
            || valueID == CSSValueWebkitIsolateOverride || valueID == CSSValueWebkitPlaintext;
    case CSSPropertyTouchActionDelay: // none | script
        ASSERT(RuntimeEnabledFeatures::cssTouchActionDelayEnabled());
        return valueID == CSSValueScript || valueID == CSSValueNone;
    case CSSPropertyWebkitBoxDecorationBreak:
        return valueID == CSSValueClone || valueID == CSSValueSlice;
    case CSSPropertyAlignContent:
        // FIXME: Per CSS alignment, this property should accept an optional <overflow-position>. We should share this parsing code with 'justify-self'.
        return valueID == CSSValueFlexStart || valueID == CSSValueFlexEnd || valueID == CSSValueCenter || valueID == CSSValueSpaceBetween || valueID == CSSValueSpaceAround || valueID == CSSValueStretch;
    case CSSPropertyAlignItems:
        // FIXME: Per CSS alignment, this property should accept the same arguments as 'justify-self' so we should share its parsing code.
        return valueID == CSSValueFlexStart || valueID == CSSValueFlexEnd || valueID == CSSValueCenter || valueID == CSSValueBaseline || valueID == CSSValueStretch;
    case CSSPropertyAlignSelf:
        // FIXME: Per CSS alignment, this property should accept the same arguments as 'justify-self' so we should share its parsing code.
        return valueID == CSSValueAuto || valueID == CSSValueFlexStart || valueID == CSSValueFlexEnd || valueID == CSSValueCenter || valueID == CSSValueBaseline || valueID == CSSValueStretch;
    case CSSPropertyFlexDirection:
        return valueID == CSSValueRow || valueID == CSSValueRowReverse || valueID == CSSValueColumn || valueID == CSSValueColumnReverse;
    case CSSPropertyFlexWrap:
        return valueID == CSSValueNowrap || valueID == CSSValueWrap || valueID == CSSValueWrapReverse;
    case CSSPropertyJustifyContent:
        // FIXME: Per CSS alignment, this property should accept an optional <overflow-position>. We should share this parsing code with 'justify-self'.
        return valueID == CSSValueFlexStart || valueID == CSSValueFlexEnd || valueID == CSSValueCenter || valueID == CSSValueSpaceBetween || valueID == CSSValueSpaceAround;
    case CSSPropertyFontKerning:
        return valueID == CSSValueAuto || valueID == CSSValueNormal || valueID == CSSValueNone;
    case CSSPropertyWebkitFontSmoothing:
        return valueID == CSSValueAuto || valueID == CSSValueNone || valueID == CSSValueAntialiased || valueID == CSSValueSubpixelAntialiased;
    case CSSPropertyWebkitLineBreak: // auto | loose | normal | strict | after-white-space
        return valueID == CSSValueAuto || valueID == CSSValueLoose || valueID == CSSValueNormal || valueID == CSSValueStrict || valueID == CSSValueAfterWhiteSpace;
    case CSSPropertyWebkitRtlOrdering:
        return valueID == CSSValueLogical || valueID == CSSValueVisual;
    case CSSPropertyWebkitTextEmphasisPosition:
        return valueID == CSSValueOver || valueID == CSSValueUnder;
    case CSSPropertyTransformStyle:
    case CSSPropertyWebkitTransformStyle:
        return valueID == CSSValueFlat || valueID == CSSValuePreserve3d;
    case CSSPropertyWebkitUserModify: // read-only | read-write
        return valueID == CSSValueReadOnly || valueID == CSSValueReadWrite || valueID == CSSValueReadWritePlaintextOnly;
    case CSSPropertyWebkitUserSelect: // auto | none | text | all
        return valueID == CSSValueAuto || valueID == CSSValueNone || valueID == CSSValueText || valueID == CSSValueAll;
    case CSSPropertyWhiteSpace: // normal | pre | nowrap
        return valueID == CSSValueNormal || valueID == CSSValuePre || valueID == CSSValuePreWrap || valueID == CSSValuePreLine || valueID == CSSValueNowrap;
    case CSSPropertyWordBreak: // normal | break-all | break-word (this is a custom extension)
        return valueID == CSSValueNormal || valueID == CSSValueBreakAll || valueID == CSSValueBreakWord;
    default:
        ASSERT_NOT_REACHED();
        return false;
    }
    return false;
}

bool isKeywordPropertyID(CSSPropertyID propertyId)
{
    switch (propertyId) {
    case CSSPropertyAlignItems:
    case CSSPropertyAlignSelf:
    case CSSPropertyBackgroundRepeatX:
    case CSSPropertyBackgroundRepeatY:
    case CSSPropertyBorderBottomStyle:
    case CSSPropertyBorderLeftStyle:
    case CSSPropertyBorderRightStyle:
    case CSSPropertyBorderTopStyle:
    case CSSPropertyBoxSizing:
    case CSSPropertyDirection:
    case CSSPropertyDisplay:
    case CSSPropertyFontStyle:
    case CSSPropertyFontStretch:
    case CSSPropertyImageRendering:
    case CSSPropertyObjectFit:
    case CSSPropertyOutlineStyle:
    case CSSPropertyOverflowWrap:
    case CSSPropertyOverflowX:
    case CSSPropertyOverflowY:
    case CSSPropertyPointerEvents:
    case CSSPropertyPosition:
    case CSSPropertyTextAlignLast:
    case CSSPropertyTextDecorationStyle:
    case CSSPropertyTextJustify:
    case CSSPropertyTextOverflow:
    case CSSPropertyTextRendering:
    case CSSPropertyTouchActionDelay:
    case CSSPropertyUnicodeBidi:
    case CSSPropertyWebkitBorderAfterStyle:
    case CSSPropertyWebkitBorderBeforeStyle:
    case CSSPropertyWebkitBorderEndStyle:
    case CSSPropertyWebkitBorderStartStyle:
    case CSSPropertyWebkitBoxDecorationBreak:
    case CSSPropertyAlignContent:
    case CSSPropertyFlexDirection:
    case CSSPropertyFlexWrap:
    case CSSPropertyJustifyContent:
    case CSSPropertyFontKerning:
    case CSSPropertyWebkitFontSmoothing:
    case CSSPropertyWebkitLineBreak:
    case CSSPropertyWebkitRtlOrdering:
    case CSSPropertyWebkitTextEmphasisPosition:
    case CSSPropertyTransformStyle:
    case CSSPropertyWebkitTransformStyle:
    case CSSPropertyWebkitUserModify:
    case CSSPropertyWebkitUserSelect:
    case CSSPropertyWhiteSpace:
    case CSSPropertyWordBreak:
    case CSSPropertyWordWrap:
        return true;
    default:
        return false;
    }
}

static bool parseKeywordValue(MutableStylePropertySet* declaration, CSSPropertyID propertyId, const String& string, const CSSParserContext& parserContext)
{
    ASSERT(!string.isEmpty());

    if (!isKeywordPropertyID(propertyId)) {
        // All properties accept the values of "initial" and "inherit".
        String lowerCaseString = string.lower();
        if (lowerCaseString != "initial" && lowerCaseString != "inherit")
            return false;

        // Parse initial/inherit shorthands using the BisonCSSParser.
        if (shorthandForProperty(propertyId).length())
            return false;
    }

    CSSParserString cssString;
    cssString.init(string);
    CSSValueID valueID = cssValueKeywordID(cssString);

    if (!valueID)
        return false;

    RefPtr<CSSValue> value = nullptr;
    if (valueID == CSSValueInherit)
        value = cssValuePool().createInheritedValue();
    else if (valueID == CSSValueInitial)
        value = cssValuePool().createExplicitInitialValue();
    else if (isValidKeywordPropertyAndValue(propertyId, valueID, parserContext))
        value = cssValuePool().createIdentifierValue(valueID);
    else
        return false;

    declaration->addParsedProperty(CSSProperty(propertyId, value.release()));
    return true;
}

template <typename CharType>
static bool parseTransformTranslateArguments(CharType*& pos, CharType* end, unsigned expectedCount, CSSTransformValue* transformValue)
{
    while (expectedCount) {
        size_t delimiter = WTF::find(pos, end - pos, expectedCount == 1 ? ')' : ',');
        if (delimiter == kNotFound)
            return false;
        unsigned argumentLength = static_cast<unsigned>(delimiter);
        CSSPrimitiveValue::UnitType unit = CSSPrimitiveValue::CSS_NUMBER;
        double number;
        if (!parseSimpleLength(pos, argumentLength, unit, number))
            return false;
        if (unit != CSSPrimitiveValue::CSS_PX && (number || unit != CSSPrimitiveValue::CSS_NUMBER))
            return false;
        transformValue->append(cssValuePool().createValue(number, CSSPrimitiveValue::CSS_PX));
        pos += argumentLength + 1;
        --expectedCount;
    }
    return true;
}

template <typename CharType>
static bool parseTransformNumberArguments(CharType*& pos, CharType* end, unsigned expectedCount, CSSTransformValue* transformValue)
{
    while (expectedCount) {
        size_t delimiter = WTF::find(pos, end - pos, expectedCount == 1 ? ')' : ',');
        if (delimiter == kNotFound)
            return false;
        unsigned argumentLength = static_cast<unsigned>(delimiter);
        bool ok;
        double number = charactersToDouble(pos, argumentLength, &ok);
        if (!ok)
            return false;
        transformValue->append(cssValuePool().createValue(number, CSSPrimitiveValue::CSS_NUMBER));
        pos += argumentLength + 1;
        --expectedCount;
    }
    return true;
}

template <typename CharType>
static PassRefPtr<CSSTransformValue> parseSimpleTransformValue(CharType*& pos, CharType* end)
{
    static const int shortestValidTransformStringLength = 12;

    if (end - pos < shortestValidTransformStringLength)
        return nullptr;

    const bool isTranslate = toASCIILower(pos[0]) == 't'
        && toASCIILower(pos[1]) == 'r'
        && toASCIILower(pos[2]) == 'a'
        && toASCIILower(pos[3]) == 'n'
        && toASCIILower(pos[4]) == 's'
        && toASCIILower(pos[5]) == 'l'
        && toASCIILower(pos[6]) == 'a'
        && toASCIILower(pos[7]) == 't'
        && toASCIILower(pos[8]) == 'e';

    if (isTranslate) {
        CSSTransformValue::TransformOperationType transformType;
        unsigned expectedArgumentCount = 1;
        unsigned argumentStart = 11;
        CharType c9 = toASCIILower(pos[9]);
        if (c9 == 'x' && pos[10] == '(') {
            transformType = CSSTransformValue::TranslateXTransformOperation;
        } else if (c9 == 'y' && pos[10] == '(') {
            transformType = CSSTransformValue::TranslateYTransformOperation;
        } else if (c9 == 'z' && pos[10] == '(') {
            transformType = CSSTransformValue::TranslateZTransformOperation;
        } else if (c9 == '(') {
            transformType = CSSTransformValue::TranslateTransformOperation;
            expectedArgumentCount = 2;
            argumentStart = 10;
        } else if (c9 == '3' && toASCIILower(pos[10]) == 'd' && pos[11] == '(') {
            transformType = CSSTransformValue::Translate3DTransformOperation;
            expectedArgumentCount = 3;
            argumentStart = 12;
        } else {
            return nullptr;
        }
        pos += argumentStart;
        RefPtr<CSSTransformValue> transformValue = CSSTransformValue::create(transformType);
        if (!parseTransformTranslateArguments(pos, end, expectedArgumentCount, transformValue.get()))
            return nullptr;
        return transformValue.release();
    }

    const bool isMatrix3d = toASCIILower(pos[0]) == 'm'
        && toASCIILower(pos[1]) == 'a'
        && toASCIILower(pos[2]) == 't'
        && toASCIILower(pos[3]) == 'r'
        && toASCIILower(pos[4]) == 'i'
        && toASCIILower(pos[5]) == 'x'
        && pos[6] == '3'
        && toASCIILower(pos[7]) == 'd'
        && pos[8] == '(';

    if (isMatrix3d) {
        pos += 9;
        RefPtr<CSSTransformValue> transformValue = CSSTransformValue::create(CSSTransformValue::Matrix3DTransformOperation);
        if (!parseTransformNumberArguments(pos, end, 16, transformValue.get()))
            return nullptr;
        return transformValue.release();
    }

    const bool isScale3d = toASCIILower(pos[0]) == 's'
        && toASCIILower(pos[1]) == 'c'
        && toASCIILower(pos[2]) == 'a'
        && toASCIILower(pos[3]) == 'l'
        && toASCIILower(pos[4]) == 'e'
        && pos[5] == '3'
        && toASCIILower(pos[6]) == 'd'
        && pos[7] == '(';

    if (isScale3d) {
        pos += 8;
        RefPtr<CSSTransformValue> transformValue = CSSTransformValue::create(CSSTransformValue::Scale3DTransformOperation);
        if (!parseTransformNumberArguments(pos, end, 3, transformValue.get()))
            return nullptr;
        return transformValue.release();
    }

    return nullptr;
}

template <typename CharType>
static PassRefPtr<CSSValueList> parseSimpleTransformList(CharType*& pos, CharType* end)
{
    RefPtr<CSSValueList> transformList = nullptr;
    while (pos < end) {
        while (pos < end && isCSSSpace(*pos))
            ++pos;
        RefPtr<CSSTransformValue> transformValue = parseSimpleTransformValue(pos, end);
        if (!transformValue)
            return nullptr;
        if (!transformList)
            transformList = CSSValueList::createSpaceSeparated();
        transformList->append(transformValue.release());
        if (pos < end) {
            if (isCSSSpace(*pos))
                return nullptr;
        }
    }
    return transformList.release();
}

static bool parseSimpleTransform(MutableStylePropertySet* properties, CSSPropertyID propertyID, const String& string)
{
    if (propertyID != CSSPropertyTransform && propertyID != CSSPropertyWebkitTransform)
        return false;
    if (string.isEmpty())
        return false;
    RefPtr<CSSValueList> transformList = nullptr;
    if (string.is8Bit()) {
        const LChar* pos = string.characters8();
        const LChar* end = pos + string.length();
        transformList = parseSimpleTransformList(pos, end);
        if (!transformList)
            return false;
    } else {
        const UChar* pos = string.characters16();
        const UChar* end = pos + string.length();
        transformList = parseSimpleTransformList(pos, end);
        if (!transformList)
            return false;
    }
    properties->addParsedProperty(CSSProperty(propertyID, transformList.release()));
    return true;
}

PassRefPtr<CSSValueList> BisonCSSParser::parseFontFaceValue(const AtomicString& string)
{
    if (string.isEmpty())
        return nullptr;
    RefPtr<MutableStylePropertySet> dummyStyle = MutableStylePropertySet::create();
    if (!parseValue(dummyStyle.get(), CSSPropertyFontFamily, string, HTMLStandardMode, 0))
        return nullptr;

    RefPtr<CSSValue> fontFamily = dummyStyle->getPropertyCSSValue(CSSPropertyFontFamily);
    if (!fontFamily->isValueList())
        return nullptr;

    return toCSSValueList(dummyStyle->getPropertyCSSValue(CSSPropertyFontFamily).get());
}

PassRefPtr<CSSValue> BisonCSSParser::parseAnimationTimingFunctionValue(const String& string)
{
    if (string.isEmpty())
        return nullptr;
    RefPtr<MutableStylePropertySet> style = MutableStylePropertySet::create();
    if (!parseValue(style.get(), CSSPropertyTransitionTimingFunction, string, HTMLStandardMode, 0))
        return nullptr;

    RefPtr<CSSValue> value = style->getPropertyCSSValue(CSSPropertyTransitionTimingFunction);
    if (!value || value->isInitialValue() || value->isInheritedValue())
        return nullptr;
    CSSValueList* valueList = toCSSValueList(value.get());
    if (valueList->length() > 1)
        return nullptr;
    return valueList->item(0);
}

bool BisonCSSParser::parseValue(MutableStylePropertySet* declaration, CSSPropertyID propertyID, const String& string, const Document& document)
{
    ASSERT(!string.isEmpty());

    CSSParserContext context(document);

    if (parseSimpleLengthValue(declaration, propertyID, string, context.mode()))
        return true;
    if (parseColorValue(declaration, propertyID, string, context.mode()))
        return true;
    if (parseKeywordValue(declaration, propertyID, string, context))
        return true;

    BisonCSSParser parser(context);
    return parser.parseValue(declaration, propertyID, string, static_cast<StyleSheetContents*>(0));
}

bool BisonCSSParser::parseValue(MutableStylePropertySet* declaration, CSSPropertyID propertyID, const String& string, CSSParserMode cssParserMode, StyleSheetContents* contextStyleSheet)
{
    ASSERT(!string.isEmpty());
    if (parseSimpleLengthValue(declaration, propertyID, string, cssParserMode))
        return true;
    if (parseColorValue(declaration, propertyID, string, cssParserMode))
        return true;

    CSSParserContext context;
    if (contextStyleSheet)
        context = contextStyleSheet->parserContext();

    if (parseKeywordValue(declaration, propertyID, string, context))
        return true;
    if (parseSimpleTransform(declaration, propertyID, string))
        return true;

    BisonCSSParser parser(context);
    return parser.parseValue(declaration, propertyID, string, contextStyleSheet);
}

bool BisonCSSParser::parseValue(MutableStylePropertySet* declaration, CSSPropertyID propertyID, const String& string, StyleSheetContents* contextStyleSheet)
{
    setStyleSheet(contextStyleSheet);

    setupParser("@-internal-value ", string, "");

    m_id = propertyID;

    cssyyparse(this);

    m_rule = nullptr;
    m_id = CSSPropertyInvalid;

    bool ok = false;
    if (!m_parsedProperties.isEmpty()) {
        ok = true;
        declaration->addParsedProperties(m_parsedProperties);
        clearProperties();
    }

    return ok;
}

// The color will only be changed when string contains a valid CSS color, so callers
// can set it to a default color and ignore the boolean result.
bool BisonCSSParser::parseColor(RGBA32& color, const String& string, bool strict)
{
    // First try creating a color specified by name, rgba(), rgb() or "#" syntax.
    if (CSSPropertyParser::fastParseColor(color, string, strict))
        return true;

    BisonCSSParser parser(strictCSSParserContext());

    // In case the fast-path parser didn't understand the color, try the full parser.
    if (!parser.parseColor(string))
        return false;

    CSSValue* value = parser.m_parsedProperties.first().value();
    if (!value->isPrimitiveValue())
        return false;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (!primitiveValue->isRGBColor())
        return false;

    color = primitiveValue->getRGBA32Value();
    return true;
}

StyleColor BisonCSSParser::colorFromRGBColorString(const String& colorString)
{
    // FIXME: Rework css parser so it is more SVG aware.
    RGBA32 color;
    if (parseColor(color, colorString.stripWhiteSpace()))
        return StyleColor(color);
    // FIXME: This branch catches the string currentColor, but we should error if we have an illegal color value.
    return StyleColor::currentColor();
}

bool BisonCSSParser::parseColor(const String& string)
{
    setupParser("@-internal-decls color:", string, "");
    cssyyparse(this);
    m_rule = nullptr;

    return !m_parsedProperties.isEmpty() && m_parsedProperties.first().id() == CSSPropertyColor;
}

bool BisonCSSParser::parseSystemColor(RGBA32& color, const String& string)
{
    CSSParserString cssColor;
    cssColor.init(string);
    CSSValueID id = cssValueKeywordID(cssColor);
    if (!CSSPropertyParser::isSystemColor(id))
        return false;

    Color parsedColor = RenderTheme::theme().systemColor(id);
    color = parsedColor.rgb();
    return true;
}

void BisonCSSParser::parseSelector(const String& string, CSSSelectorList& selectorList)
{
    m_selectorListForParseSelector = &selectorList;

    setupParser("@-internal-selector ", string, "");

    cssyyparse(this);

    m_selectorListForParseSelector = 0;
}

PassRefPtr<ImmutableStylePropertySet> BisonCSSParser::parseInlineStyleDeclaration(const String& string, Element* element)
{
    Document& document = element->document();
    CSSParserContext context = CSSParserContext(document.elementSheet().contents()->parserContext());
    return BisonCSSParser(context).parseDeclaration(string, document.elementSheet().contents());
}

PassRefPtr<ImmutableStylePropertySet> BisonCSSParser::parseDeclaration(const String& string, StyleSheetContents* contextStyleSheet)
{
    setStyleSheet(contextStyleSheet);

    setupParser("@-internal-decls ", string, "");
    cssyyparse(this);
    m_rule = nullptr;

    RefPtr<ImmutableStylePropertySet> style = createStylePropertySet();
    clearProperties();
    return style.release();
}


bool BisonCSSParser::parseDeclaration(MutableStylePropertySet* declaration, const String& string, CSSParserObserver* observer, StyleSheetContents* contextStyleSheet)
{
    setStyleSheet(contextStyleSheet);

    TemporaryChange<CSSParserObserver*> scopedObsever(m_observer, observer);

    setupParser("@-internal-decls ", string, "");
    if (m_observer) {
        m_observer->startRuleHeader(CSSRuleSourceData::STYLE_RULE, 0);
        m_observer->endRuleHeader(1);
        m_observer->startRuleBody(0);
    }

    cssyyparse(this);

    m_rule = nullptr;

    bool ok = false;
    if (!m_parsedProperties.isEmpty()) {
        ok = true;
        declaration->addParsedProperties(m_parsedProperties);
        clearProperties();
    }

    if (m_observer)
        m_observer->endRuleBody(string.length(), false);

    return ok;
}

bool BisonCSSParser::parseAttributeMatchType(CSSSelector::AttributeMatchType& matchType, const String& string)
{
    if (!RuntimeEnabledFeatures::cssAttributeCaseSensitivityEnabled() && !isUASheetBehavior(m_context.mode()))
        return false;
    if (string == "i") {
        matchType = CSSSelector::CaseInsensitive;
        return true;
    }
    return false;
}

static inline void filterProperties(const Vector<CSSProperty, 256>& input, Vector<CSSProperty, 256>& output, size_t& unusedEntries, BitArray<numCSSProperties>& seenProperties)
{
    // Add properties in reverse order so that highest priority definitions are reached first. Duplicate definitions can then be ignored when found.
    for (int i = input.size() - 1; i >= 0; --i) {
        const CSSProperty& property = input[i];
        const unsigned propertyIDIndex = property.id() - firstCSSProperty;
        if (seenProperties.get(propertyIDIndex))
            continue;
        seenProperties.set(propertyIDIndex);
        output[--unusedEntries] = property;
    }
}

PassRefPtr<ImmutableStylePropertySet> BisonCSSParser::createStylePropertySet()
{
    BitArray<numCSSProperties> seenProperties;
    size_t unusedEntries = m_parsedProperties.size();
    Vector<CSSProperty, 256> results(unusedEntries);

    filterProperties(m_parsedProperties, results, unusedEntries, seenProperties);
    if (unusedEntries)
        results.remove(0, unusedEntries);

    return ImmutableStylePropertySet::create(results.data(), results.size(), HTMLStandardMode);
}

void BisonCSSParser::rollbackLastProperties(int num)
{
    ASSERT(num >= 0);
    ASSERT(m_parsedProperties.size() >= static_cast<unsigned>(num));
    m_parsedProperties.shrink(m_parsedProperties.size() - num);
}

void BisonCSSParser::clearProperties()
{
    m_parsedProperties.clear();
    m_numParsedPropertiesBeforeMarginBox = INVALID_NUM_PARSED_PROPERTIES;
}

void BisonCSSParser::setCurrentProperty(CSSPropertyID propId)
{
    m_id = propId;
}

bool BisonCSSParser::parseValue(CSSPropertyID propId)
{
    return CSSPropertyParser::parseValue(propId, m_valueList.get(), m_context, m_inViewport, m_parsedProperties, m_ruleHeaderType);
}


class TransformOperationInfo {
public:
    TransformOperationInfo(const CSSParserString& name)
        : m_type(CSSTransformValue::UnknownTransformOperation)
        , m_argCount(1)
        , m_allowSingleArgument(false)
        , m_unit(CSSPropertyParser::FUnknown)
    {
        const UChar* characters;
        unsigned nameLength = name.length();

        const unsigned longestNameLength = 12;
        UChar characterBuffer[longestNameLength];
        if (name.is8Bit()) {
            unsigned length = std::min(longestNameLength, nameLength);
            const LChar* characters8 = name.characters8();
            for (unsigned i = 0; i < length; ++i)
                characterBuffer[i] = characters8[i];
            characters = characterBuffer;
        } else
            characters = name.characters16();

        SWITCH(characters, nameLength) {
            CASE("skew(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::SkewTransformOperation;
                m_allowSingleArgument = true;
                m_argCount = 3;
            }
            CASE("scale(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::ScaleTransformOperation;
                m_allowSingleArgument = true;
                m_argCount = 3;
            }
            CASE("skewx(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::SkewXTransformOperation;
            }
            CASE("skewy(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::SkewYTransformOperation;
            }
            CASE("matrix(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::MatrixTransformOperation;
                m_argCount = 11;
            }
            CASE("rotate(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::RotateTransformOperation;
            }
            CASE("scalex(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::ScaleXTransformOperation;
            }
            CASE("scaley(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::ScaleYTransformOperation;
            }
            CASE("scalez(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::ScaleZTransformOperation;
            }
            CASE("scale3d(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::Scale3DTransformOperation;
                m_argCount = 5;
            }
            CASE("rotatex(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::RotateXTransformOperation;
            }
            CASE("rotatey(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::RotateYTransformOperation;
            }
            CASE("rotatez(") {
                m_unit = CSSPropertyParser::FAngle;
                m_type = CSSTransformValue::RotateZTransformOperation;
            }
            CASE("matrix3d(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::Matrix3DTransformOperation;
                m_argCount = 31;
            }
            CASE("rotate3d(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::Rotate3DTransformOperation;
                m_argCount = 7;
            }
            CASE("translate(") {
                m_unit = CSSPropertyParser::FLength | CSSPropertyParser::FPercent;
                m_type = CSSTransformValue::TranslateTransformOperation;
                m_allowSingleArgument = true;
                m_argCount = 3;
            }
            CASE("translatex(") {
                m_unit = CSSPropertyParser::FLength | CSSPropertyParser::FPercent;
                m_type = CSSTransformValue::TranslateXTransformOperation;
            }
            CASE("translatey(") {
                m_unit = CSSPropertyParser::FLength | CSSPropertyParser::FPercent;
                m_type = CSSTransformValue::TranslateYTransformOperation;
            }
            CASE("translatez(") {
                m_unit = CSSPropertyParser::FLength | CSSPropertyParser::FPercent;
                m_type = CSSTransformValue::TranslateZTransformOperation;
            }
            CASE("perspective(") {
                m_unit = CSSPropertyParser::FNumber;
                m_type = CSSTransformValue::PerspectiveTransformOperation;
            }
            CASE("translate3d(") {
                m_unit = CSSPropertyParser::FLength | CSSPropertyParser::FPercent;
                m_type = CSSTransformValue::Translate3DTransformOperation;
                m_argCount = 5;
            }
        }
    }

    CSSTransformValue::TransformOperationType type() const { return m_type; }
    unsigned argCount() const { return m_argCount; }
    CSSPropertyParser::Units unit() const { return m_unit; }

    bool unknown() const { return m_type == CSSTransformValue::UnknownTransformOperation; }
    bool hasCorrectArgCount(unsigned argCount) { return m_argCount == argCount || (m_allowSingleArgument && argCount == 1); }

private:
    CSSTransformValue::TransformOperationType m_type;
    unsigned m_argCount;
    bool m_allowSingleArgument;
    CSSPropertyParser::Units m_unit;
};

PassRefPtr<CSSValueList> CSSPropertyParser::parseTransform(CSSPropertyID propId)
{
    if (!m_valueList)
        return nullptr;

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    for (CSSParserValue* value = m_valueList->current(); value; value = m_valueList->next()) {
        RefPtr<CSSValue> parsedTransformValue = parseTransformValue(propId, value);
        if (!parsedTransformValue)
            return nullptr;

        list->append(parsedTransformValue.release());
    }

    return list.release();
}

PassRefPtr<CSSValue> CSSPropertyParser::parseTransformValue(CSSPropertyID propId, CSSParserValue *value)
{
    if (value->unit != CSSParserValue::Function || !value->function)
        return nullptr;

    // Every primitive requires at least one argument.
    CSSParserValueList* args = value->function->args.get();
    if (!args)
        return nullptr;

    // See if the specified primitive is one we understand.
    TransformOperationInfo info(value->function->name);
    if (info.unknown())
        return nullptr;

    if (!info.hasCorrectArgCount(args->size()))
        return nullptr;

    // The transform is a list of functional primitives that specify transform operations.
    // We collect a list of CSSTransformValues, where each value specifies a single operation.

    // Create the new CSSTransformValue for this operation and add it to our list.
    RefPtr<CSSTransformValue> transformValue = CSSTransformValue::create(info.type());

    // Snag our values.
    CSSParserValue* a = args->current();
    unsigned argNumber = 0;
    while (a) {
        CSSPropertyParser::Units unit = info.unit();

        if (info.type() == CSSTransformValue::Rotate3DTransformOperation && argNumber == 3) {
            // 4th param of rotate3d() is an angle rather than a bare number, validate it as such
            if (!validUnit(a, FAngle, HTMLStandardMode))
                return nullptr;
        } else if (info.type() == CSSTransformValue::Translate3DTransformOperation && argNumber == 2) {
            // 3rd param of translate3d() cannot be a percentage
            if (!validUnit(a, FLength, HTMLStandardMode))
                return nullptr;
        } else if (info.type() == CSSTransformValue::TranslateZTransformOperation && !argNumber) {
            // 1st param of translateZ() cannot be a percentage
            if (!validUnit(a, FLength, HTMLStandardMode))
                return nullptr;
        } else if (info.type() == CSSTransformValue::PerspectiveTransformOperation && !argNumber) {
            // 1st param of perspective() must be a non-negative number (deprecated) or length.
            if ((propId == CSSPropertyWebkitTransform && !validUnit(a, FNumber | FLength | FNonNeg, HTMLStandardMode))
                || (propId == CSSPropertyTransform && !validUnit(a, FLength | FNonNeg, HTMLStandardMode)))
                return nullptr;
        } else if (!validUnit(a, unit, HTMLStandardMode)) {
            return nullptr;
        }

        // Add the value to the current transform operation.
        transformValue->append(createPrimitiveNumericValue(a));

        a = args->next();
        if (!a)
            break;
        if (a->unit != CSSParserValue::Operator || a->iValue != ',')
            return nullptr;
        a = args->next();

        argNumber++;
    }

    return transformValue.release();
}

void BisonCSSParser::ensureLineEndings()
{
    if (!m_lineEndings)
        m_lineEndings = lineEndings(*m_source);
}

CSSParserSelector* BisonCSSParser::createFloatingSelectorWithTagName(const QualifiedName& tagQName)
{
    CSSParserSelector* selector = new CSSParserSelector(tagQName);
    m_floatingSelectors.append(selector);
    return selector;
}

CSSParserSelector* BisonCSSParser::createFloatingSelector()
{
    CSSParserSelector* selector = new CSSParserSelector;
    m_floatingSelectors.append(selector);
    return selector;
}

PassOwnPtr<CSSParserSelector> BisonCSSParser::sinkFloatingSelector(CSSParserSelector* selector)
{
    if (selector) {
        size_t index = m_floatingSelectors.reverseFind(selector);
        ASSERT(index != kNotFound);
        m_floatingSelectors.remove(index);
    }
    return adoptPtr(selector);
}

Vector<OwnPtr<CSSParserSelector> >* BisonCSSParser::createFloatingSelectorVector()
{
    Vector<OwnPtr<CSSParserSelector> >* selectorVector = new Vector<OwnPtr<CSSParserSelector> >;
    m_floatingSelectorVectors.append(selectorVector);
    return selectorVector;
}

PassOwnPtr<Vector<OwnPtr<CSSParserSelector> > > BisonCSSParser::sinkFloatingSelectorVector(Vector<OwnPtr<CSSParserSelector> >* selectorVector)
{
    if (selectorVector) {
        size_t index = m_floatingSelectorVectors.reverseFind(selectorVector);
        ASSERT(index != kNotFound);
        m_floatingSelectorVectors.remove(index);
    }
    return adoptPtr(selectorVector);
}

CSSParserValueList* BisonCSSParser::createFloatingValueList()
{
    CSSParserValueList* list = new CSSParserValueList;
    m_floatingValueLists.append(list);
    return list;
}

PassOwnPtr<CSSParserValueList> BisonCSSParser::sinkFloatingValueList(CSSParserValueList* list)
{
    if (list) {
        size_t index = m_floatingValueLists.reverseFind(list);
        ASSERT(index != kNotFound);
        m_floatingValueLists.remove(index);
    }
    return adoptPtr(list);
}

CSSParserFunction* BisonCSSParser::createFloatingFunction()
{
    CSSParserFunction* function = new CSSParserFunction;
    m_floatingFunctions.append(function);
    return function;
}

CSSParserFunction* BisonCSSParser::createFloatingFunction(const CSSParserString& name, PassOwnPtr<CSSParserValueList> args)
{
    CSSParserFunction* function = createFloatingFunction();
    function->name = name;
    function->args = args;
    return function;
}

PassOwnPtr<CSSParserFunction> BisonCSSParser::sinkFloatingFunction(CSSParserFunction* function)
{
    if (function) {
        size_t index = m_floatingFunctions.reverseFind(function);
        ASSERT(index != kNotFound);
        m_floatingFunctions.remove(index);
    }
    return adoptPtr(function);
}

CSSParserValue& BisonCSSParser::sinkFloatingValue(CSSParserValue& value)
{
    if (value.unit == CSSParserValue::Function) {
        size_t index = m_floatingFunctions.reverseFind(value.function);
        ASSERT(index != kNotFound);
        m_floatingFunctions.remove(index);
    }
    return value;
}

StyleRuleBase* BisonCSSParser::createSupportsRule(bool conditionIsSupported, RuleList* rules)
{
    m_allowImportRules = m_allowNamespaceDeclarations = false;

    RefPtr<CSSRuleSourceData> data = popSupportsRuleData();
    RefPtr<StyleRuleSupports> rule = nullptr;
    String conditionText;
    unsigned conditionOffset = data->ruleHeaderRange.start + 9;
    unsigned conditionLength = data->ruleHeaderRange.length() - 9;

    if (m_tokenizer.is8BitSource())
        conditionText = String(m_tokenizer.m_dataStart8.get() + conditionOffset, conditionLength).stripWhiteSpace();
    else
        conditionText = String(m_tokenizer.m_dataStart16.get() + conditionOffset, conditionLength).stripWhiteSpace();

    if (rules) {
        rule = StyleRuleSupports::create(conditionText, conditionIsSupported, *rules);
    } else {
        RuleList emptyRules;
        rule = StyleRuleSupports::create(conditionText, conditionIsSupported, emptyRules);
    }

    StyleRuleSupports* result = rule.get();
    m_parsedRules.append(rule.release());

    return result;
}

void BisonCSSParser::markSupportsRuleHeaderStart()
{
    if (!m_supportsRuleDataStack)
        m_supportsRuleDataStack = adoptPtr(new RuleSourceDataList());

    RefPtr<CSSRuleSourceData> data = CSSRuleSourceData::create(CSSRuleSourceData::SUPPORTS_RULE);
    data->ruleHeaderRange.start = m_tokenizer.tokenStartOffset();
    m_supportsRuleDataStack->append(data);
}

void BisonCSSParser::markSupportsRuleHeaderEnd()
{
    ASSERT(m_supportsRuleDataStack && !m_supportsRuleDataStack->isEmpty());

    if (m_tokenizer.is8BitSource())
        m_supportsRuleDataStack->last()->ruleHeaderRange.end = m_tokenizer.tokenStart<LChar>() - m_tokenizer.m_dataStart8.get();
    else
        m_supportsRuleDataStack->last()->ruleHeaderRange.end = m_tokenizer.tokenStart<UChar>() - m_tokenizer.m_dataStart16.get();
}

PassRefPtr<CSSRuleSourceData> BisonCSSParser::popSupportsRuleData()
{
    ASSERT(m_supportsRuleDataStack && !m_supportsRuleDataStack->isEmpty());
    RefPtr<CSSRuleSourceData> data = m_supportsRuleDataStack->last();
    m_supportsRuleDataStack->removeLast();
    return data.release();
}

BisonCSSParser::RuleList* BisonCSSParser::createRuleList()
{
    OwnPtr<RuleList> list = adoptPtr(new RuleList);
    RuleList* listPtr = list.get();

    m_parsedRuleLists.append(list.release());
    return listPtr;
}

BisonCSSParser::RuleList* BisonCSSParser::appendRule(RuleList* ruleList, StyleRuleBase* rule)
{
    if (rule) {
        if (!ruleList)
            ruleList = createRuleList();
        ruleList->append(rule);
    }
    return ruleList;
}

template <typename CharacterType>
ALWAYS_INLINE static void makeLower(const CharacterType* input, CharacterType* output, unsigned length)
{
    // FIXME: If we need Unicode lowercasing here, then we probably want the real kind
    // that can potentially change the length of the string rather than the character
    // by character kind. If we don't need Unicode lowercasing, it would be good to
    // simplify this function.

    if (charactersAreAllASCII(input, length)) {
        // Fast case for all-ASCII.
        for (unsigned i = 0; i < length; i++)
            output[i] = toASCIILower(input[i]);
    } else {
        for (unsigned i = 0; i < length; i++)
            output[i] = Unicode::toLower(input[i]);
    }
}

void BisonCSSParser::tokenToLowerCase(CSSParserString& token)
{
    // Since it's our internal token, we know that we created it out
    // of our writable work buffers. Therefore the const_cast is just
    // ugly and not a potential crash.
    size_t length = token.length();
    if (token.is8Bit()) {
        makeLower(token.characters8(), const_cast<LChar*>(token.characters8()), length);
    } else {
        makeLower(token.characters16(), const_cast<UChar*>(token.characters16()), length);
    }
}

void BisonCSSParser::endInvalidRuleHeader()
{
    if (m_ruleHeaderType == CSSRuleSourceData::UNKNOWN_RULE)
        return;

    CSSParserLocation location;
    location.lineNumber = m_tokenizer.m_lineNumber;
    location.offset = m_ruleHeaderStartOffset;
    if (m_tokenizer.is8BitSource())
        location.token.init(m_tokenizer.m_dataStart8.get() + m_ruleHeaderStartOffset, 0);
    else
        location.token.init(m_tokenizer.m_dataStart16.get() + m_ruleHeaderStartOffset, 0);

    reportError(location, m_ruleHeaderType == CSSRuleSourceData::STYLE_RULE ? InvalidSelectorCSSError : InvalidRuleCSSError);

    endRuleHeader();
}

StyleRuleBase* BisonCSSParser::createStyleRule(Vector<OwnPtr<CSSParserSelector> >* selectors)
{
    StyleRule* result = 0;
    if (selectors) {
        m_allowImportRules = m_allowNamespaceDeclarations = false;
        RefPtr<StyleRule> rule = StyleRule::create();
        rule->parserAdoptSelectorVector(*selectors);
        rule->setProperties(createStylePropertySet());
        result = rule.get();
        m_parsedRules.append(rule.release());
    }
    clearProperties();
    return result;
}

StyleRuleBase* BisonCSSParser::createFontFaceRule()
{
    m_allowImportRules = m_allowNamespaceDeclarations = false;
    for (unsigned i = 0; i < m_parsedProperties.size(); ++i) {
        CSSProperty& property = m_parsedProperties[i];
        if (property.id() == CSSPropertyFontVariant && property.value()->isPrimitiveValue())
            property.wrapValueInCommaSeparatedList();
        else if (property.id() == CSSPropertyFontFamily && (!property.value()->isValueList() || toCSSValueList(property.value())->length() != 1)) {
            // Unlike font-family property, font-family descriptor in @font-face rule
            // has to be a value list with exactly one family name. It cannot have a
            // have 'initial' value and cannot 'inherit' from parent.
            // See http://dev.w3.org/csswg/css3-fonts/#font-family-desc
            clearProperties();
            return 0;
        }
    }
    RefPtr<StyleRuleFontFace> rule = StyleRuleFontFace::create();
    rule->setProperties(createStylePropertySet());
    clearProperties();
    StyleRuleFontFace* result = rule.get();
    m_parsedRules.append(rule.release());
    return result;
}

CSSParserSelector* BisonCSSParser::rewriteSpecifiersWithNamespaceIfNeeded(CSSParserSelector* specifiers)
{
    if (m_defaultNamespace != starAtom)
        return rewriteSpecifiersWithElementName(nullAtom, starAtom, specifiers, /*tagIsForNamespaceRule*/true);
    return specifiers;
}

CSSParserSelector* BisonCSSParser::rewriteSpecifiersWithElementName(const AtomicString& namespacePrefix, const AtomicString& elementName, CSSParserSelector* specifiers, bool tagIsForNamespaceRule)
{
    QualifiedName tag(elementName);

    // *:host never matches, so we can't discard the * otherwise we can't tell the
    // difference between *:host and just :host.
    if (tag == anyName && !specifiers->hasHostPseudoSelector())
        return specifiers;
    specifiers->prependTagSelector(tag, tagIsForNamespaceRule);
    return specifiers;
}

CSSParserSelector* BisonCSSParser::rewriteSpecifiers(CSSParserSelector* specifiers, CSSParserSelector* newSpecifier)
{
    specifiers->appendTagHistory(sinkFloatingSelector(newSpecifier));
    return specifiers;
}

void BisonCSSParser::startDeclarationsForMarginBox()
{
    m_numParsedPropertiesBeforeMarginBox = m_parsedProperties.size();
}

void BisonCSSParser::endDeclarationsForMarginBox()
{
    rollbackLastProperties(m_parsedProperties.size() - m_numParsedPropertiesBeforeMarginBox);
    m_numParsedPropertiesBeforeMarginBox = INVALID_NUM_PARSED_PROPERTIES;
}

void BisonCSSParser::startRule()
{
    if (!m_observer)
        return;

    ASSERT(m_ruleHasHeader);
    m_ruleHasHeader = false;
}

void BisonCSSParser::endRule(bool valid)
{
    if (!m_observer)
        return;

    if (m_ruleHasHeader)
        m_observer->endRuleBody(m_tokenizer.safeUserStringTokenOffset(), !valid);
    m_ruleHasHeader = true;
}

void BisonCSSParser::startRuleHeader(CSSRuleSourceData::Type ruleType)
{
    m_ruleHeaderType = ruleType;
    m_ruleHeaderStartOffset = m_tokenizer.safeUserStringTokenOffset();
    m_ruleHeaderStartLineNumber = m_tokenizer.m_tokenStartLineNumber;
    if (m_observer) {
        ASSERT(!m_ruleHasHeader);
        m_observer->startRuleHeader(ruleType, m_ruleHeaderStartOffset);
        m_ruleHasHeader = true;
    }
}

void BisonCSSParser::endRuleHeader()
{
    ASSERT(m_ruleHeaderType != CSSRuleSourceData::UNKNOWN_RULE);
    m_ruleHeaderType = CSSRuleSourceData::UNKNOWN_RULE;
    if (m_observer) {
        ASSERT(m_ruleHasHeader);
        m_observer->endRuleHeader(m_tokenizer.safeUserStringTokenOffset());
    }
}

void BisonCSSParser::startSelector()
{
    if (m_observer)
        m_observer->startSelector(m_tokenizer.safeUserStringTokenOffset());
}

void BisonCSSParser::endSelector()
{
    if (m_observer)
        m_observer->endSelector(m_tokenizer.safeUserStringTokenOffset());
}

void BisonCSSParser::startRuleBody()
{
    if (m_observer)
        m_observer->startRuleBody(m_tokenizer.safeUserStringTokenOffset());
}

void BisonCSSParser::startProperty()
{
    if (m_observer)
        m_observer->startProperty(m_tokenizer.safeUserStringTokenOffset());
}

void BisonCSSParser::endProperty(bool isPropertyParsed, CSSParserError errorType)
{
    m_id = CSSPropertyInvalid;
    if (m_observer)
        m_observer->endProperty(isPropertyParsed, m_tokenizer.safeUserStringTokenOffset(), errorType);
}

void BisonCSSParser::startEndUnknownRule()
{
    if (m_observer)
        m_observer->startEndUnknownRule();
}

}
