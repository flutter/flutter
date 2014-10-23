// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/SizesAttributeParser.h"

#include "core/MediaTypeNames.h"
#include "core/css/MediaQueryEvaluator.h"
#include "core/css/parser/MediaQueryTokenizer.h"
#include "core/css/parser/SizesCalcParser.h"

namespace blink {

SizesAttributeParser::SizesAttributeParser(PassRefPtr<MediaValues> mediaValues, const String& attribute)
    : m_mediaValues(mediaValues)
    , m_length(0)
    , m_lengthWasSet(false)
    , m_viewportDependant(false)
{
    MediaQueryTokenizer::tokenize(attribute, m_tokens);
    m_isValid = parse(m_tokens);
}

unsigned SizesAttributeParser::length()
{
    if (m_isValid)
        return effectiveSize();
    return effectiveSizeDefaultValue();
}

bool SizesAttributeParser::calculateLengthInPixels(MediaQueryTokenIterator startToken, MediaQueryTokenIterator endToken, unsigned& result)
{
    if (startToken == endToken)
        return false;
    MediaQueryTokenType type = startToken->type();
    if (type == DimensionToken) {
        int length;
        if (!CSSPrimitiveValue::isLength(startToken->unitType()))
            return false;
        m_viewportDependant = CSSPrimitiveValue::isViewportPercentageLength(startToken->unitType());
        if ((m_mediaValues->computeLength(startToken->numericValue(), startToken->unitType(), length)) && (length > 0)) {
            result = (unsigned)length;
            return true;
        }
    } else if (type == FunctionToken) {
        SizesCalcParser calcParser(startToken, endToken, m_mediaValues);
        if (!calcParser.isValid())
            return false;
        m_viewportDependant = calcParser.viewportDependant();
        result = calcParser.result();
        return true;
    } else if (type == NumberToken && !startToken->numericValue()) {
        result = 0;
        return true;
    }

    return false;
}

static void reverseSkipIrrelevantTokens(MediaQueryTokenIterator& token, MediaQueryTokenIterator startToken)
{
    MediaQueryTokenIterator endToken = token;
    while (token != startToken && (token->type() == WhitespaceToken || token->type() == CommentToken || token->type() == EOFToken))
        --token;
    if (token != endToken)
        ++token;
}

static void reverseSkipUntilComponentStart(MediaQueryTokenIterator& token, MediaQueryTokenIterator startToken)
{
    if (token == startToken)
        return;
    --token;
    if (token->blockType() != MediaQueryToken::BlockEnd)
        return;
    unsigned blockLevel = 0;
    while (token != startToken) {
        if (token->blockType() == MediaQueryToken::BlockEnd) {
            ++blockLevel;
        } else if (token->blockType() == MediaQueryToken::BlockStart) {
            --blockLevel;
            if (!blockLevel)
                break;
        }

        --token;
    }
}

bool SizesAttributeParser::mediaConditionMatches(PassRefPtrWillBeRawPtr<MediaQuerySet> mediaCondition)
{
    // A Media Condition cannot have a media type other then screen.
    MediaQueryEvaluator mediaQueryEvaluator(*m_mediaValues);
    return mediaQueryEvaluator.eval(mediaCondition.get());
}

bool SizesAttributeParser::parseMediaConditionAndLength(MediaQueryTokenIterator startToken, MediaQueryTokenIterator endToken)
{
    MediaQueryTokenIterator lengthTokenStart;
    MediaQueryTokenIterator lengthTokenEnd;

    reverseSkipIrrelevantTokens(endToken, startToken);
    lengthTokenEnd = endToken;
    reverseSkipUntilComponentStart(endToken, startToken);
    lengthTokenStart = endToken;
    unsigned length;
    if (!calculateLengthInPixels(lengthTokenStart, lengthTokenEnd, length))
        return false;
    RefPtrWillBeRawPtr<MediaQuerySet> mediaCondition = MediaQueryParser::parseMediaCondition(startToken, endToken);
    if (mediaCondition && mediaConditionMatches(mediaCondition)) {
        m_length = length;
        m_lengthWasSet = true;
        return true;
    }
    return false;
}

bool SizesAttributeParser::parse(Vector<MediaQueryToken>& tokens)
{
    if (tokens.isEmpty())
        return false;
    MediaQueryTokenIterator startToken = tokens.begin();
    MediaQueryTokenIterator endToken;
    // Split on a comma token, and send the result tokens to be parsed as (media-condition, length) pairs
    for (MediaQueryTokenIterator token = tokens.begin(); token != tokens.end(); ++token) {
        if (token->type() == CommaToken) {
            endToken = token;
            if (parseMediaConditionAndLength(startToken, endToken))
                return true;
            startToken = token;
            ++startToken;
        }
    }
    endToken = tokens.end();
    return parseMediaConditionAndLength(startToken, --endToken);
}

unsigned SizesAttributeParser::effectiveSize()
{
    if (m_lengthWasSet)
        return m_length;
    return effectiveSizeDefaultValue();
}

unsigned SizesAttributeParser::effectiveSizeDefaultValue()
{
    // Returning the equivalent of "100vw"
    m_viewportDependant = true;
    return m_mediaValues->viewportWidth();
}

} // namespace

