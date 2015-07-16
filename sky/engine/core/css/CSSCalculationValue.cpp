/*
 * Copyright (C) 2011, 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/core/css/CSSCalculationValue.h"

#include "sky/engine/core/css/CSSPrimitiveValueMappings.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/wtf/MathExtras.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/StringBuilder.h"

static const int maxExpressionDepth = 100;

enum ParseState {
    OK,
    TooDeep,
    NoMoreTokens
};

namespace blink {

static CalculationCategory unitCategory(CSSPrimitiveValue::UnitType type)
{
    switch (type) {
    case CSSPrimitiveValue::CSS_NUMBER:
        return CalcNumber;
    case CSSPrimitiveValue::CSS_PERCENTAGE:
        return CalcPercent;
    case CSSPrimitiveValue::CSS_EMS:
    case CSSPrimitiveValue::CSS_EXS:
    case CSSPrimitiveValue::CSS_PX:
    case CSSPrimitiveValue::CSS_CM:
    case CSSPrimitiveValue::CSS_MM:
    case CSSPrimitiveValue::CSS_IN:
    case CSSPrimitiveValue::CSS_PT:
    case CSSPrimitiveValue::CSS_PC:
    case CSSPrimitiveValue::CSS_CHS:
    case CSSPrimitiveValue::CSS_VW:
    case CSSPrimitiveValue::CSS_VH:
    case CSSPrimitiveValue::CSS_VMIN:
    case CSSPrimitiveValue::CSS_VMAX:
        return CalcLength;
    case CSSPrimitiveValue::CSS_DEG:
    case CSSPrimitiveValue::CSS_GRAD:
    case CSSPrimitiveValue::CSS_RAD:
    case CSSPrimitiveValue::CSS_TURN:
        return CalcAngle;
    case CSSPrimitiveValue::CSS_MS:
    case CSSPrimitiveValue::CSS_S:
        return CalcTime;
    case CSSPrimitiveValue::CSS_HZ:
    case CSSPrimitiveValue::CSS_KHZ:
        return CalcFrequency;
    default:
        return CalcOther;
    }
}

static bool hasDoubleValue(CSSPrimitiveValue::UnitType type)
{
    switch (type) {
    case CSSPrimitiveValue::CSS_NUMBER:
    case CSSPrimitiveValue::CSS_PERCENTAGE:
    case CSSPrimitiveValue::CSS_EMS:
    case CSSPrimitiveValue::CSS_EXS:
    case CSSPrimitiveValue::CSS_CHS:
    case CSSPrimitiveValue::CSS_PX:
    case CSSPrimitiveValue::CSS_CM:
    case CSSPrimitiveValue::CSS_MM:
    case CSSPrimitiveValue::CSS_IN:
    case CSSPrimitiveValue::CSS_PT:
    case CSSPrimitiveValue::CSS_PC:
    case CSSPrimitiveValue::CSS_DEG:
    case CSSPrimitiveValue::CSS_RAD:
    case CSSPrimitiveValue::CSS_GRAD:
    case CSSPrimitiveValue::CSS_TURN:
    case CSSPrimitiveValue::CSS_MS:
    case CSSPrimitiveValue::CSS_S:
    case CSSPrimitiveValue::CSS_HZ:
    case CSSPrimitiveValue::CSS_KHZ:
    case CSSPrimitiveValue::CSS_DIMENSION:
    case CSSPrimitiveValue::CSS_VW:
    case CSSPrimitiveValue::CSS_VH:
    case CSSPrimitiveValue::CSS_VMIN:
    case CSSPrimitiveValue::CSS_VMAX:
    case CSSPrimitiveValue::CSS_DPPX:
    case CSSPrimitiveValue::CSS_DPI:
    case CSSPrimitiveValue::CSS_DPCM:
    case CSSPrimitiveValue::CSS_FR:
        return true;
    case CSSPrimitiveValue::CSS_UNKNOWN:
    case CSSPrimitiveValue::CSS_STRING:
    case CSSPrimitiveValue::CSS_URI:
    case CSSPrimitiveValue::CSS_IDENT:
    case CSSPrimitiveValue::CSS_ATTR:
    case CSSPrimitiveValue::CSS_RECT:
    case CSSPrimitiveValue::CSS_RGBCOLOR:
    case CSSPrimitiveValue::CSS_PAIR:
    case CSSPrimitiveValue::CSS_UNICODE_RANGE:
    case CSSPrimitiveValue::CSS_PARSER_HEXCOLOR:
    case CSSPrimitiveValue::CSS_SHAPE:
    case CSSPrimitiveValue::CSS_QUAD:
    case CSSPrimitiveValue::CSS_CALC:
    case CSSPrimitiveValue::CSS_CALC_PERCENTAGE_WITH_NUMBER:
    case CSSPrimitiveValue::CSS_CALC_PERCENTAGE_WITH_LENGTH:
    case CSSPrimitiveValue::CSS_PROPERTY_ID:
    case CSSPrimitiveValue::CSS_VALUE_ID:
        return false;
    };
    ASSERT_NOT_REACHED();
    return false;
}

static String buildCSSText(const String& expression)
{
    StringBuilder result;
    result.appendLiteral("calc");
    bool expressionHasSingleTerm = expression[0] != '(';
    if (expressionHasSingleTerm)
        result.append('(');
    result.append(expression);
    if (expressionHasSingleTerm)
        result.append(')');
    return result.toString();
}

String CSSCalcValue::customCSSText() const
{
    return buildCSSText(m_expression->customCSSText());
}

bool CSSCalcValue::equals(const CSSCalcValue& other) const
{
    return compareCSSValuePtr(m_expression, other.m_expression);
}

double CSSCalcValue::clampToPermittedRange(double value) const
{
    return m_nonNegative && value < 0 ? 0 : value;
}

double CSSCalcValue::doubleValue() const
{
    return clampToPermittedRange(m_expression->doubleValue());
}

double CSSCalcValue::computeLengthPx(const CSSToLengthConversionData& conversionData) const
{
    return clampToPermittedRange(m_expression->computeLengthPx(conversionData));
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CSSCalcExpressionNode)

class CSSCalcPrimitiveValue final : public CSSCalcExpressionNode {
    WTF_MAKE_FAST_ALLOCATED;
public:

    static PassRefPtr<CSSCalcPrimitiveValue> create(PassRefPtr<CSSPrimitiveValue> value, bool isInteger)
    {
        return adoptRef(new CSSCalcPrimitiveValue(value, isInteger));
    }

    static PassRefPtr<CSSCalcPrimitiveValue> create(double value, CSSPrimitiveValue::UnitType type, bool isInteger)
    {
        if (std::isnan(value) || std::isinf(value))
            return nullptr;
        return adoptRef(new CSSCalcPrimitiveValue(CSSPrimitiveValue::create(value, type).get(), isInteger));
    }

    virtual bool isZero() const override
    {
        return !m_value->getDoubleValue();
    }

    virtual String customCSSText() const override
    {
        return m_value->cssText();
    }

    virtual void accumulatePixelsAndPercent(const CSSToLengthConversionData& conversionData, PixelsAndPercent& value, float multiplier) const override
    {
        switch (m_category) {
        case CalcLength:
            value.pixels += m_value->computeLength<float>(conversionData) * multiplier;
            break;
        case CalcPercent:
            ASSERT(m_value->isPercentage());
            value.percent += m_value->getDoubleValue() * multiplier;
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }

    virtual double doubleValue() const override
    {
        if (hasDoubleValue(primitiveType()))
            return m_value->getDoubleValue();
        ASSERT_NOT_REACHED();
        return 0;
    }

    virtual double computeLengthPx(const CSSToLengthConversionData& conversionData) const override
    {
        switch (m_category) {
        case CalcLength:
            return m_value->computeLength<double>(conversionData);
        case CalcNumber:
        case CalcPercent:
            return m_value->getDoubleValue();
        case CalcAngle:
        case CalcFrequency:
        case CalcPercentLength:
        case CalcPercentNumber:
        case CalcTime:
        case CalcOther:
            ASSERT_NOT_REACHED();
            break;
        }
        ASSERT_NOT_REACHED();
        return 0;
    }

    virtual void accumulateLengthArray(CSSLengthArray& lengthArray, double multiplier) const
    {
        ASSERT(category() != CalcNumber);
        m_value->accumulateLengthArray(lengthArray, multiplier);
    }

    virtual bool equals(const CSSCalcExpressionNode& other) const override
    {
        if (type() != other.type())
            return false;

        return compareCSSValuePtr(m_value, static_cast<const CSSCalcPrimitiveValue&>(other).m_value);
    }

    virtual Type type() const override { return CssCalcPrimitiveValue; }
    virtual CSSPrimitiveValue::UnitType primitiveType() const override
    {
        return m_value->primitiveType();
    }

private:
    CSSCalcPrimitiveValue(PassRefPtr<CSSPrimitiveValue> value, bool isInteger)
        : CSSCalcExpressionNode(unitCategory(value->primitiveType()), isInteger)
        , m_value(value)
    {
    }

    RefPtr<CSSPrimitiveValue> m_value;
};

static const CalculationCategory addSubtractResult[CalcOther][CalcOther] = {
//                        CalcNumber         CalcLength         CalcPercent        CalcPercentNumber  CalcPercentLength  CalcAngle  CalcTime   CalcFrequency
/* CalcNumber */        { CalcNumber,        CalcOther,         CalcPercentNumber, CalcPercentNumber, CalcOther,         CalcOther, CalcOther, CalcOther     },
/* CalcLength */        { CalcOther,         CalcLength,        CalcPercentLength, CalcOther,         CalcPercentLength, CalcOther, CalcOther, CalcOther     },
/* CalcPercent */       { CalcPercentNumber, CalcPercentLength, CalcPercent,       CalcPercentNumber, CalcPercentLength, CalcOther, CalcOther, CalcOther     },
/* CalcPercentNumber */ { CalcPercentNumber, CalcOther,         CalcPercentNumber, CalcPercentNumber, CalcOther,         CalcOther, CalcOther, CalcOther     },
/* CalcPercentLength */ { CalcOther,         CalcPercentLength, CalcPercentLength, CalcOther,         CalcPercentLength, CalcOther, CalcOther, CalcOther     },
/* CalcAngle  */        { CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcAngle, CalcOther, CalcOther     },
/* CalcTime */          { CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcOther, CalcTime,  CalcOther     },
/* CalcFrequency */     { CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcOther,         CalcOther, CalcOther, CalcFrequency }
};

