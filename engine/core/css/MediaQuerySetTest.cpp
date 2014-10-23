// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/MediaQuery.h"

#include "core/css/MediaList.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/StringBuilder.h"

#include <gtest/gtest.h>

namespace blink {

typedef struct {
    const char* input;
    const char* output;
    bool shouldWorkOnOldParser;
} TestCase;

static void testMediaQuery(TestCase test, MediaQuerySet& querySet, bool oldParser)
{
    StringBuilder output;
    size_t j = 0;
    while (j < querySet.queryVector().size()) {
        String queryText = querySet.queryVector()[j]->cssText();
        output.append(queryText);
        ++j;
        if (j >= querySet.queryVector().size())
            break;
        output.appendLiteral(", ");
    }
    if (!oldParser || test.shouldWorkOnOldParser) {
        if (test.output)
            ASSERT_STREQ(test.output, output.toString().ascii().data());
        else
            ASSERT_STREQ(test.input, output.toString().ascii().data());
    }
}

TEST(MediaQuerySetTest, Basic)
{
    // The first string represents the input string.
    // The second string represents the output string, if present.
    // Otherwise, the output string is identical to the first string.
    TestCase testCases[] = {
        {"", 0, true},
        {" ", "", true},
        {"screen", 0, true},
        {"screen and (color)", 0, true},
        {"all and (min-width:500px)", "(min-width: 500px)", true},
        {"all and (min-width:/*bla*/500px)", "(min-width: 500px)", true},
        {"(min-width:500px)", "(min-width: 500px)", true},
        {"screen and (color), projection and (color)", 0, true},
        {"not screen and (color)", 0, true},
        {"only screen and (color)", 0, true},
        {"screen and (color), projection and (color)", 0, true},
        {"aural and (device-aspect-ratio: 16/9)", 0, true},
        {"speech and (min-device-width: 800px)", 0, true},
        {"example", 0, true},
        {"screen and (max-weight: 3kg) and (color), (monochrome)", "not all, (monochrome)", true},
        {"(min-width: -100px)", "not all", true},
        {"(example, all,), speech", "not all, speech", true},
        {"&test, screen", "not all, screen", true},
        {"print and (min-width: 25cm)", 0, true},
        {"screen and (min-width: 400px) and (max-width: 700px)", "screen and (max-width: 700px) and (min-width: 400px)", true},
        {"screen and (device-width: 800px)", 0, true},
        {"screen and (device-height: 60em)", 0, true},
        {"screen and (device-height: 60rem)", 0, true},
        {"screen and (device-height: 60ch)", 0, true},
        {"screen and (device-aspect-ratio: 16/9)", 0, true},
        {"(device-aspect-ratio: 16.0/9.0)", "not all", true},
        {"(device-aspect-ratio: 16/ 9)", "(device-aspect-ratio: 16/9)", true},
        {"(device-aspect-ratio: 16/\r9)", "(device-aspect-ratio: 16/9)", true},
        {"all and (color)", "(color)", true},
        {"all and (min-color: 1)", "(min-color: 1)", true},
        {"all and (min-color: 1.0)", "not all", true},
        {"all and (min-color: 2)", "(min-color: 2)", true},
        {"all and (color-index)", "(color-index)", true},
        {"all and (min-color-index: 1)", "(min-color-index: 1)", true},
        {"all and (monochrome)", "(monochrome)", true},
        {"all and (min-monochrome: 1)", "(min-monochrome: 1)", true},
        {"all and (min-monochrome: 2)", "(min-monochrome: 2)", true},
        {"print and (monochrome)", 0, true},
        {"handheld and (grid) and (max-width: 15em)", 0, true},
        {"handheld and (grid) and (max-device-height: 7em)", 0, true},
        {"screen and (max-width: 50%)", "not all", true},
        {"screen and (max-WIDTH: 500px)", "screen and (max-width: 500px)", true},
        {"screen and (max-width: 24.4em)", 0, true},
        {"screen and (max-width: 24.4EM)", "screen and (max-width: 24.4em)", true},
        {"screen and (max-width: blabla)", "not all", true},
        {"screen and (max-width: 1)", "not all", true},
        {"screen and (max-width: 0)", 0, true},
        {"screen and (max-width: 1deg)", "not all", true},
        {"handheld and (min-width: 20em), \nscreen and (min-width: 20em)", "handheld and (min-width: 20em), screen and (min-width: 20em)", true},
        {"print and (min-resolution: 300dpi)", 0, true},
        {"print and (min-resolution: 118dpcm)", 0, true},
        {"(resolution: 0.83333333333333333333dppx)", "(resolution: 0.833333333333333dppx)", true},
        {"(resolution: 2.4dppx)", 0, true},
        {"all and(color)", "not all", true},
        {"all and (", "not all", true},
        {"test;,all", "not all, all", true},
        {"(color:20example)", "not all", false},
        {"not braille", 0, true},
        {",screen", "not all, screen", true},
        {",all", "not all, all", true},
        {",,all,,", "not all, not all, all, not all, not all", true},
        {",,all,, ", "not all, not all, all, not all, not all", true},
        {",screen,,&invalid,,", "not all, screen, not all, not all, not all, not all", true},
        {",screen,,(invalid,),,", "not all, screen, not all, not all, not all, not all", true},
        {",(all,),,", "not all, not all, not all, not all", true},
        {",", "not all, not all", true},
        {"  ", "", true},
        {"(color", "(color)", true},
        {"(min-color: 2", "(min-color: 2)", true},
        {"(orientation: portrait)", 0, true},
        {"tv and (scan: progressive)", 0, true},
        {"(pointer: coarse)", 0, true},
        {"(min-orientation:portrait)", "not all", true},
        {"all and (orientation:portrait)", "(orientation: portrait)", true},
        {"all and (orientation:landscape)", "(orientation: landscape)", true},
        {"NOT braille, tv AND (max-width: 200px) and (min-WIDTH: 100px) and (orientation: landscape), (color)",
            "not braille, tv and (max-width: 200px) and (min-width: 100px) and (orientation: landscape), (color)", true},
        {"(m\\61x-width: 300px)", "(max-width: 300px)", true},
        {"(max-width: 400\\70\\78)", "(max-width: 400px)", false},
        {"(max-width: 500\\0070\\0078)", "(max-width: 500px)", false},
        {"(max-width: 600\\000070\\000078)", "(max-width: 600px)", false},
        {"(max-width: 700px), (max-width: 700px)", "(max-width: 700px), (max-width: 700px)", true},
        {"(max-width: 800px()), (max-width: 800px)", "not all, (max-width: 800px)", true},
        {"(max-width: 900px(()), (max-width: 900px)", "not all", true},
        {"(max-width: 600px(())))), (max-width: 600px)", "not all, (max-width: 600px)", true},
        {"(max-width: 500px(((((((((())))), (max-width: 500px)", "not all", true},
        {"(max-width: 800px[]), (max-width: 800px)", "not all, (max-width: 800px)", true},
        {"(max-width: 900px[[]), (max-width: 900px)", "not all", true},
        {"(max-width: 600px[[]]]]), (max-width: 600px)", "not all, (max-width: 600px)", true},
        {"(max-width: 500px[[[[[[[[[[]]]]), (max-width: 500px)", "not all", true},
        {"(max-width: 800px{}), (max-width: 800px)", "not all, (max-width: 800px)", true},
        {"(max-width: 900px{{}), (max-width: 900px)", "not all", true},
        {"(max-width: 600px{{}}}}), (max-width: 600px)", "not all, (max-width: 600px)", true},
        {"(max-width: 500px{{{{{{{{{{}}}}), (max-width: 500px)", "not all", true},
        {"[(), (max-width: 400px)", "not all", true},
        {"[{}, (max-width: 500px)", "not all", true},
        {"[{]}], (max-width: 900px)", "not all, (max-width: 900px)", true},
        {"[{[]{}{{{}}}}], (max-width: 900px)", "not all, (max-width: 900px)", true},
        {"[{[}], (max-width: 900px)", "not all", true},
        {"[({)}], (max-width: 900px)", "not all", true},
        {"[]((), (max-width: 900px)", "not all", true},
        {"((), (max-width: 900px)", "not all", true},
        {"(foo(), (max-width: 900px)", "not all", true},
        {"[](()), (max-width: 900px)", "not all, (max-width: 900px)", true},
        {"all an[isdfs bla())()]icalc(i)(()), (max-width: 400px)", "not all, (max-width: 400px)", true},
        {"all an[isdfs bla())(]icalc(i)(()), (max-width: 500px)", "not all", true},
        {"all an[isdfs bla())(]icalc(i)(())), (max-width: 600px)", "not all", true},
        {"all an[isdfs bla())(]icalc(i)(()))], (max-width: 800px)", "not all, (max-width: 800px)", true},
        {"(max-width: '40px')", "not all", true},
        {"('max-width': 40px)", "not all", true},
        {"'\"'\", (max-width: 900px)", "not all", true},
        {"'\"\"\"', (max-width: 900px)", "not all, (max-width: 900px)", true},
        {"\"'\"', (max-width: 900px)", "not all", true},
        {"\"'''\", (max-width: 900px)", "not all, (max-width: 900px)", true},
        {0, 0} // Do not remove the terminator line.
    };

    for (unsigned i = 0; testCases[i].input; ++i) {
        RefPtrWillBeRawPtr<MediaQuerySet> oldParserQuerySet = MediaQuerySet::create(testCases[i].input);
        RefPtrWillBeRawPtr<MediaQuerySet> threadSafeQuerySet = MediaQuerySet::createOffMainThread(testCases[i].input);
        testMediaQuery(testCases[i], *oldParserQuerySet, true);
        testMediaQuery(testCases[i], *threadSafeQuerySet, false);
    }
}

} // namespace
