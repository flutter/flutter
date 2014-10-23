// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/MediaQueryParser.h"

#include "core/MediaTypeNames.h"
#include "core/css/parser/CSSPropertyParser.h"
#include "core/css/parser/MediaQueryTokenizer.h"
#include "wtf/Vector.h"

namespace blink {

PassRefPtrWillBeRawPtr<MediaQuerySet> MediaQueryParser::parseMediaQuerySet(const String& queryString)
{
    // FIXME: Replace the MediaQueryTokenizer with a generic CSSTokenizer, once there is one,
    // or better yet, replace the MediaQueryParser with a generic thread-safe CSS parser.
    Vector<MediaQueryToken> tokens;
    MediaQueryTokenizer::tokenize(queryString, tokens);
    return MediaQueryParser(MediaQuerySetParser).parseImpl(tokens.begin(), tokens.end());
}

PassRefPtrWillBeRawPtr<MediaQuerySet> MediaQueryParser::parseMediaCondition(MediaQueryTokenIterator token, MediaQueryTokenIterator endToken)
{
    return MediaQueryParser(MediaConditionParser).parseImpl(token, endToken);
}

const MediaQueryParser::State MediaQueryParser::ReadRestrictor = &MediaQueryParser::readRestrictor;
const MediaQueryParser::State MediaQueryParser::ReadMediaType = &MediaQueryParser::readMediaType;
const MediaQueryParser::State MediaQueryParser::ReadAnd = &MediaQueryParser::readAnd;
const MediaQueryParser::State MediaQueryParser::ReadFeatureStart = &MediaQueryParser::readFeatureStart;
const MediaQueryParser::State MediaQueryParser::ReadFeature = &MediaQueryParser::readFeature;
const MediaQueryParser::State MediaQueryParser::ReadFeatureColon = &MediaQueryParser::readFeatureColon;
const MediaQueryParser::State MediaQueryParser::ReadFeatureValue = &MediaQueryParser::readFeatureValue;
const MediaQueryParser::State MediaQueryParser::ReadFeatureEnd = &MediaQueryParser::readFeatureEnd;
const MediaQueryParser::State MediaQueryParser::SkipUntilComma = &MediaQueryParser::skipUntilComma;
const MediaQueryParser::State MediaQueryParser::SkipUntilBlockEnd = &MediaQueryParser::skipUntilBlockEnd;
const MediaQueryParser::State MediaQueryParser::Done = &MediaQueryParser::done;

MediaQueryParser::MediaQueryParser(ParserType parserType)
    : m_parserType(parserType)
    , m_querySet(MediaQuerySet::create())
{
    if (parserType == MediaQuerySetParser)
        m_state = &MediaQueryParser::readRestrictor;
    else // MediaConditionParser
        m_state = &MediaQueryParser::readFeatureStart;
}

MediaQueryParser::~MediaQueryParser() { };

void MediaQueryParser::setStateAndRestrict(State state, MediaQuery::Restrictor restrictor)
{
    m_mediaQueryData.setRestrictor(restrictor);
    m_state = state;
}

// State machine member functions start here
void MediaQueryParser::readRestrictor(MediaQueryTokenType type, const MediaQueryToken& token)
{
    readMediaType(type, token);
}

void MediaQueryParser::readMediaType(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == LeftParenthesisToken) {
        m_state = ReadFeature;
    } else if (type == IdentToken) {
        if (m_state == ReadRestrictor && equalIgnoringCase(token.value(), "not")) {
            setStateAndRestrict(ReadMediaType, MediaQuery::Not);
        } else if (m_state == ReadRestrictor && equalIgnoringCase(token.value(), "only")) {
            setStateAndRestrict(ReadMediaType, MediaQuery::Only);
        } else {
            m_mediaQueryData.setMediaType(token.value());
            m_state = ReadAnd;
        }
    } else if (type == EOFToken && (!m_querySet->queryVector().size() || m_state != ReadRestrictor)) {
        m_state = Done;
    } else {
        m_state = SkipUntilComma;
        if (type == CommaToken)
            skipUntilComma(type, token);
    }
}

void MediaQueryParser::readAnd(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == IdentToken && equalIgnoringCase(token.value(), "and")) {
        m_state = ReadFeatureStart;
    } else if (type == CommaToken && m_parserType != MediaConditionParser) {
        m_querySet->addMediaQuery(m_mediaQueryData.takeMediaQuery());
        m_state = ReadRestrictor;
    } else if (type == EOFToken) {
        m_state = Done;
    } else {
        m_state = SkipUntilComma;
    }
}

void MediaQueryParser::readFeatureStart(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == LeftParenthesisToken)
        m_state = ReadFeature;
    else
        m_state = SkipUntilComma;
}

void MediaQueryParser::readFeature(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == IdentToken) {
        m_mediaQueryData.setMediaFeature(token.value());
        m_state = ReadFeatureColon;
    } else {
        m_state = SkipUntilComma;
    }
}

void MediaQueryParser::readFeatureColon(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == ColonToken)
        m_state = ReadFeatureValue;
    else if (type == RightParenthesisToken || type == EOFToken)
        readFeatureEnd(type, token);
    else
        m_state = SkipUntilBlockEnd;
}

