// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/SizesAttributeParser.h"

#include "core/MediaTypeNames.h"
#include "core/css/MediaValuesCached.h"

#include <gtest/gtest.h>

namespace blink {

typedef struct {
    const char* input;
    const unsigned effectiveSize;
    const bool viewportDependant;
} TestCase;

TEST(SizesAttributeParserTest, Basic)
{
    TestCase testCases[] = {
        {"screen", 500, true},
        {"(min-width:500px)", 500, true},
        {"(min-width:500px) 200px", 200, false},
        {"(min-width:500px) 50vw", 250, true},
        {"(min-width:500px) 200px, 400px", 200, false},
        {"400px, (min-width:500px) 200px", 400, false},
        {"40vw, (min-width:500px) 201px", 200, true},
        {"(min-width:500px) 201px, 40vw", 201, false},
        {"(min-width:5000px) 40vw, 201px", 201, false},
        {"(min-width:500px) calc(201px), calc(40vw)", 201, false},
        {"(min-width:5000px) calc(40vw), calc(201px)", 201, false},
        {"(min-width:5000px) 200px, 400px", 400, false},
        {"(blalbadfsdf) 200px, 400px", 400, false},
        {"0", 0, false},
        {"-0", 0, false},
        {"1", 500, true},
        {"300px, 400px", 300, false},
        {"(min-width:5000px) 200px, (min-width:500px) 400px", 400, false},
        {"", 500, true},
        {"  ", 500, true},
        {" /**/ ", 500, true},
        {" /**/ 300px", 300, false},
        {"300px /**/ ", 300, false},
        {" /**/ (min-width:500px) /**/ 300px", 300, false},
        {"-100px, 200px", 200, false},
        {"-50vw, 20vw", 100, true},
        {"50asdf, 200px", 200, false},
        {"asdf, 200px", 200, false},
        {"(max-width: 3000px) 200w, 400w", 500, true},
        {",, , /**/ ,200px", 200, false},
        {"50vw", 250, true},
        {"5em", 80, false},
        {"5rem", 80, false},
        {"calc(40vw*2)", 400, true},
        {"(min-width:5000px) calc(5000px/10), (min-width:500px) calc(1200px/3)", 400, false},
        {"(min-width:500px) calc(1200/3)", 500, true},
        {"(min-width:500px) calc(1200px/(0px*14))", 500, true},
        {"(max-width: 3000px) 200px, 400px", 200, false},
        {"(max-width: 3000px) 20em, 40em", 320, false},
        {"(max-width: 3000px) 0, 40em", 0, false},
        {"(max-width: 3000px) 50vw, 40em", 250, true},
        {"(max-width: 3000px) 50px, 40vw", 50, false},
        {0, 0, false} // Do not remove the terminator line.
    };

    MediaValuesCached::MediaValuesCachedData data;
    data.viewportWidth = 500;
    data.viewportHeight = 500;
    data.deviceWidth = 500;
    data.deviceHeight = 500;
    data.devicePixelRatio = 2.0;
    data.colorBitsPerComponent = 24;
    data.monochromeBitsPerComponent = 0;
    data.primaryPointerType = PointerTypeFine;
    data.defaultFontSize = 16;
    data.threeDEnabled = true;
    data.mediaType = MediaTypeNames::screen;
    data.strictMode = true;
    RefPtr<MediaValues> mediaValues = MediaValuesCached::create(data);

    for (unsigned i = 0; testCases[i].input; ++i) {
        SizesAttributeParser parser(mediaValues, testCases[i].input);
        ASSERT_EQ(testCases[i].effectiveSize, parser.length());
        ASSERT_EQ(testCases[i].viewportDependant, parser.viewportDependant());
    }
}

} // namespace