static CalculationCategory determineCategory(const CSSCalcExpressionNode& leftSide, const CSSCalcExpressionNode& rightSide, CalcOperator op)
{
    CalculationCategory leftCategory = leftSide.category();
    CalculationCategory rightCategory = rightSide.category();

    if (leftCategory == CalcOther || rightCategory == CalcOther)
        return CalcOther;

    switch (op) {
    case CalcAdd:
    case CalcSubtract:
        return addSubtractResult[leftCategory][rightCategory];
    case CalcMultiply:
        if (leftCategory != CalcNumber && rightCategory != CalcNumber)
            return CalcOther;
        return leftCategory == CalcNumber ? rightCategory : leftCategory;
    case CalcDivide:
        if (rightCategory != CalcNumber || rightSide.isZero())
            return CalcOther;
        return leftCategory;
    }

    ASSERT_NOT_REACHED();
    return CalcOther;
}

static bool isIntegerResult(const CSSCalcExpressionNode* leftSide, const CSSCalcExpressionNode* rightSide, CalcOperator op)
{
    // Not testing for actual integer values.
    // Performs W3C spec's type checking for calc integers.
    // http://www.w3.org/TR/css3-values/#calc-type-checking
    return op != CalcDivide && leftSide->isInteger() && rightSide->isInteger();
}

