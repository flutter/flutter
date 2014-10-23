// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MediaQueryToken_h
#define MediaQueryToken_h

#include "core/css/CSSPrimitiveValue.h"
#include "wtf/text/WTFString.h"

namespace blink {

enum MediaQueryTokenType {
    IdentToken = 0,
    FunctionToken,
    DelimiterToken,
    NumberToken,
    PercentageToken,
    DimensionToken,
    WhitespaceToken,
    ColonToken,
    SemicolonToken,
    CommaToken,
    LeftParenthesisToken,
    RightParenthesisToken,
    LeftBracketToken,
    RightBracketToken,
    LeftBraceToken,
    RightBraceToken,
    StringToken,
    BadStringToken,
    EOFToken,
    CommentToken,
};

enum NumericValueType {
    IntegerValueType,
    NumberValueType,
};

class MediaQueryToken {
public:
    enum BlockType {
        NotBlock,
        BlockStart,
        BlockEnd,
    };

    MediaQueryToken(MediaQueryTokenType, BlockType = NotBlock);
    MediaQueryToken(MediaQueryTokenType, String value, BlockType = NotBlock);

    MediaQueryToken(MediaQueryTokenType, UChar); // for DelimiterToken
    MediaQueryToken(MediaQueryTokenType, double, NumericValueType); // for NumberToken

    // Converts NumberToken to DimensionToken.
    void convertToDimensionWithUnit(String);

    // Converts NumberToken to PercentageToken.
    void convertToPercentage();

    MediaQueryTokenType type() const { return m_type; }
    String value() const { return m_value; }
    String textForUnitTests() const;

    UChar delimiter() const;
    NumericValueType numericValueType() const;
    double numericValue() const;
    BlockType blockType() const { return m_blockType; }
    CSSPrimitiveValue::UnitType unitType() const { return m_unit; }

private:
    MediaQueryTokenType m_type;
    String m_value;

    UChar m_delimiter; // Could be rolled into m_value?

    NumericValueType m_numericValueType;
    double m_numericValue;
    CSSPrimitiveValue::UnitType m_unit;

    BlockType m_blockType;
};

typedef Vector<MediaQueryToken>::iterator MediaQueryTokenIterator;

} // namespace

#endif // MediaQueryToken_h
