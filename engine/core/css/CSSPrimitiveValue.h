/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
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

#ifndef CSSPrimitiveValue_h
#define CSSPrimitiveValue_h

#include "core/CSSPropertyNames.h"
#include "core/CSSValueKeywords.h"
#include "core/css/CSSValue.h"
#include "platform/graphics/Color.h"
#include "wtf/Forward.h"
#include "wtf/MathExtras.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class CSSBasicShape;
class CSSCalcValue;
class CSSToLengthConversionData;
class ExceptionState;
class Length;
class LengthSize;
class Pair;
class Quad;
class RGBColor;
class Rect;
class RenderStyle;

// Dimension calculations are imprecise, often resulting in values of e.g.
// 44.99998. We need to go ahead and round if we're really close to the next
// integer value.
template<typename T> inline T roundForImpreciseConversion(double value)
{
    value += (value < 0) ? -0.01 : +0.01;
    return ((value > std::numeric_limits<T>::max()) || (value < std::numeric_limits<T>::min())) ? 0 : static_cast<T>(value);
}

template<> inline float roundForImpreciseConversion(double value)
{
    double ceiledValue = ceil(value);
    double proximityToNextInt = ceiledValue - value;
    if (proximityToNextInt <= 0.01 && value > 0)
        return static_cast<float>(ceiledValue);
    if (proximityToNextInt >= 0.99 && value < 0)
        return static_cast<float>(floor(value));
    return static_cast<float>(value);
}

// CSSPrimitiveValues are immutable. This class has manual ref-counting
// of unioned types and does not have the code necessary
// to handle any kind of mutations. All DOM-exposed "setters" just throw
// exceptions.
class CSSPrimitiveValue : public CSSValue {
public:
    enum UnitType {
        CSS_UNKNOWN = 0,
        CSS_NUMBER = 1,
        CSS_PERCENTAGE = 2,
        CSS_EMS = 3,
        CSS_EXS = 4,
        CSS_PX = 5,
        CSS_CM = 6,
        CSS_MM = 7,
        CSS_IN = 8,
        CSS_PT = 9,
        CSS_PC = 10,
        CSS_DEG = 11,
        CSS_RAD = 12,
        CSS_GRAD = 13,
        CSS_MS = 14,
        CSS_S = 15,
        CSS_HZ = 16,
        CSS_KHZ = 17,
        CSS_DIMENSION = 18,
        CSS_STRING = 19,
        CSS_URI = 20,
        CSS_IDENT = 21,
        CSS_ATTR = 22,
        CSS_RECT = 24,
        CSS_RGBCOLOR = 25,
        // From CSS Values and Units. Viewport-percentage Lengths (vw/vh/vmin/vmax).
        CSS_VW = 26,
        CSS_VH = 27,
        CSS_VMIN = 28,
        CSS_VMAX = 29,
        CSS_DPPX = 30,
        CSS_DPI = 31,
        CSS_DPCM = 32,
        CSS_FR = 33,
        CSS_PAIR = 100, // We envision this being exposed as a means of getting computed style values for pairs (border-spacing/radius, background-position, etc.)
        CSS_UNICODE_RANGE = 102,

        // FIXME: This is only used in CSSParserValue, so it's probably better as part of the enum there
        CSS_PARSER_HEXCOLOR = 105,

        // These are from CSS3 Values and Units, but that isn't a finished standard yet
        CSS_TURN = 107,
        CSS_REMS = 108,
        CSS_CHS = 109,

        // This is used by the CSS Shapes draft
        CSS_SHAPE = 111,

        // Used by border images.
        CSS_QUAD = 112,

        CSS_CALC = 113,
        CSS_CALC_PERCENTAGE_WITH_NUMBER = 114,
        CSS_CALC_PERCENTAGE_WITH_LENGTH = 115,

        CSS_PROPERTY_ID = 117,
        CSS_VALUE_ID = 118
    };

    enum LengthUnitType {
        UnitTypePixels = 0,
        UnitTypePercentage,
        UnitTypeFontSize,
        UnitTypeFontXSize,
        UnitTypeRootFontSize,
        UnitTypeZeroCharacterWidth,
        UnitTypeViewportWidth,
        UnitTypeViewportHeight,
        UnitTypeViewportMin,
        UnitTypeViewportMax,