void MediaQueryParser::readFeatureValue(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == DimensionToken && token.unitType() == CSSPrimitiveValue::CSS_UNKNOWN) {
        m_state = SkipUntilComma;
    } else {
        m_mediaQueryData.addParserValue(type, token);
        m_state = ReadFeatureEnd;
    }
}

void MediaQueryParser::readFeatureEnd(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (type == RightParenthesisToken || type == EOFToken) {
        if (m_mediaQueryData.addExpression())
            m_state = ReadAnd;
        else
            m_state = SkipUntilComma;
    } else if (type == DelimiterToken && token.delimiter() == '/') {
        m_mediaQueryData.addParserValue(type, token);
        m_state = ReadFeatureValue;
    } else {
        m_state = SkipUntilBlockEnd;
    }
}

void MediaQueryParser::skipUntilComma(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if ((type == CommaToken && !m_blockWatcher.blockLevel()) || type == EOFToken) {
        m_state = ReadRestrictor;
        m_mediaQueryData.clear();
        m_querySet->addMediaQuery(MediaQuery::createNotAll());
    }
}

void MediaQueryParser::skipUntilBlockEnd(MediaQueryTokenType type, const MediaQueryToken& token)
{
    if (token.blockType() == MediaQueryToken::BlockEnd && !m_blockWatcher.blockLevel())
        m_state = SkipUntilComma;
}

void MediaQueryParser::done(MediaQueryTokenType type, const MediaQueryToken& token) { }

void MediaQueryParser::handleBlocks(const MediaQueryToken& token)
{
    if (token.blockType() == MediaQueryToken::BlockStart
        && (token.type() != LeftParenthesisToken || m_blockWatcher.blockLevel()))
            m_state = SkipUntilBlockEnd;
}

void MediaQueryParser::processToken(const MediaQueryToken& token)
{
    MediaQueryTokenType type = token.type();

    handleBlocks(token);
    m_blockWatcher.handleToken(token);

    // Call the function that handles current state
    if (type != WhitespaceToken && type != CommentToken)
        ((this)->*(m_state))(type, token);
}

// The state machine loop
PassRefPtrWillBeRawPtr<MediaQuerySet> MediaQueryParser::parseImpl(MediaQueryTokenIterator token, MediaQueryTokenIterator endToken)
{
    for (; token != endToken; ++token)
        processToken(*token);

    if (m_state != ReadAnd && m_state != ReadRestrictor && m_state != Done && (m_parserType != MediaConditionParser || m_state != ReadFeatureStart))
        m_querySet->addMediaQuery(MediaQuery::createNotAll());
    else if (m_mediaQueryData.currentMediaQueryChanged())
        m_querySet->addMediaQuery(m_mediaQueryData.takeMediaQuery());

    return m_querySet;
}

MediaQueryData::MediaQueryData()
    : m_restrictor(MediaQuery::None)
    , m_mediaType(MediaTypeNames::all)
    , m_expressions(adoptPtrWillBeNoop(new ExpressionHeapVector))
    , m_mediaTypeSet(false)
{
}

void MediaQueryData::clear()
{
    m_restrictor = MediaQuery::None;
    m_mediaType = MediaTypeNames::all;
    m_mediaTypeSet = false;
    m_mediaFeature = String();
    m_valueList.destroyAndClear();
    m_expressions = adoptPtrWillBeNoop(new ExpressionHeapVector);
}

PassOwnPtrWillBeRawPtr<MediaQuery> MediaQueryData::takeMediaQuery()
{
    OwnPtrWillBeRawPtr<MediaQuery> mediaQuery = adoptPtrWillBeNoop(new MediaQuery(m_restrictor, m_mediaType, m_expressions.release()));
    clear();
    return mediaQuery.release();
}

bool MediaQueryData::addExpression()
{
    OwnPtrWillBeRawPtr<MediaQueryExp> expression = MediaQueryExp::createIfValid(m_mediaFeature, &m_valueList);
    bool isValid = !!expression;
    m_expressions->append(expression.release());
    m_valueList.destroyAndClear();
    return isValid;
}

void MediaQueryData::addParserValue(MediaQueryTokenType type, const MediaQueryToken& token)
{
    CSSParserValue value;
    if (type == NumberToken || type == PercentageToken || type == DimensionToken) {
        value.setFromNumber(token.numericValue(), token.unitType());
        value.isInt = (token.numericValueType() == IntegerValueType);
    } else if (type == DelimiterToken) {
        value.unit = CSSParserValue::Operator;
        value.iValue = token.delimiter();
        value.id = CSSValueInvalid;
        value.isInt = false;
    } else {
        CSSParserFunction* function = new CSSParserFunction;
        function->name.init(token.value());
        value.setFromFunction(function);
        CSSParserString tokenValue;
        tokenValue.init(token.value());
        value.id = cssValueKeywordID(tokenValue);
    }
    m_valueList.addValue(value);
}

void MediaQueryData::setMediaType(const String& mediaType)
{
    m_mediaType = mediaType;
    m_mediaTypeSet = true;
}

} // namespace blink
