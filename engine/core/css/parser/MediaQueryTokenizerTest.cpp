// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/MediaQueryTokenizer.h"

#include "core/css/parser/MediaQueryBlockWatcher.h"
#include "wtf/PassOwnPtr.h"
#include <gtest/gtest.h>

namespace blink {

typedef struct {
    const char* input;
    const char* output;
} TestCase;

typedef struct {
    const char* input;
    const unsigned maxLevel;
    const unsigned finalLevel;
} BlockTestCase;

TEST(MediaQueryTokenizerTest, Basic)
{
    TestCase testCases[] = {
        { "(max-width: 50px)", "(max-width: 50px)" },
        { "(max-width: 1e+2px)", "(max-width: 100px)" },
        { "(max-width: 1e2px)", "(max-width: 100px)" },
        { "(max-width: 1000e-1px)", "(max-width: 100px)" },
        { "(max-width: 50\\70\\78)", "(max-width: 50px)" },
        { "(max-width: /* comment */50px)", "(max-width: 50px)" },
        { "(max-width: /** *commen*t */60px)", "(max-width: 60px)" },
        { "(max-width: /** *commen*t **/70px)", "(max-width: 70px)" },
        { "(max-width: /** *commen*t **//**/80px)", "(max-width: 80px)" },
        { "(max-width: /*/ **/90px)", "(max-width: 90px)" },
        { "(max-width: /*/ **/*100px)", "(max-width: '*'100px)" },
        { "(max-width: 110px/*)", "(max-width: 110px" },
        { "(max-width: 120px)/*", "(max-width: 120px)" },
        { "(max-width: 130px)/**", "(max-width: 130px)" },
        { "(max-width: /***/140px)/**/", "(max-width: 140px)" },
        { "(max-width: '40px')", "(max-width: 40px)" },
        { "(max-width: '40px", "(max-width: 40px" },
        { "(max-width: '40px\n", "(max-width:  " },
        { "(max-width: '40px\\", "(max-width: 40px" },
        { "(max-width: '40px\\\n", "(max-width: 40px" },
        { "(max-width: '40px\\\n')", "(max-width: 40px)" },
        { "(max-width: '40\\70\\78')", "(max-width: 40px)" },
        { "(max-width: '40\\\npx')", "(max-width: 40px)" },
        { "(max-aspect-ratio: 5)", "(max-aspect-ratio: 5)" },
        { "(max-aspect-ratio: +5)", "(max-aspect-ratio: 5)" },
        { "(max-aspect-ratio: -5)", "(max-aspect-ratio: -5)" },
        { "(max-aspect-ratio: -+5)", "(max-aspect-ratio: '-'5)" },
        { "(max-aspect-ratio: +-5)", "(max-aspect-ratio: '+'-5)" },
        { "(max-aspect-ratio: +bla5)", "(max-aspect-ratio: '+'bla5)" },
        { "(max-aspect-ratio: +5bla)", "(max-aspect-ratio: 5other)" },
        { "(max-aspect-ratio: -bla)", "(max-aspect-ratio: -bla)" },
        { "(max-aspect-ratio: --bla)", "(max-aspect-ratio: '-'-bla)" },
        { 0, 0 } // Do not remove the terminator line.
    };

    for (int i = 0; testCases[i].input; ++i) {
        Vector<MediaQueryToken> tokens;
        MediaQueryTokenizer::tokenize(testCases[i].input, tokens);
        StringBuilder output;
        for (size_t j = 0; j < tokens.size(); ++j)
            output.append(tokens[j].textForUnitTests());
        ASSERT_STREQ(testCases[i].output, output.toString().ascii().data());
    }
}

TEST(MediaQueryTokenizerBlockTest, Basic)
{
    BlockTestCase testCases[] = {
        {"(max-width: 800px()), (max-width: 800px)", 2, 0},
        {"(max-width: 900px(()), (max-width: 900px)", 3, 1},
        {"(max-width: 600px(())))), (max-width: 600px)", 3, 0},
        {"(max-width: 500px(((((((((())))), (max-width: 500px)", 11, 6},
        {"(max-width: 800px[]), (max-width: 800px)", 2, 0},
        {"(max-width: 900px[[]), (max-width: 900px)", 3, 2},
        {"(max-width: 600px[[]]]]), (max-width: 600px)", 3, 0},
        {"(max-width: 500px[[[[[[[[[[]]]]), (max-width: 500px)", 11, 7},
        {"(max-width: 800px{}), (max-width: 800px)", 2, 0},
        {"(max-width: 900px{{}), (max-width: 900px)", 3, 2},
        {"(max-width: 600px{{}}}}), (max-width: 600px)", 3, 0},
        {"(max-width: 500px{{{{{{{{{{}}}}), (max-width: 500px)", 11, 7},
        {"[(), (max-width: 400px)", 2, 1},
        {"[{}, (max-width: 500px)", 2, 1},
        {"[{]}], (max-width: 900px)", 2, 0},
        {"[{[]{}{{{}}}}], (max-width: 900px)", 5, 0},
        {"[{[}], (max-width: 900px)", 3, 2},
        {"[({)}], (max-width: 900px)", 3, 2},
        {"[]((), (max-width: 900px)", 2, 1},
        {"((), (max-width: 900px)", 2, 1},
        {"(foo(), (max-width: 900px)", 2, 1},
        {"[](()), (max-width: 900px)", 2, 0},
        {"all an[isdfs bla())(i())]icalc(i)(()), (max-width: 400px)", 3, 0},
        {"all an[isdfs bla())(]icalc(i)(()), (max-width: 500px)", 4, 2},
        {"all an[isdfs bla())(]icalc(i)(())), (max-width: 600px)", 4, 1},
        {"all an[isdfs bla())(]icalc(i)(()))], (max-width: 800px)", 4, 0},
        {0, 0, 0} // Do not remove the terminator line.
    };
    for (int i = 0; testCases[i].input; ++i) {
        Vector<MediaQueryToken> tokens;
        MediaQueryTokenizer::tokenize(testCases[i].input, tokens);
        MediaQueryBlockWatcher blockWatcher;

        unsigned maxLevel = 0;
        unsigned level = 0;
        for (size_t j = 0; j < tokens.size(); ++j) {
            blockWatcher.handleToken(tokens[j]);
            level = blockWatcher.blockLevel();
            maxLevel = std::max(level, maxLevel);
        }
        ASSERT_EQ(testCases[i].maxLevel, maxLevel);
        ASSERT_EQ(testCases[i].finalLevel, level);
    }
}

void testToken(UChar c, MediaQueryTokenType tokenType)
{
    Vector<MediaQueryToken> tokens;
    StringBuilder input;
    input.append(c);
    MediaQueryTokenizer::tokenize(input.toString(), tokens);
    ASSERT_EQ(tokens[0].type(), tokenType);
}

TEST(MediaQueryTokenizerCodepointsTest, Basic)
{
    for (UChar c = 0; c <= 1000; ++c) {
        if (isASCIIDigit(c))
            testToken(c, NumberToken);
        else if (isASCIIAlpha(c))
            testToken(c, IdentToken);
        else if (c == '_')
            testToken(c, IdentToken);
        else if (c == '\r' || c == ' ' || c == '\n' || c == '\t' || c == '\f')
            testToken(c, WhitespaceToken);
        else if (c == '(')
            testToken(c, LeftParenthesisToken);
        else if (c == ')')
            testToken(c, RightParenthesisToken);
        else if (c == '[')
            testToken(c, LeftBracketToken);
        else if (c == ']')
            testToken(c, RightBracketToken);
        else if (c == '{')
            testToken(c, LeftBraceToken);
        else if (c == '}')
            testToken(c, RightBraceToken);
        else if (c == '.' || c == '+' || c == '-' || c == '/' || c == '\\')
            testToken(c, DelimiterToken);
        else if (c == '\'' || c == '"')
            testToken(c, StringToken);
        else if (c == ',')
            testToken(c, CommaToken);
        else if (c == ':')
            testToken(c, ColonToken);
        else if (c == ';')
            testToken(c, SemicolonToken);
        else if (!c)
            testToken(c, EOFToken);
        else if (c > SCHAR_MAX)
            testToken(c, IdentToken);
        else
            testToken(c, DelimiterToken);
    }
    testToken(USHRT_MAX, IdentToken);
}

} // namespace
