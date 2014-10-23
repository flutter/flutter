// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/SizesCalcParser.h"

#include "core/css/MediaValues.h"
#include "core/css/parser/MediaQueryToken.h"

namespace blink {

SizesCalcParser::SizesCalcParser(MediaQueryTokenIterator start, MediaQueryTokenIterator end, PassRefPtr<MediaValues> mediaValues)
    : m_mediaValues(mediaValues)
    , m_viewportDependant(false)
    , m_result(0)
{
    m_isValid = calcToReversePolishNotation(start, end) && calculate();
}

unsigned SizesCalcParser::result() const
{
    ASSERT(m_isValid);
    return m_result;
}

static bool operatorPriority(UChar cc, bool& highPriority)
{
    if (cc == '+' || cc == '-')
        highPriority = false;
    else if (cc == '*' || cc == '/')
        highPriority = true;
    else
        return false;
    return true;
}

bool SizesCalcParser::handleOperator(Vector<MediaQueryToken>& stack, const MediaQueryToken& token)
{
    // If the token is an operator, o1, then:
    // while there is an operator token, o2, at the top of the stack, and
    // either o1 is left-associative and its precedence is equal to that of o2,
    // or o1 has precedence less than that of o2,
    // pop o2 off the stack, onto the output queue;
    // push o1 onto the stack.
    bool stackOperatorPriority;
    bool incomingOperatorPriority;

    if (!operatorPriority(token.delimiter(), incomingOperatorPriority))
        return false;
    if (!stack.isEmpty() && stack.last().type() == DelimiterToken) {
        if (!operatorPriority(stack.last().delimiter(), stackOperatorPriority))
            return false;
        if (!incomingOperatorPriority || stackOperatorPriority) {
            appendOperator(stack.last());
            stack.removeLast();
        }
    }
    stack.append(token);
    return true;
}

void SizesCalcParser::appendNumber(const MediaQueryToken& token)
{
    SizesCalcValue value;
    value.value = token.numericValue();
    m_valueList.append(value);
}

bool SizesCalcParser::appendLength(const MediaQueryToken& token)
{
    SizesCalcValue value;
    double result = 0;
    if (!m_mediaValues->computeLength(token.numericValue(), token.unitType(), result))
        return false;
    value.value = result;
    value.isLength = true;
    m_valueList.append(value);
    return true;
}

void SizesCalcParser::appendOperator(const MediaQueryToken& token)
{
    SizesCalcValue value;
    value.operation = token.delimiter();
    m_valueList.append(value);
}

bool SizesCalcParser::calcToReversePolishNotation(MediaQueryTokenIterator start, MediaQueryTokenIterator end)
{
    // This method implements the shunting yard algorithm, to turn the calc syntax into a reverse polish notation.
    // http://en.wikipedia.org/wiki/Shunting-yard_algorithm

    Vector<MediaQueryToken> stack;
    for (MediaQueryTokenIterator it = start; it != end; ++it) {
        MediaQueryTokenType type = it->type();
        switch (type) {
        case NumberToken:
            appendNumber(*it);
            break;
        case DimensionToken:
            m_viewportDependant = m_viewportDependant || CSSPrimitiveValue::isViewportPercentageLength(it->unitType());
            if (!CSSPrimitiveValue::isLength(it->unitType()) || !appendLength(*it))
                return false;
            break;
        case DelimiterToken:
            if (!handleOperator(stack, *it))
                return false;
            break;
        case FunctionToken:
            if (it->value() != "calc")
                return false;
            // "calc(" is the same as "("
        case LeftParenthesisToken:
            // If the token is a left parenthesis, then push it onto the stack.
            stack.append(*it);
            break;
        case RightParenthesisToken:
            // If the token is a right parenthesis:
            // Until the token at the top of the stack is a left parenthesis, pop operators off the stack onto the output queue.
            while (!stack.isEmpty() && stack.last().type() != LeftParenthesisToken && stack.last().type() != FunctionToken) {
                appendOperator(stack.last());
                stack.removeLast();
            }
            // If the stack runs out without finding a left parenthesis, then there are mismatched parentheses.
            if (stack.isEmpty())
                return false;
            // Pop the left parenthesis from the stack, but not onto the output queue.
            stack.removeLast();
            break;
        case CommentToken:
        case WhitespaceToken:
        case EOFToken:
            break;
        case PercentageToken:
        case IdentToken:
        case CommaToken:
        case ColonToken:
        case SemicolonToken:
        case LeftBraceToken:
        case LeftBracketToken:
        case RightBraceToken:
        case RightBracketToken:
        case StringToken:
        case BadStringToken:
            return false;
        }
    }

    // When there are no more tokens to read:
    // While there are still operator tokens in the stack:
    while (!stack.isEmpty()) {
        // If the operator token on the top of the stack is a parenthesis, then there are mismatched parentheses.
        MediaQueryTokenType type = stack.last().type();
        if (type == LeftParenthesisToken || type == FunctionToken)
            return false;
        // Pop the operator onto the output queue.
        appendOperator(stack.last());
        stack.removeLast();
    }
    return true;
}

static bool operateOnStack(Vector<SizesCalcValue>& stack, UChar operation)
{
    if (stack.size() < 2)
        return false;
    SizesCalcValue rightOperand = stack.last();
    stack.removeLast();
    SizesCalcValue leftOperand = stack.last();
    stack.removeLast();
    bool isLength;
    switch (operation) {
    case '+':
        if (rightOperand.isLength != leftOperand.isLength)
            return false;
        isLength = (rightOperand.isLength && leftOperand.isLength);
        stack.append(SizesCalcValue(leftOperand.value + rightOperand.value, isLength));
        break;
    case '-':
        if (rightOperand.isLength != leftOperand.isLength)
            return false;
        isLength = (rightOperand.isLength && leftOperand.isLength);
        stack.append(SizesCalcValue(leftOperand.value - rightOperand.value, isLength));
        break;
    case '*':
        if (rightOperand.isLength && leftOperand.isLength)
            return false;
        isLength = (rightOperand.isLength || leftOperand.isLength);
        stack.append(SizesCalcValue(leftOperand.value * rightOperand.value, isLength));
        break;
    case '/':
        if (rightOperand.isLength || rightOperand.value == 0)
            return false;
        stack.append(SizesCalcValue(leftOperand.value / rightOperand.value, leftOperand.isLength));
        break;
    default:
        return false;
    }
    return true;
}

bool SizesCalcParser::calculate()
{
    Vector<SizesCalcValue> stack;
    for (Vector<SizesCalcValue>::iterator it = m_valueList.begin(); it != m_valueList.end(); ++it) {
        if (it->operation == 0) {
            stack.append(*it);
        } else {
            if (!operateOnStack(stack, it->operation))
                return false;
        }
    }
    if (stack.size() == 1 && stack.last().isLength) {
        m_result = clampTo<unsigned>(stack.last().value);
        return true;
    }
    return false;
}

} // namespace blink
