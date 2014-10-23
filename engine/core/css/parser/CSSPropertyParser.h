/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 - 2010  Torch Mobile (Beijing) Co. Ltd. All rights reserved.
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

#ifndef CSSPropertyParser_h
#define CSSPropertyParser_h

// FIXME: Way too many.
#include "core/CSSPropertyNames.h"
#include "core/CSSValueKeywords.h"
#include "core/css/CSSCalculationValue.h"
#include "core/css/CSSFilterValue.h"
#include "core/css/CSSGradientValue.h"
#include "core/css/CSSGridTemplateAreasValue.h"
#include "core/css/CSSProperty.h"
#include "core/css/CSSPropertySourceData.h"
#include "core/css/CSSSelector.h"
#include "core/css/parser/CSSParserMode.h"
#include "core/css/parser/CSSParserValues.h"
#include "platform/graphics/Color.h"
#include "wtf/OwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class CSSBorderImageSliceValue;
class CSSPrimitiveValue;
class CSSValue;
class CSSValueList;
class CSSBasicShape;
class CSSBasicShapeInset;
class CSSGridLineNamesValue;
class ImmutableStylePropertySet;
class StylePropertyShorthand;
class UseCounter;

// Inputs: PropertyID, isImportant bool, CSSParserValueList.
// Outputs: Vector of CSSProperties

class CSSPropertyParser {
    STACK_ALLOCATED();
public:
    static bool parseValue(CSSPropertyID, bool important,
        CSSParserValueList*, const CSSParserContext&, bool inViewport,
        WillBeHeapVector<CSSProperty, 256>&, CSSRuleSourceData::Type);

    // FIXME: Should this be on a separate ColorParser object?
    template<typename StringType>
    static bool fastParseColor(RGBA32&, const StringType&, bool strict);

    static bool isSystemColor(int id);

private:
    CSSPropertyParser(CSSParserValueList*, const CSSParserContext&, bool inViewport,
        WillBeHeapVector<CSSProperty, 256>&, CSSRuleSourceData::Type);

    bool parseValue(CSSPropertyID, bool important);

    bool inShorthand() const { return m_inParseShorthand; }
    bool inQuirksMode() const { return isQuirksModeBehavior(m_context.mode()); }

    bool inViewport() const { return m_inViewport; }
    bool parseViewportProperty(CSSPropertyID propId, bool important);
    bool parseViewportShorthand(CSSPropertyID propId, CSSPropertyID first, CSSPropertyID second, bool important);

    KURL completeURL(const String& url) const;

    void addPropertyWithPrefixingVariant(CSSPropertyID, PassRefPtrWillBeRawPtr<CSSValue>, bool important, bool implicit = false);
    void addProperty(CSSPropertyID, PassRefPtrWillBeRawPtr<CSSValue>, bool important, bool implicit = false);
    void rollbackLastProperties(int num);
    void addExpandedPropertyForValue(CSSPropertyID propId, PassRefPtrWillBeRawPtr<CSSValue>, bool);

    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseValidPrimitive(CSSValueID ident, CSSParserValue*);

    bool parseShorthand(CSSPropertyID, const StylePropertyShorthand&, bool important);
    bool parse4Values(CSSPropertyID, const CSSPropertyID* properties, bool important);
    bool parseContent(CSSPropertyID, bool important);
    PassRefPtrWillBeRawPtr<CSSValue> parseQuotes();

    PassRefPtrWillBeRawPtr<CSSValue> parseAttr(CSSParserValueList* args);

    PassRefPtrWillBeRawPtr<CSSValue> parseBackgroundColor();

    bool parseFillImage(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&);

    enum FillPositionFlag { InvalidFillPosition = 0, AmbiguousFillPosition = 1, XFillPosition = 2, YFillPosition = 4 };
    enum FillPositionParsingMode { ResolveValuesAsPercent = 0, ResolveValuesAsKeyword = 1 };
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseFillPositionComponent(CSSParserValueList*, unsigned& cumulativeFlags, FillPositionFlag& individualFlag, FillPositionParsingMode = ResolveValuesAsPercent);
    PassRefPtrWillBeRawPtr<CSSValue> parseFillPositionX(CSSParserValueList*);
    PassRefPtrWillBeRawPtr<CSSValue> parseFillPositionY(CSSParserValueList*);
    void parse2ValuesFillPosition(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&);
    bool isPotentialPositionValue(CSSParserValue*);
    void parseFillPosition(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&);
    void parse3ValuesFillPosition(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&, PassRefPtrWillBeRawPtr<CSSPrimitiveValue>, PassRefPtrWillBeRawPtr<CSSPrimitiveValue>);
    void parse4ValuesFillPosition(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&, PassRefPtrWillBeRawPtr<CSSPrimitiveValue>, PassRefPtrWillBeRawPtr<CSSPrimitiveValue>);

