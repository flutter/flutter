// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/parser/HTMLSrcsetParser.h"

#include <gtest/gtest.h>
#include <limits.h>

namespace blink {

typedef struct {
    float deviceScaleFactor;
    int effectiveSize;
    const char* srcInput;
    const char* srcsetInput;
    const char* outputURL;
    float outputDensity;
    int outputResourceWidth;
} TestCase;

TEST(ImageCandidateTest, Basic)
{
    ImageCandidate candidate;
    ASSERT_EQ(candidate.density(), 1);
    ASSERT_EQ(candidate.resourceWidth(), -1);
    ASSERT_EQ(candidate.srcOrigin(), false);

}

TEST(HTMLSrcsetParserTest, Basic)
{
    TestCase testCases[] = {
        {2.0, -1, "", "1x.gif 1x, 2x.gif 2x", "2x.gif", 2.0, -1},
        {2.0, -1, "", "1x.gif 1q, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "", "1x.gif 1q, 2x.gif 2x", "1x.gif", 1.0, -1},
        {1.0, -1, "", "1x.gif 1x 100h, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "", "1x.gif 1x 100w, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "", "1x.gif 1x 100h 100w, 2x.gif 2x", "2x.gif", 2.0, -1},
        {2.0, -1, "", "1x.gif 1x, 2x.gif -2x", "1x.gif", 1.0, -1},
        {2.0, -1, "", "0x.gif 0x", "0x.gif", 0.0, -1},
        {2.0, -1, "", "0x.gif -0x", "0x.gif", 0.0, -1},
        {2.0, -1, "", "neg.gif -2x", "", 1.0, -1},
        {2.0, -1, "", "1x.gif 1x, 2x.gif 2q", "1x.gif", 1.0, -1},
        {2.0, -1, "", "1x.gif, 2x.gif 2q", "1x.gif", 1.0, -1},
        {2.0, -1, "", "1x.gif  , 2x.gif 2q", "1x.gif", 1.0, -1},
        {2.0, -1, "1x.gif 1x, 2x.gif 2x", "1x.gif 1x, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "1x.gif 1x, 2x.gif 2x", "1x.gif 1x, 2x.gif 2x", "1x.gif", 1.0, -1},
        {1.0, -1, "1x.gif 1x, 2x.gif 2x", "", "1x.gif 1x, 2x.gif 2x", 1.0, -1},
        {2.0, -1, "src.gif", "1x.gif 1x, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "src.gif", "1x.gif 1x, 2x.gif 2x", "1x.gif", 1.0, -1},
        {1.0, -1, "src.gif", "2x.gif 2x", "src.gif", 1.0, -1},
        {2.0, -1, "src.gif", "2x.gif 2x", "2x.gif", 2.0, -1},
        {2.0, -1, "src.gif", "2x.gif 2px", "src.gif", 1.0, -1},
        {2.0, -1, "src.gif", "2x.gif 2ex", "src.gif", 1.0, -1},
        {2.0, -1, "src.gif", "2x.gif 2e1x", "2x.gif", 20.0, -1},
        {2.0, -1, "src.gif", "2x.gif +2x", "2x.gif", 2.0, -1},
        {1.5, -1, "src.gif", "2x.gif 2x", "2x.gif", 2.0, -1},
        {2.5, -1, "src.gif", "2x.gif 2x", "2x.gif", 2.0, -1},
        {2.5, -1, "src.gif", "2x.gif 2x, 3x.gif 3x", "3x.gif", 3.0, -1},
        {2.0, -1, "", "1x,,  ,   x    ,2x  ", "1x", 1.0, -1},
        {2.0, -1, "", "1x,,  ,   x    ,2x  ", "1x", 1.0, -1},
        {2.0, -1, "", ",,1x,,  ,   x    ,2x  ", "1x", 1.0, -1},
        {2.0, -1, "", ",,1x,,", "1x", 1.0, -1},
        {2.0, -1, "", ",1x,", "1x", 1.0, -1},
        {2.0, -1, "", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg 1x, 2x.gif 2x", "2x.gif", 2.0, -1},
        {2.0, -1, "", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg 2x, 1x.gif 1x", "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg", 2.0, -1},
        {2.0, -1, "", "1x,,  ,   x    ,2x  , 1x.gif, 3x, 4x.gif 4x 100z, 5x.gif 5, dx.gif dx, 2x.gif   2x ,", "2x.gif", 2.0, -1},
        {4.0, -1, "", "1x,,  ,   x    ,2x  , 1x.gif, 3x, 4x.gif 4x 100h, 5x.gif 5, dx.gif dx, 2x.gif   2x ,", "2x.gif", 2.0, -1},
        {4.0, -1, "", "1x,,  ,   x    ,2x  , 1x.gif, 3x, 4x.gif 4x 100z, 5x.gif 5, dx.gif dx, 2x.gif   2x ,", "4x.gif", 4.0, -1},
        {1.0, -1, "", "1x,,  ,   x    ,2x  , 1x.gif, 3x, 4x.gif 4x 100z, 5x.gif 5, dx.gif dx, 2x.gif   2x ,", "1x", 1.0, -1},
        {5.0, -1, "", "1x,,  ,   x    ,2x  , 1x.gif, 3x, 4x.gif 4x 100z, 5x.gif 5, dx.gif dx, 2x.gif   2x ,", "4x.gif", 4.0, -1},
        {2.0, -1, "", "1x.gif 1x, data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIj4KCTxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJncmVlbiIvPgo8L3N2Zz4K 2x", "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIj4KCTxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJncmVlbiIvPgo8L3N2Zz4K", 2.0, -1 },
        {2.0, -1, "1x.gif", "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIj4KCTxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJncmVlbiIvPgo8L3N2Zz4K 2x", "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIj4KCTxyZWN0IHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJncmVlbiIvPgo8L3N2Zz4K", 2.0, -1 },
        {2.0, -1, "1x.svg#red", "1x.svg#green 2x", "1x.svg#green", 2.0, -1},
        {2.0, -1, "", "1x.svg#red 1x, 1x.svg#green 2x", "1x.svg#green", 2.0, -1},
        {1.0, 400, "", "400.gif 400w, 6000.gif 6000w", "400.gif", 1.0, 400},
        {1.0, 400, "", "400.gif 400pw, 6000.gif 6000w", "6000.gif", 15.0, 6000},
        {1.0, 400, "fallback.gif", "400.gif 400pw", "fallback.gif", 1.0, -1},
        {1.0, 400, "fallback.gif", "400.gif +400w", "400.gif", 1.0, 400},
        {1.0, 400, "", "400.gif 400w 400h, 6000.gif 6000w", "400.gif", 1.0, 400},
        {2.0, 400, "", "400.gif 400w, 6000.gif 6000w", "6000.gif", 15.0, 6000},
        {1.0, 400, "src.gif", "800.gif 800w", "800.gif", 2.0, 800},
        {1.0, 400, "src.gif", "0.gif 0w, 800.gif 800w", "800.gif", 2.0, 800},
        {1.0, 400, "src.gif", "0.gif 0w, 2x.gif 2x", "src.gif", 1.0, -1},
        {1.0, 400, "src.gif", "800.gif 2x, 1600.gif 1600w", "800.gif", 2.0, -1},
        {1.0, 400, "", "400.gif 400w, 2x.gif 2x", "400.gif", 1.0, 400},
        {2.0, 400, "", "400.gif 400w, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, 0, "", "400.gif 400w, 6000.gif 6000w", "400.gif", std::numeric_limits<float>::infinity(), 400},
        {2.0, -1, "", ", 1x.gif 1x, 2x.gif 2x", "2x.gif", 2.0, -1},
        {1.0, -1, "", ",1x.gif 1x, 2x.gif 2x", "1x.gif", 1.0, -1},
        {1.2, -1, "", ",1x.gif 1x, 1.4x.gif 1.4x, 2x.gif 2x", "1.4x.gif", 1.4, -1},
        {1.0, -1, "", "inf.gif 0.00000000001x", "inf.gif", 1e-11, -1},
        {1.0, -1, "", ",1x.gif 1x future-descriptor(3x, 4h, whatever), 2x.gif 2x", "1x.gif", 1.0, -1},
        {2.0, -1, "", ",1x.gif 1x future-descriptor(3x, 4h, whatever), 2x.gif 2x", "2x.gif", 2.0, -1},
        {0, 0, 0, 0, 0, 0} // Do not remove the terminator line.
    };

    for (unsigned i = 0; testCases[i].srcInput; ++i) {
        TestCase test = testCases[i];
        ImageCandidate candidate = bestFitSourceForImageAttributes(test.deviceScaleFactor, test.effectiveSize, test.srcInput, test.srcsetInput);
        ASSERT_EQ(test.outputDensity, candidate.density());
        ASSERT_EQ(test.outputResourceWidth, candidate.resourceWidth());
        ASSERT_STREQ(test.outputURL, candidate.toString().ascii().data());
    }
}

} // namespace
