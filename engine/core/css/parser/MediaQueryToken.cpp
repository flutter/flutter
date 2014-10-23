// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/MediaQueryToken.h"

#include "wtf/HashMap.h"
#include "wtf/text/StringHash.h"
#include <limits.h>

namespace blink {


MediaQueryToken::MediaQueryToken(MediaQueryTokenType type, BlockType blockType)
    : m_type(type)
    , m_delimiter(0)
    , m_numericValue(0)
    , m_unit(CSSPrimitiveValue::CSS_UNKNOWN)
    , m_blockType(blockType)
{
}

// Just a helper used for Delimiter tokens.
MediaQueryToken::MediaQueryToken(MediaQueryTokenType type, UChar c)
    : m_type(type)
    , m_delimiter(c)
    , m_numericValue(0)
    , m_unit(CSSPrimitiveValue::CSS_UNKNOWN)
    , m_blockType(NotBlock)
{
    ASSERT(m_type == DelimiterToken);
}

MediaQueryToken::MediaQueryToken(MediaQueryTokenType type, String value, BlockType blockType)
    : m_type(type)
    , m_value(value)
    , m_delimiter(0)
    , m_numericValue(0)
    , m_unit(CSSPrimitiveValue::CSS_UNKNOWN)
    , m_blockType(blockType)
{
}

MediaQueryToken::MediaQueryToken(MediaQueryTokenType type, double numericValue, NumericValueType numericValueType)
    : m_type(type)
    , m_delimiter(0)
    , m_numericValueType(numericValueType)
    , m_numericValue(numericValue)
    , m_unit(CSSPrimitiveValue::CSS_NUMBER)
    , m_blockType(NotBlock)
{
    ASSERT(type == NumberToken);
}

void MediaQueryToken::convertToDimensionWithUnit(String unit)
{
    ASSERT(m_type == NumberToken);
    m_type = DimensionToken;
    m_unit = CSSPrimitiveValue::fromName(unit);
}

void MediaQueryToken::convertToPercentage()
{
    ASSERT(m_type == NumberToken);
    m_type = PercentageToken;
    m_unit = CSSPrimitiveValue::CSS_PERCENTAGE;
}

// This function is used only for testing
// FIXME - This doesn't cover all possible Token types, but it's enough for current testing.
String MediaQueryToken::textForUnitTests() const
{
    char buffer[std::numeric_limits<float>::digits];
    if (!m_value.isNull())
        return m_value;
    if (m_type == LeftParenthesisToken)
        return String("(");
    if (m_type == RightParenthesisToken)
        return String(")");
    if (m_type == ColonToken)
        return String(":");
    if (m_type == WhitespaceToken)
        return String(" ");

    if (m_delimiter) {
        sprintf(buffer, "'%c'", m_delimiter);
        return String(buffer, strlen(buffer));
    }
    if (m_numericValue) {
        static const unsigned maxUnitBufferLength = 6;
        char unitBuffer[maxUnitBufferLength] = {0};
        if (m_unit == CSSPrimitiveValue::CSS_PERCENTAGE)
            sprintf(unitBuffer, "%s", "%");
        else if (m_unit == CSSPrimitiveValue::CSS_PX)
            sprintf(unitBuffer, "%s", "px");
        else if (m_unit == CSSPrimitiveValue::CSS_EMS)
            sprintf(unitBuffer, "%s", "em");
        else if (m_unit != CSSPrimitiveValue::CSS_NUMBER)
            sprintf(unitBuffer, "%s", "other");
        if (m_numericValueType == IntegerValueType)
            sprintf(buffer, "%d%s", static_cast<int>(m_numericValue), unitBuffer);
        else
            sprintf(buffer, "%f%s", m_numericValue, unitBuffer);

        return String(buffer, strlen(buffer));
    }
    return String();
}

UChar MediaQueryToken::delimiter() const
{
    ASSERT(m_type == DelimiterToken);
    return m_delimiter;
}

NumericValueType MediaQueryToken::numericValueType() const
{
    ASSERT(m_type == NumberToken || m_type == PercentageToken || m_type == DimensionToken);
    return m_numericValueType;
}

double MediaQueryToken::numericValue() const
{
    ASSERT(m_type == NumberToken || m_type == PercentageToken || m_type == DimensionToken);
    return m_numericValue;
}

} // namespace blink