        // This value must come after the last length unit type to enable iteration over the length unit types.
        LengthUnitTypeCount,
    };

    typedef Vector<double, CSSPrimitiveValue::LengthUnitTypeCount> CSSLengthArray;
    void accumulateLengthArray(CSSLengthArray&, double multiplier = 1) const;

    // This enum follows the BisonCSSParser::Units enum augmented with UNIT_FREQUENCY for frequencies.
    enum UnitCategory {
        UNumber,
        UPercent,
        ULength,
        UAngle,
        UTime,
        UFrequency,
        UResolution,
        UOther
    };
    static UnitCategory unitCategory(UnitType);

    static UnitType fromName(const String& unit);

    bool isAngle() const
    {
        return m_primitiveUnitType == CSS_DEG
               || m_primitiveUnitType == CSS_RAD
               || m_primitiveUnitType == CSS_GRAD
               || m_primitiveUnitType == CSS_TURN;
    }
    bool isAttr() const { return m_primitiveUnitType == CSS_ATTR; }
    bool isFontIndependentLength() const { return m_primitiveUnitType >= CSS_PX && m_primitiveUnitType <= CSS_PC; }
    bool isFontRelativeLength() const
    {
        return m_primitiveUnitType == CSS_EMS
            || m_primitiveUnitType == CSS_EXS
            || m_primitiveUnitType == CSS_REMS
            || m_primitiveUnitType == CSS_CHS;
    }
    bool isViewportPercentageLength() const { return isViewportPercentageLength(static_cast<UnitType>(m_primitiveUnitType)); }
    static bool isViewportPercentageLength(UnitType type) { return type >= CSS_VW && type <= CSS_VMAX; }
    static bool isLength(UnitType type)
    {
        return (type >= CSS_EMS && type <= CSS_PC) || type == CSS_REMS || type == CSS_CHS || isViewportPercentageLength(type);
    }
    bool isLength() const { return isLength(primitiveType()); }
    bool isNumber() const { return primitiveType() == CSS_NUMBER; }
    bool isPercentage() const { return primitiveType() == CSS_PERCENTAGE; }
    bool isPx() const { return primitiveType() == CSS_PX; }
    bool isRect() const { return m_primitiveUnitType == CSS_RECT; }
    bool isRGBColor() const { return m_primitiveUnitType == CSS_RGBCOLOR; }
    bool isShape() const { return m_primitiveUnitType == CSS_SHAPE; }
    bool isString() const { return m_primitiveUnitType == CSS_STRING; }
    bool isTime() const { return m_primitiveUnitType == CSS_S || m_primitiveUnitType == CSS_MS; }
    bool isURI() const { return m_primitiveUnitType == CSS_URI; }
    bool isCalculated() const { return m_primitiveUnitType == CSS_CALC; }
    bool isCalculatedPercentageWithNumber() const { return primitiveType() == CSS_CALC_PERCENTAGE_WITH_NUMBER; }
    bool isCalculatedPercentageWithLength() const { return primitiveType() == CSS_CALC_PERCENTAGE_WITH_LENGTH; }
    static bool isDotsPerInch(UnitType type) { return type == CSS_DPI; }
    static bool isDotsPerPixel(UnitType type) { return type == CSS_DPPX; }
    static bool isDotsPerCentimeter(UnitType type) { return type == CSS_DPCM; }
    static bool isResolution(UnitType type) { return type >= CSS_DPPX && type <= CSS_DPCM; }
    bool isFlex() const { return primitiveType() == CSS_FR; }
    bool isValueID() const { return m_primitiveUnitType == CSS_VALUE_ID; }
    bool colorIsDerivedFromElement() const;