class CSSCalcBinaryOperation final : public CSSCalcExpressionNode {
public:
    static PassRefPtr<CSSCalcExpressionNode> create(PassRefPtr<CSSCalcExpressionNode> leftSide, PassRefPtr<CSSCalcExpressionNode> rightSide, CalcOperator op)
    {
        ASSERT(leftSide->category() != CalcOther && rightSide->category() != CalcOther);

        CalculationCategory newCategory = determineCategory(*leftSide, *rightSide, op);
        if (newCategory == CalcOther)
            return nullptr;

        return adoptRef(new CSSCalcBinaryOperation(leftSide, rightSide, op, newCategory));
    }

    static PassRefPtr<CSSCalcExpressionNode> createSimplified(PassRefPtr<CSSCalcExpressionNode> leftSide, PassRefPtr<CSSCalcExpressionNode> rightSide, CalcOperator op)
    {
        CalculationCategory leftCategory = leftSide->category();
        CalculationCategory rightCategory = rightSide->category();
        ASSERT(leftCategory != CalcOther && rightCategory != CalcOther);

        bool isInteger = isIntegerResult(leftSide.get(), rightSide.get(), op);

        // Simplify numbers.
        if (leftCategory == CalcNumber && rightCategory == CalcNumber) {
            return CSSCalcPrimitiveValue::create(evaluateOperator(leftSide->doubleValue(), rightSide->doubleValue(), op), CSSPrimitiveValue::CSS_NUMBER, isInteger);
        }

        // Simplify addition and subtraction between same types.
        if (op == CalcAdd || op == CalcSubtract) {
            if (leftCategory == rightSide->category()) {
                CSSPrimitiveValue::UnitType leftType = leftSide->primitiveType();
                if (hasDoubleValue(leftType)) {
                    CSSPrimitiveValue::UnitType rightType = rightSide->primitiveType();
                    if (leftType == rightType)
                        return CSSCalcPrimitiveValue::create(evaluateOperator(leftSide->doubleValue(), rightSide->doubleValue(), op), leftType, isInteger);
                    CSSPrimitiveValue::UnitCategory leftUnitCategory = CSSPrimitiveValue::unitCategory(leftType);
                    if (leftUnitCategory != CSSPrimitiveValue::UOther && leftUnitCategory == CSSPrimitiveValue::unitCategory(rightType)) {
                        CSSPrimitiveValue::UnitType canonicalType = CSSPrimitiveValue::canonicalUnitTypeForCategory(leftUnitCategory);
                        if (canonicalType != CSSPrimitiveValue::CSS_UNKNOWN) {
                            double leftValue = leftSide->doubleValue() * CSSPrimitiveValue::conversionToCanonicalUnitsScaleFactor(leftType);
                            double rightValue = rightSide->doubleValue() * CSSPrimitiveValue::conversionToCanonicalUnitsScaleFactor(rightType);
                            return CSSCalcPrimitiveValue::create(evaluateOperator(leftValue, rightValue, op), canonicalType, isInteger);
                        }
                    }
                }
            }
        } else {
            // Simplify multiplying or dividing by a number for simplifiable types.
            ASSERT(op == CalcMultiply || op == CalcDivide);
            CSSCalcExpressionNode* numberSide = getNumberSide(leftSide.get(), rightSide.get());
            if (!numberSide)
                return create(leftSide, rightSide, op);
            if (numberSide == leftSide && op == CalcDivide)
                return nullptr;
            CSSCalcExpressionNode* otherSide = leftSide == numberSide ? rightSide.get() : leftSide.get();

            double number = numberSide->doubleValue();
            if (std::isnan(number) || std::isinf(number))
                return nullptr;
            if (op == CalcDivide && !number)
                return nullptr;

            CSSPrimitiveValue::UnitType otherType = otherSide->primitiveType();
            if (hasDoubleValue(otherType))
                return CSSCalcPrimitiveValue::create(evaluateOperator(otherSide->doubleValue(), number, op), otherType, isInteger);
        }

        return create(leftSide, rightSide, op);
    }

