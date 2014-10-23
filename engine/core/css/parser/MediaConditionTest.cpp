// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/css/MediaList.h"
#include "core/css/MediaQuery.h"
#include "core/css/parser/MediaQueryParser.h"
#include "core/css/parser/MediaQueryTokenizer.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/StringBuilder.h"

#include <gtest/gtest.h>

namespace blink {

typedef struct {
    const char* input;
    const char* output;
} TestCase;

TEST(MediaConditionParserTest, Basic)
{
    // The first string represents the input string.
    // The second string represents the output string, if present.
    // Otherwise, the output string is identical to the first string.
    TestCase testCases[] = {
        {"screen", "not all"},
        {"screen and (color)", "not all"},
        {"all and (min-width:500px)", "not all"},
        {"(min-width:500px)", "(min-width: 500px)"},
        {"screen and (color), projection and (color)", "not all"},
        {"(min-width: -100px)", "not all"},
        {"(min-width: 100px) and print", "not all"},
        {"(min-width: 100px) and (max-width: 900px)", "(max-width: 900px) and (min-width: 100px)"},
        {"(min-width: [100px) and (max-width: 900px)", "not all"},
        {0, 0} // Do not remove the terminator line.
    };

    for (unsigned i = 0; testCases[i].input; ++i) {
        Vector<MediaQueryToken> tokens;
        MediaQueryTokenizer::tokenize(testCases[i].input, tokens);
        MediaQueryTokenIterator endToken;
        // Stop the input once we hit a comma token
        for (endToken = tokens.begin(); endToken != tokens.end() && endToken->type() != CommaToken; ++endToken) { }
        RefPtrWillBeRawPtr<MediaQuerySet> mediaConditionQuerySet = MediaQueryParser::parseMediaCondition(tokens.begin(), endToken);
        ASSERT_EQ(mediaConditionQuerySet->queryVector().size(), (unsigned)1);
        String queryText = mediaConditionQuerySet->queryVector()[0]->cssText();
        ASSERT_STREQ(testCases[i].output, queryText.ascii().data());
    }
}

} // namespace
