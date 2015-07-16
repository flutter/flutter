// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYPARSER_H_
#define SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYPARSER_H_

#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/MediaQuery.h"
#include "sky/engine/core/css/MediaQueryExp.h"
#include "sky/engine/core/css/parser/CSSParserValues.h"
#include "sky/engine/core/css/parser/MediaQueryBlockWatcher.h"
#include "sky/engine/core/css/parser/MediaQueryToken.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class MediaQuerySet;

class MediaQueryData {
    STACK_ALLOCATED();
private:
    MediaQuery::Restrictor m_restrictor;
    String m_mediaType;
    OwnPtr<ExpressionHeapVector> m_expressions;
    String m_mediaFeature;
    CSSParserValueList m_valueList;
    bool m_mediaTypeSet;

public:
    MediaQueryData();
    void clear();
    bool addExpression();
    void addParserValue(MediaQueryTokenType, const MediaQueryToken&);
    void setMediaType(const String&);
    PassOwnPtr<MediaQuery> takeMediaQuery();

    inline bool currentMediaQueryChanged() const
    {
        return (m_restrictor != MediaQuery::None || m_mediaTypeSet || m_expressions->size() > 0);
    }

    inline void setRestrictor(MediaQuery::Restrictor restrictor) { m_restrictor = restrictor; }

    inline void setMediaFeature(const String& str) { m_mediaFeature = str; }
};

class MediaQueryParser {
    STACK_ALLOCATED();
public:
    static PassRefPtr<MediaQuerySet> parseMediaQuerySet(const String&);
    static PassRefPtr<MediaQuerySet> parseMediaCondition(MediaQueryTokenIterator, MediaQueryTokenIterator endToken);

private:
    enum ParserType {
        MediaQuerySetParser,
        MediaConditionParser,
    };

    MediaQueryParser(ParserType);
    virtual ~MediaQueryParser();

    PassRefPtr<MediaQuerySet> parseImpl(MediaQueryTokenIterator, MediaQueryTokenIterator endToken);

    void processToken(const MediaQueryToken&);

    void readRestrictor(MediaQueryTokenType, const MediaQueryToken&);
    void readMediaType(MediaQueryTokenType, const MediaQueryToken&);
    void readAnd(MediaQueryTokenType, const MediaQueryToken&);
    void readFeatureStart(MediaQueryTokenType, const MediaQueryToken&);
    void readFeature(MediaQueryTokenType, const MediaQueryToken&);
    void readFeatureColon(MediaQueryTokenType, const MediaQueryToken&);
    void readFeatureValue(MediaQueryTokenType, const MediaQueryToken&);
    void readFeatureEnd(MediaQueryTokenType, const MediaQueryToken&);
    void skipUntilComma(MediaQueryTokenType, const MediaQueryToken&);
    void skipUntilBlockEnd(MediaQueryTokenType, const MediaQueryToken&);
    void done(MediaQueryTokenType, const MediaQueryToken&);

    typedef void (MediaQueryParser::*State)(MediaQueryTokenType, const MediaQueryToken&);

    void setStateAndRestrict(State, MediaQuery::Restrictor);
    void handleBlocks(const MediaQueryToken&);

    State m_state;
    ParserType m_parserType;
    MediaQueryData m_mediaQueryData;
    RefPtr<MediaQuerySet> m_querySet;
    MediaQueryBlockWatcher m_blockWatcher;

    const static State ReadRestrictor;
    const static State ReadMediaType;
    const static State ReadAnd;
    const static State ReadFeatureStart;
    const static State ReadFeature;
    const static State ReadFeatureColon;
    const static State ReadFeatureValue;
    const static State ReadFeatureEnd;
    const static State SkipUntilComma;
    const static State SkipUntilBlockEnd;
    const static State Done;

};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYPARSER_H_