    virtual bool isZero() const override
    {
        return !doubleValue();
    }

    virtual void accumulatePixelsAndPercent(const CSSToLengthConversionData& conversionData, PixelsAndPercent& value, float multiplier) const override
    {
        switch (m_operator) {
        case CalcAdd:
            m_leftSide->accumulatePixelsAndPercent(conversionData, value, multiplier);
            m_rightSide->accumulatePixelsAndPercent(conversionData, value, multiplier);
            break;
        case CalcSubtract:
            m_leftSide->accumulatePixelsAndPercent(conversionData, value, multiplier);
            m_rightSide->accumulatePixelsAndPercent(conversionData, value, -multiplier);
            break;
        case CalcMultiply:
            ASSERT((m_leftSide->category() == CalcNumber) != (m_rightSide->category() == CalcNumber));
            if (m_leftSide->category() == CalcNumber)
                m_rightSide->accumulatePixelsAndPercent(conversionData, value, multiplier * m_leftSide->doubleValue());
            else
                m_leftSide->accumulatePixelsAndPercent(conversionData, value, multiplier * m_rightSide->doubleValue());
            break;
        case CalcDivide:
            ASSERT(m_rightSide->category() == CalcNumber);
            m_leftSide->accumulatePixelsAndPercent(conversionData, value, multiplier / m_rightSide->doubleValue());
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }

    virtual double doubleValue() const override
    {
        return evaluate(m_leftSide->doubleValue(), m_rightSide->doubleValue());
    }

    virtual double computeLengthPx(const CSSToLengthConversionData& conversionData) const override
    {
        const double leftValue = m_leftSide->computeLengthPx(conversionData);
        const double rightValue = m_rightSide->computeLengthPx(conversionData);
        return evaluate(leftValue, rightValue);
    }

    virtual void accumulateLengthArray(CSSLengthArray& lengthArray, double multiplier) const
    {
        switch (m_operator) {
        case CalcAdd:
            m_leftSide->accumulateLengthArray(lengthArray, multiplier);
            m_rightSide->accumulateLengthArray(lengthArray, multiplier);
            break;
        case CalcSubtract:
            m_leftSide->accumulateLengthArray(lengthArray, multiplier);
            m_rightSide->accumulateLengthArray(lengthArray, -multiplier);
            break;
        case CalcMultiply:
            ASSERT((m_leftSide->category() == CalcNumber) != (m_rightSide->category() == CalcNumber));
            if (m_leftSide->category() == CalcNumber)
                m_rightSide->accumulateLengthArray(lengthArray, multiplier * m_leftSide->doubleValue());
            else
                m_leftSide->accumulateLengthArray(lengthArray, multiplier * m_rightSide->doubleValue());
            break;
        case CalcDivide:
            ASSERT(m_rightSide->category() == CalcNumber);
            m_leftSide->accumulateLengthArray(lengthArray, multiplier / m_rightSide->doubleValue());
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }

    static String buildCSSText(const String& leftExpression, const String& rightExpression, CalcOperator op)
    {
        StringBuilder result;
        result.append('(');
        result.append(leftExpression);
        result.append(' ');
        result.append(static_cast<char>(op));
        result.append(' ');
        result.append(rightExpression);
        result.append(')');

        return result.toString();
    }

    virtual String customCSSText() const override
    {
        return buildCSSText(m_leftSide->customCSSText(), m_rightSide->customCSSText(), m_operator);
    }

    virtual bool equals(const CSSCalcExpressionNode& exp) const override
    {
        if (type() != exp.type())
            return false;

        const CSSCalcBinaryOperation& other = static_cast<const CSSCalcBinaryOperation&>(exp);
        return compareCSSValuePtr(m_leftSide, other.m_leftSide)
            && compareCSSValuePtr(m_rightSide, other.m_rightSide)
            && m_operator == other.m_operator;
    }

    virtual Type type() const override { return CssCalcBinaryOperation; }

    virtual CSSPrimitiveValue::UnitType primitiveType() const override
    {
        switch (m_category) {
        case CalcNumber:
            ASSERT(m_leftSide->category() == CalcNumber && m_rightSide->category() == CalcNumber);
            return CSSPrimitiveValue::CSS_NUMBER;
        case CalcLength:
        case CalcPercent: {
            if (m_leftSide->category() == CalcNumber)
                return m_rightSide->primitiveType();
            if (m_rightSide->category() == CalcNumber)
                return m_leftSide->primitiveType();
            CSSPrimitiveValue::UnitType leftType = m_leftSide->primitiveType();
            if (leftType == m_rightSide->primitiveType())
                return leftType;
            return CSSPrimitiveValue::CSS_UNKNOWN;
        }
        case CalcAngle:
            return CSSPrimitiveValue::CSS_DEG;
        case CalcTime:
            return CSSPrimitiveValue::CSS_MS;
        case CalcFrequency:
            return CSSPrimitiveValue::CSS_HZ;
        case CalcPercentLength:
        case CalcPercentNumber:
        case CalcOther:
            return CSSPrimitiveValue::CSS_UNKNOWN;
        }
        ASSERT_NOT_REACHED();
        return CSSPrimitiveValue::CSS_UNKNOWN;
    }

private:
    CSSCalcBinaryOperation(PassRefPtr<CSSCalcExpressionNode> leftSide, PassRefPtr<CSSCalcExpressionNode> rightSide, CalcOperator op, CalculationCategory category)
        : CSSCalcExpressionNode(category, isIntegerResult(leftSide.get(), rightSide.get(), op))
        , m_leftSide(leftSide)
        , m_rightSide(rightSide)
        , m_operator(op)
    {
    }

    static CSSCalcExpressionNode* getNumberSide(CSSCalcExpressionNode* leftSide, CSSCalcExpressionNode* rightSide)
    {
        if (leftSide->category() == CalcNumber)
            return leftSide;
        if (rightSide->category() == CalcNumber)
            return rightSide;
        return 0;
    }

    double evaluate(double leftSide, double rightSide) const
    {
        return evaluateOperator(leftSide, rightSide, m_operator);
    }

    static double evaluateOperator(double leftValue, double rightValue, CalcOperator op)
    {
        switch (op) {
        case CalcAdd:
            return leftValue + rightValue;
        case CalcSubtract:
            return leftValue - rightValue;
        case CalcMultiply:
            return leftValue * rightValue;
        case CalcDivide:
            if (rightValue)
                return leftValue / rightValue;
            return std::numeric_limits<double>::quiet_NaN();
        }
        return 0;
    }

    const RefPtr<CSSCalcExpressionNode> m_leftSide;
    const RefPtr<CSSCalcExpressionNode> m_rightSide;
    const CalcOperator m_operator;
};

static ParseState checkDepthAndIndex(int* depth, unsigned index, CSSParserValueList* tokens)
{
    (*depth)++;
    if (*depth > maxExpressionDepth)
        return TooDeep;
    if (index >= tokens->size())
        return NoMoreTokens;
    return OK;
}

class CSSCalcExpressionNodeParser {
    STACK_ALLOCATED();
public:
    PassRefPtr<CSSCalcExpressionNode> parseCalc(CSSParserValueList* tokens)
    {
        unsigned index = 0;
        Value result;
        bool ok = parseValueExpression(tokens, 0, &index, &result);
        ASSERT_WITH_SECURITY_IMPLICATION(index <= tokens->size());
        if (!ok || index != tokens->size())
            return nullptr;
        return result.value;
    }

private:
    struct Value {
        STACK_ALLOCATED();
    public:
        RefPtr<CSSCalcExpressionNode> value;
    };

    char operatorValue(CSSParserValueList* tokens, unsigned index)
    {
        if (index >= tokens->size())
            return 0;
        CSSParserValue* value = tokens->valueAt(index);
        if (value->unit != CSSParserValue::Operator)
            return 0;

        return value->iValue;
    }

    bool parseValue(CSSParserValueList* tokens, unsigned* index, Value* result)
    {
        CSSParserValue* parserValue = tokens->valueAt(*index);
        if (parserValue->unit >= CSSParserValue::Operator)
            return false;

        CSSPrimitiveValue::UnitType type = static_cast<CSSPrimitiveValue::UnitType>(parserValue->unit);
        if (unitCategory(type) == CalcOther)
            return false;

        result->value = CSSCalcPrimitiveValue::create(
            CSSPrimitiveValue::create(parserValue->fValue, type), parserValue->isInt);

        ++*index;
        return true;
    }

    bool parseValueTerm(CSSParserValueList* tokens, int depth, unsigned* index, Value* result)
    {
        if (checkDepthAndIndex(&depth, *index, tokens) != OK)
            return false;

        if (operatorValue(tokens, *index) == '(') {
            unsigned currentIndex = *index + 1;
            if (!parseValueExpression(tokens, depth, &currentIndex, result))
                return false;

            if (operatorValue(tokens, currentIndex) != ')')
                return false;
            *index = currentIndex + 1;
            return true;
        }

        return parseValue(tokens, index, result);
    }

    bool parseValueMultiplicativeExpression(CSSParserValueList* tokens, int depth, unsigned* index, Value* result)
    {
        if (checkDepthAndIndex(&depth, *index, tokens) != OK)
            return false;

        if (!parseValueTerm(tokens, depth, index, result))
            return false;

        while (*index < tokens->size() - 1) {
            char operatorCharacter = operatorValue(tokens, *index);
            if (operatorCharacter != CalcMultiply && operatorCharacter != CalcDivide)
                break;
            ++*index;

            Value rhs;
            if (!parseValueTerm(tokens, depth, index, &rhs))
                return false;

            result->value = CSSCalcBinaryOperation::createSimplified(result->value, rhs.value, static_cast<CalcOperator>(operatorCharacter));
            if (!result->value)
                return false;
        }

        ASSERT_WITH_SECURITY_IMPLICATION(*index <= tokens->size());
        return true;
    }

    bool parseAdditiveValueExpression(CSSParserValueList* tokens, int depth, unsigned* index, Value* result)
    {
        if (checkDepthAndIndex(&depth, *index, tokens) != OK)
            return false;

        if (!parseValueMultiplicativeExpression(tokens, depth, index, result))
            return false;

        while (*index < tokens->size() - 1) {
            char operatorCharacter = operatorValue(tokens, *index);
            if (operatorCharacter != CalcAdd && operatorCharacter != CalcSubtract)
                break;
            ++*index;

            Value rhs;
            if (!parseValueMultiplicativeExpression(tokens, depth, index, &rhs))
                return false;

            result->value = CSSCalcBinaryOperation::createSimplified(result->value, rhs.value, static_cast<CalcOperator>(operatorCharacter));
            if (!result->value)
                return false;
        }

        ASSERT_WITH_SECURITY_IMPLICATION(*index <= tokens->size());
        return true;
    }

    bool parseValueExpression(CSSParserValueList* tokens, int depth, unsigned* index, Value* result)
    {
        return parseAdditiveValueExpression(tokens, depth, index, result);
    }
};

PassRefPtr<CSSCalcExpressionNode> CSSCalcValue::createExpressionNode(PassRefPtr<CSSPrimitiveValue> value, bool isInteger)
{
    return CSSCalcPrimitiveValue::create(value, isInteger);
}

PassRefPtr<CSSCalcExpressionNode> CSSCalcValue::createExpressionNode(PassRefPtr<CSSCalcExpressionNode> leftSide, PassRefPtr<CSSCalcExpressionNode> rightSide, CalcOperator op)
{
    return CSSCalcBinaryOperation::create(leftSide, rightSide, op);
}

PassRefPtr<CSSCalcExpressionNode> CSSCalcValue::createExpressionNode(double pixels, double percent)
{
    return createExpressionNode(
        createExpressionNode(CSSPrimitiveValue::create(pixels, CSSPrimitiveValue::CSS_PX), pixels == trunc(pixels)),
        createExpressionNode(CSSPrimitiveValue::create(percent, CSSPrimitiveValue::CSS_PERCENTAGE), percent == trunc(percent)),
        CalcAdd);
}

PassRefPtr<CSSCalcValue> CSSCalcValue::create(CSSParserString name, CSSParserValueList* parserValueList, ValueRange range)
{
    CSSCalcExpressionNodeParser parser;
    RefPtr<CSSCalcExpressionNode> expression = nullptr;

    if (equalIgnoringCase(name, "calc(") || equalIgnoringCase(name, "-webkit-calc("))
        expression = parser.parseCalc(parserValueList);
    // FIXME calc (http://webkit.org/b/16662) Add parsing for min and max here

    return expression ? adoptRef(new CSSCalcValue(expression, range)) : nullptr;
}

PassRefPtr<CSSCalcValue> CSSCalcValue::create(PassRefPtr<CSSCalcExpressionNode> expression, ValueRange range)
{
    return adoptRef(new CSSCalcValue(expression, range));
}

} // namespace blink