    static PassRefPtr<CSSPrimitiveValue> createIdentifier(CSSValueID valueID)
    {
        return adoptRef(new CSSPrimitiveValue(valueID));
    }
    static PassRefPtr<CSSPrimitiveValue> createIdentifier(CSSPropertyID propertyID)
    {
        return adoptRef(new CSSPrimitiveValue(propertyID));
    }
    static PassRefPtr<CSSPrimitiveValue> createColor(unsigned rgbValue)
    {
        return adoptRef(new CSSPrimitiveValue(rgbValue, CSS_RGBCOLOR));
    }
    static PassRefPtr<CSSPrimitiveValue> create(double value, UnitType type)
    {
        return adoptRef(new CSSPrimitiveValue(value, type));
    }
    static PassRefPtr<CSSPrimitiveValue> create(const String& value, UnitType type)
    {
        return adoptRef(new CSSPrimitiveValue(value, type));
    }
    static PassRefPtr<CSSPrimitiveValue> create(const Length& value)
    {
        return adoptRef(new CSSPrimitiveValue(value));
    }
    static PassRefPtr<CSSPrimitiveValue> create(const LengthSize& value, const RenderStyle& style)
    {
        return adoptRef(new CSSPrimitiveValue(value, style));
    }
    template<typename T> static PassRefPtr<CSSPrimitiveValue> create(T value)
    {
        return adoptRef(new CSSPrimitiveValue(value));
    }

    // This value is used to handle quirky margins in reflow roots (body, td, and th) like WinIE.
    // The basic idea is that a stylesheet can use the value __qem (for quirky em) instead of em.
    // When the quirky value is used, if you're in quirks mode, the margin will collapse away
    // inside a table cell.
    static PassRefPtr<CSSPrimitiveValue> createAllowingMarginQuirk(double value, UnitType type)
    {
        CSSPrimitiveValue* quirkValue = new CSSPrimitiveValue(value, type);
        quirkValue->m_isQuirkValue = true;
        return adoptRef(quirkValue);
    }

    ~CSSPrimitiveValue();

    void cleanup();

    UnitType primitiveType() const;

    double computeDegrees();
    double computeSeconds();

    /*
     * Computes a length in pixels out of the given CSSValue
     *
     * The metrics have to be a bit different for screen and printer output.
     * For screen output we assume 1 inch == 72 px, for printer we assume 300 dpi
     *
     * this is screen/printer dependent, so we probably need a config option for this,
     * and some tool to calibrate.
     */
    template<typename T> T computeLength(const CSSToLengthConversionData&);

    // Converts to a Length, mapping various unit types appropriately.
    template<int> Length convertToLength(const CSSToLengthConversionData&);

    double getDoubleValue(UnitType, ExceptionState&) const;
    double getDoubleValue(UnitType) const;
    double getDoubleValue() const;

    // setFloatValue(..., ExceptionState&) and setStringValue() must use unsigned short instead of UnitType to match IDL bindings.
    void setFloatValue(unsigned short unitType, double floatValue, ExceptionState&);
    float getFloatValue(unsigned short unitType, ExceptionState& exceptionState) const { return getValue<float>(static_cast<UnitType>(unitType), exceptionState); }
    float getFloatValue(UnitType type) const { return getValue<float>(type); }
    float getFloatValue() const { return getValue<float>(); }

    int getIntValue(UnitType type, ExceptionState& exceptionState) const { return getValue<int>(type, exceptionState); }
    int getIntValue(UnitType type) const { return getValue<int>(type); }
    int getIntValue() const { return getValue<int>(); }

    template<typename T> inline T getValue(UnitType type, ExceptionState& exceptionState) const { return clampTo<T>(getDoubleValue(type, exceptionState)); }
    template<typename T> inline T getValue(UnitType type) const { return clampTo<T>(getDoubleValue(type)); }
    template<typename T> inline T getValue() const { return clampTo<T>(getDoubleValue()); }

    void setStringValue(unsigned short stringType, const String& stringValue, ExceptionState&);
    String getStringValue(ExceptionState&) const;
    String getStringValue() const;

    Rect* getRectValue(ExceptionState&) const;
    Rect* getRectValue() const { return m_primitiveUnitType != CSS_RECT ? 0 : m_value.rect; }

    Quad* getQuadValue(ExceptionState&) const;
    Quad* getQuadValue() const { return m_primitiveUnitType != CSS_QUAD ? 0 : m_value.quad; }