    void parseFillRepeat(RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&);
    PassRefPtrWillBeRawPtr<CSSValue> parseFillSize(CSSPropertyID, bool &allowComma);

    bool parseFillProperty(CSSPropertyID propId, CSSPropertyID& propId1, CSSPropertyID& propId2, RefPtrWillBeRawPtr<CSSValue>&, RefPtrWillBeRawPtr<CSSValue>&);
    bool parseFillShorthand(CSSPropertyID, const CSSPropertyID* properties, int numProperties, bool important);

    void addFillValue(RefPtrWillBeRawPtr<CSSValue>& lval, PassRefPtrWillBeRawPtr<CSSValue> rval);

    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationDelay();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationDirection();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationDuration();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationFillMode();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationIterationCount();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationName();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationPlayState();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationProperty();
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationTimingFunction();

    bool parseWebkitTransformOriginShorthand(bool important);
    bool parseCubicBezierTimingFunctionValue(CSSParserValueList*& args, double& result);
    PassRefPtrWillBeRawPtr<CSSValue> parseAnimationProperty(CSSPropertyID);
    PassRefPtrWillBeRawPtr<CSSValueList> parseAnimationPropertyList(CSSPropertyID);
    bool parseTransitionShorthand(CSSPropertyID, bool important);
    bool parseAnimationShorthand(CSSPropertyID, bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseGridPosition();
    bool parseIntegerOrCustomIdentFromGridPosition(RefPtrWillBeRawPtr<CSSPrimitiveValue>& numericValue, RefPtrWillBeRawPtr<CSSPrimitiveValue>& gridLineName);
    bool parseGridItemPositionShorthand(CSSPropertyID, bool important);
    bool parseGridTemplateRowsAndAreas(PassRefPtrWillBeRawPtr<CSSValue>, bool important);
    bool parseGridTemplateShorthand(bool important);
    bool parseGridShorthand(bool important);
    bool parseGridAreaShorthand(bool important);
    bool parseSingleGridAreaLonghand(RefPtrWillBeRawPtr<CSSValue>&);
    PassRefPtrWillBeRawPtr<CSSValue> parseGridTrackList();
    bool parseGridTrackRepeatFunction(CSSValueList&);
    PassRefPtrWillBeRawPtr<CSSValue> parseGridTrackSize(CSSParserValueList& inputList);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseGridBreadth(CSSParserValue*);
    bool parseGridTemplateAreasRow(NamedGridAreaMap&, const size_t, size_t&);
    PassRefPtrWillBeRawPtr<CSSValue> parseGridTemplateAreas();
    void parseGridLineNames(CSSParserValueList&, CSSValueList&, CSSGridLineNamesValue* = 0);
    PassRefPtrWillBeRawPtr<CSSValue> parseGridAutoFlow(CSSParserValueList&);

    bool parseClipShape(CSSPropertyID, bool important);

    bool parseItemPositionOverflowPosition(CSSPropertyID, bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseShapeProperty(CSSPropertyID propId);
    PassRefPtrWillBeRawPtr<CSSValue> parseBasicShapeAndOrBox();
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseBasicShape();
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseShapeRadius(CSSParserValue*);

    PassRefPtrWillBeRawPtr<CSSBasicShape> parseBasicShapeCircle(CSSParserValueList* args);
    PassRefPtrWillBeRawPtr<CSSBasicShape> parseBasicShapeEllipse(CSSParserValueList* args);
    PassRefPtrWillBeRawPtr<CSSBasicShape> parseBasicShapePolygon(CSSParserValueList* args);
    PassRefPtrWillBeRawPtr<CSSBasicShape> parseBasicShapeInset(CSSParserValueList* args);

    bool parseFont(bool important);
    PassRefPtrWillBeRawPtr<CSSValueList> parseFontFamily();

    bool parseColorParameters(CSSParserValue*, int* colorValues, bool parseAlpha);
    bool parseHSLParameters(CSSParserValue*, double* colorValues, bool parseAlpha);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseColor(CSSParserValue* = 0, bool acceptQuirkyColors = false);
    bool parseColorFromValue(CSSParserValue*, RGBA32&, bool acceptQuirkyColors = false);

    bool parseLineHeight(bool important);
    bool parseFontSize(bool important);
    bool parseFontVariant(bool important);
    bool parseFontWeight(bool important);
    PassRefPtrWillBeRawPtr<CSSValueList> parseFontFaceSrc();
    PassRefPtrWillBeRawPtr<CSSValueList> parseFontFaceUnicodeRange();

    // CSS3 Parsing Routines (for properties specific to CSS3)
    PassRefPtrWillBeRawPtr<CSSValueList> parseShadow(CSSParserValueList*, CSSPropertyID);
    bool parseBorderImageShorthand(CSSPropertyID, bool important);
    PassRefPtrWillBeRawPtr<CSSValue> parseBorderImage(CSSPropertyID);
    bool parseBorderImageRepeat(RefPtrWillBeRawPtr<CSSValue>&);
    bool parseBorderImageSlice(CSSPropertyID, RefPtrWillBeRawPtr<CSSBorderImageSliceValue>&);
    bool parseBorderImageWidth(RefPtrWillBeRawPtr<CSSPrimitiveValue>&);
    bool parseBorderImageOutset(RefPtrWillBeRawPtr<CSSPrimitiveValue>&);
    bool parseBorderRadius(CSSPropertyID, bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseAspectRatio();

    bool parseFlex(CSSParserValueList* args, bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseObjectPosition();

    // Image generators
    bool parseCanvas(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&);

    bool parseLinearGradient(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, CSSGradientRepeat repeating);
    bool parseRadialGradient(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&, CSSGradientRepeat repeating);
    bool parseGradientColorStops(CSSParserValueList*, CSSGradientValue*, bool expectComma);

    bool parseCrossfade(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&);

    PassRefPtrWillBeRawPtr<CSSValue> parseImageSet(CSSParserValueList*);

    PassRefPtrWillBeRawPtr<CSSValue> parseWillChange();

    PassRefPtrWillBeRawPtr<CSSValueList> parseFilter();
    PassRefPtrWillBeRawPtr<CSSFilterValue> parseBuiltinFilterArguments(CSSParserValueList*, CSSFilterValue::FilterOperationType);

    PassRefPtrWillBeRawPtr<CSSValueList> parseTransformOrigin();
    PassRefPtrWillBeRawPtr<CSSValueList> parseTransform(CSSPropertyID);
    PassRefPtrWillBeRawPtr<CSSValue> parseTransformValue(CSSPropertyID, CSSParserValue*);

    bool parseTextEmphasisStyle(bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseTouchAction();

    void addTextDecorationProperty(CSSPropertyID, PassRefPtrWillBeRawPtr<CSSValue>, bool important);
    bool parseTextDecoration(CSSPropertyID propId, bool important);
    bool parseTextUnderlinePosition(bool important);

    PassRefPtrWillBeRawPtr<CSSValue> parseTextIndent();

    bool parseLineBoxContain(bool important);
    bool parseCalculation(CSSParserValue*, ValueRange);

    bool parseFontFeatureTag(CSSValueList*);
    bool parseFontFeatureSettings(bool important);

    bool parseFontVariantLigatures(bool important);

    bool parseGeneratedImage(CSSParserValueList*, RefPtrWillBeRawPtr<CSSValue>&);

    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createPrimitiveNumericValue(CSSParserValue*);
    PassRefPtrWillBeRawPtr<CSSPrimitiveValue> createPrimitiveStringValue(CSSParserValue*);

    PassRefPtrWillBeRawPtr<CSSValue> createCSSImageValueWithReferrer(const String& rawValue, const KURL&);

    bool validWidthOrHeight(CSSParserValue*);

    PassRefPtrWillBeRawPtr<CSSBasicShape> parseInsetRoundedCorners(PassRefPtrWillBeRawPtr<CSSBasicShapeInset>, CSSParserValueList*);

    enum SizeParameterType {
        None,
        Auto,
        Length,
        PageSize,
        Orientation,
    };

    bool parsePage(CSSPropertyID propId, bool important);
    bool parseSize(CSSPropertyID propId, bool important);
    SizeParameterType parseSizeParameter(CSSValueList* parsedValues, CSSParserValue*, SizeParameterType prevParamType);

    bool parseFontFaceSrcURI(CSSValueList*);
    bool parseFontFaceSrcLocal(CSSValueList*);

    class ImplicitScope {
        STACK_ALLOCATED();
        WTF_MAKE_NONCOPYABLE(ImplicitScope);
    public:
        ImplicitScope(CSSPropertyParser* parser)
            : m_parser(parser)
        {
            m_parser->m_implicitShorthand = true;
        }

        ~ImplicitScope()
        {
            m_parser->m_implicitShorthand = false;
        }

    private:
        CSSPropertyParser* m_parser;
    };

    class ShorthandScope {
        STACK_ALLOCATED();
    public:
        ShorthandScope(CSSPropertyParser* parser, CSSPropertyID propId) : m_parser(parser)
        {
            if (!(m_parser->m_inParseShorthand++))
                m_parser->m_currentShorthand = propId;
        }
        ~ShorthandScope()
        {
            if (!(--m_parser->m_inParseShorthand))
                m_parser->m_currentShorthand = CSSPropertyInvalid;
        }

    private:
        CSSPropertyParser* m_parser;
    };

    enum ReleaseParsedCalcValueCondition {
        ReleaseParsedCalcValue,
        DoNotReleaseParsedCalcValue
    };

    enum Units {
        FUnknown = 0x0000,
        FInteger = 0x0001,
        FNumber = 0x0002, // Real Numbers
        FPercent = 0x0004,
        FLength = 0x0008,
        FAngle = 0x0010,
        FTime = 0x0020,
        FFrequency = 0x0040,
        FPositiveInteger = 0x0080,
        FRelative = 0x0100,
        FResolution = 0x0200,
        FNonNeg = 0x0400
    };

    friend inline Units operator|(Units a, Units b)
    {
        return static_cast<Units>(static_cast<unsigned>(a) | static_cast<unsigned>(b));
    }

    bool validCalculationUnit(CSSParserValue*, Units, ReleaseParsedCalcValueCondition releaseCalc = DoNotReleaseParsedCalcValue);

    bool shouldAcceptUnitLessValues(CSSParserValue*, Units, CSSParserMode);

    inline bool validUnit(CSSParserValue* value, Units unitflags, ReleaseParsedCalcValueCondition releaseCalc = DoNotReleaseParsedCalcValue) { return validUnit(value, unitflags, m_context.mode(), releaseCalc); }
    bool validUnit(CSSParserValue*, Units, CSSParserMode, ReleaseParsedCalcValueCondition releaseCalc = DoNotReleaseParsedCalcValue);

    bool parseBorderImageQuad(Units, RefPtrWillBeRawPtr<CSSPrimitiveValue>&);
    int colorIntFromValue(CSSParserValue*);
    bool isCalculation(CSSParserValue*);

private:
    // Inputs:
    CSSParserValueList* m_valueList;
    const CSSParserContext& m_context;
    const bool m_inViewport;

    // Outputs:
    WillBeHeapVector<CSSProperty, 256>& m_parsedProperties;
    CSSRuleSourceData::Type m_ruleType;

    // Locals during parsing:
    int m_inParseShorthand;
    CSSPropertyID m_currentShorthand;
    bool m_implicitShorthand;
    RefPtrWillBeMember<CSSCalcValue> m_parsedCalculation;

    // FIXME: There is probably a small set of APIs we could expose for these
    // classes w/o needing to make them friends.
    friend class ShadowParseContext;
    friend class BorderImageParseContext;
    friend class BorderImageSliceParseContext;
    friend class BorderImageQuadParseContext;
    friend class TransformOperationInfo;
    friend PassRefPtrWillBeRawPtr<CSSPrimitiveValue> parseGradientColorOrKeyword(CSSPropertyParser*, CSSParserValue*);
};

CSSPropertyID cssPropertyID(const CSSParserString&);
CSSPropertyID cssPropertyID(const String&);
CSSValueID cssValueKeywordID(const CSSParserString&);

bool isKeywordPropertyID(CSSPropertyID);
bool isValidKeywordPropertyAndValue(CSSPropertyID, CSSValueID, const CSSParserContext&);

} // namespace blink

#endif // CSSPropertyParser_h
