// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYTOKENIZER_H_
#define SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYTOKENIZER_H_

#include <climits>
#include "sky/engine/core/css/parser/MediaQueryToken.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class MediaQueryInputStream;

class MediaQueryTokenizer {
    WTF_MAKE_NONCOPYABLE(MediaQueryTokenizer);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static void tokenize(String, Vector<MediaQueryToken>&);
private:
    MediaQueryTokenizer(MediaQueryInputStream&);

    MediaQueryToken nextToken();

    UChar consume();
    void consume(unsigned);
    void reconsume(UChar);

    MediaQueryToken consumeNumericToken();
    MediaQueryToken consumeIdentLikeToken();
    MediaQueryToken consumeNumber();
    MediaQueryToken consumeStringTokenUntil(UChar);

    void consumeUntilNonWhitespace();
    bool consumeUntilCommentEndFound();

    bool consumeIfNext(UChar);
    String consumeName();
    UChar consumeEscape();

    bool nextTwoCharsAreValidEscape();
    bool nextCharsAreNumber(UChar);
    bool nextCharsAreNumber();
    bool nextCharsAreIdentifier(UChar);
    bool nextCharsAreIdentifier();
    MediaQueryToken blockStart(MediaQueryTokenType);
    MediaQueryToken blockStart(MediaQueryTokenType blockType, MediaQueryTokenType, String);
    MediaQueryToken blockEnd(MediaQueryTokenType, MediaQueryTokenType startType);

    typedef MediaQueryToken (MediaQueryTokenizer::*CodePoint)(UChar);

    static const CodePoint codePoints[];
    Vector<MediaQueryTokenType> m_blockStack;

    MediaQueryToken whiteSpace(UChar);
    MediaQueryToken leftParenthesis(UChar);
    MediaQueryToken rightParenthesis(UChar);
    MediaQueryToken leftBracket(UChar);
    MediaQueryToken rightBracket(UChar);
    MediaQueryToken leftBrace(UChar);
    MediaQueryToken rightBrace(UChar);
    MediaQueryToken plusOrFullStop(UChar);
    MediaQueryToken comma(UChar);
    MediaQueryToken hyphenMinus(UChar);
    MediaQueryToken asterisk(UChar);
    MediaQueryToken solidus(UChar);
    MediaQueryToken colon(UChar);
    MediaQueryToken semiColon(UChar);
    MediaQueryToken reverseSolidus(UChar);
    MediaQueryToken asciiDigit(UChar);
    MediaQueryToken nameStart(UChar);
    MediaQueryToken stringStart(UChar);
    MediaQueryToken endOfFile(UChar);

    MediaQueryInputStream& m_input;
};



} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_PARSER_MEDIAQUERYTOKENIZER_H_