    PassRefPtr<RGBColor> getRGBColorValue(ExceptionState&) const;
    RGBA32 getRGBA32Value() const { return m_primitiveUnitType != CSS_RGBCOLOR ? 0 : m_value.rgbcolor; }

    Pair* getPairValue(ExceptionState&) const;
    Pair* getPairValue() const { return m_primitiveUnitType != CSS_PAIR ? 0 : m_value.pair; }

    CSSBasicShape* getShapeValue() const { return m_primitiveUnitType != CSS_SHAPE ? 0 : m_value.shape; }

    CSSCalcValue* cssCalcValue() const { return m_primitiveUnitType != CSS_CALC ? 0 : m_value.calc; }

    CSSPropertyID getPropertyID() const { return m_primitiveUnitType == CSS_PROPERTY_ID ? m_value.propertyID : CSSPropertyInvalid; }
    CSSValueID getValueID() const { return m_primitiveUnitType == CSS_VALUE_ID ? m_value.valueID : CSSValueInvalid; }

    template<typename T> inline operator T() const; // Defined in CSSPrimitiveValueMappings.h

    static const char* unitTypeToString(UnitType);
    String customCSSText(CSSTextFormattingFlags = QuoteCSSStringIfNeeded) const;

    bool isQuirkValue() { return m_isQuirkValue; }

    PassRefPtr<CSSPrimitiveValue> cloneForCSSOM() const;
    void setCSSOMSafe() { m_isCSSOMSafe = true; }

    bool equals(const CSSPrimitiveValue&) const;

    static UnitType canonicalUnitTypeForCategory(UnitCategory);
    static double conversionToCanonicalUnitsScaleFactor(UnitType);

    // Returns true and populates lengthUnitType, if unitType is a length unit. Otherwise, returns false.
    static bool unitTypeToLengthUnitType(UnitType, LengthUnitType&);
    static UnitType lengthUnitTypeToUnitType(LengthUnitType);

private:
    CSSPrimitiveValue(CSSValueID);
    CSSPrimitiveValue(CSSPropertyID);
    // int vs. unsigned is too subtle to distinguish types, so require a UnitType.
    CSSPrimitiveValue(int parserOperator, UnitType);
    CSSPrimitiveValue(unsigned color, UnitType); // RGB value
    CSSPrimitiveValue(const Length&);
    CSSPrimitiveValue(const LengthSize&, const RenderStyle&);
    CSSPrimitiveValue(const String&, UnitType);
    CSSPrimitiveValue(double, UnitType);

    template<typename T> CSSPrimitiveValue(T); // Defined in CSSPrimitiveValueMappings.h
    template<typename T> CSSPrimitiveValue(T* val)
        : CSSValue(PrimitiveClass)
    {
        init(PassRefPtr<T>(val));
    }

    template<typename T> CSSPrimitiveValue(PassRefPtr<T> val)
        : CSSValue(PrimitiveClass)
    {
        init(val);
    }

    static void create(int); // compile-time guard
    static void create(unsigned); // compile-time guard
    template<typename T> operator T*(); // compile-time guard

    void init(const Length&);
    void init(const LengthSize&, const RenderStyle&);
    void init(PassRefPtr<Rect>);
    void init(PassRefPtr<Pair>);
    void init(PassRefPtr<Quad>);
    void init(PassRefPtr<CSSBasicShape>);
    void init(PassRefPtr<CSSCalcValue>);
    bool getDoubleValueInternal(UnitType targetUnitType, double* result) const;

    double computeLengthDouble(const CSSToLengthConversionData&);

    union {
        CSSPropertyID propertyID;
        CSSValueID valueID;
        int parserOperator;
        double num;
        StringImpl* string;
        unsigned rgbcolor;
        // FIXME: oilpan: Should be members, but no support for members in unions. Just trace the raw ptr for now.
        CSSBasicShape* shape;
        CSSCalcValue* calc;
        Pair* pair;
        Rect* rect;
        Quad* quad;
    } m_value;
};

typedef CSSPrimitiveValue::CSSLengthArray CSSLengthArray;

DEFINE_CSS_VALUE_TYPE_CASTS(CSSPrimitiveValue, isPrimitiveValue());

} // namespace blink

#endif // CSSPrimitiveValue_h
