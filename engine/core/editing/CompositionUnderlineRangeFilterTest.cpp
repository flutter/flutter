// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/editing/CompositionUnderlineRangeFilter.h"

#include "core/editing/CompositionUnderline.h"
#include "platform/graphics/Color.h"
#include "wtf/Vector.h"
#include "wtf/text/IntegerToStringConversion.h"
#include "wtf/text/WTFString.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

// Parses test case string and populate |underlines|.
void initUnderlines(const String& testCase, Vector<CompositionUnderline>* underlines)
{
    ASSERT(underlines && underlines->size() == 0U);
    Vector<String> rangeList;
    testCase.split('|', rangeList);
    // Intervals are named 'A', 'B', ..., 'Z', so ensure there aren't too many.
    ASSERT_LE(rangeList.size(), static_cast<size_t>('Z' - 'A'));
    for (unsigned i = 0; i < rangeList.size(); ++i) {
        String range = rangeList[i];
        Vector<String> toks;
        rangeList[i].split(',', toks);
        ASSERT_EQ(2U, toks.size());
        int startOffset = toks[0].toInt();
        int endOffset = toks[1].toInt();
        ASSERT_LE(startOffset, endOffset);
        // For testing: Store i in red component of |color|, so the intervals
        // can be distinguished.
        underlines->append(CompositionUnderline(startOffset, endOffset, Color(i, 0, 0), false, 0));
    }
}

// Runs the filter and encodes the result into a string, with 'A' as first
// elemnt, 'B' as second, etc.
String filterUnderlines(const Vector<CompositionUnderline>& underlines, int indexLo, int indexHi)
{
    CompositionUnderlineRangeFilter filter(underlines, indexLo, indexHi);
    String ret = "";
    for (CompositionUnderlineRangeFilter::ConstIterator it = filter.begin(); it != filter.end(); ++it) {
        int code = (*it).color.red();
        ret.append(static_cast<char>('A' + code));
    }
    return ret;
}

TEST(CompositionUnderlineRangeFilterTest, Empty)
{
    Vector<CompositionUnderline> underlines;
    EXPECT_EQ("", filterUnderlines(underlines, 0, 10));
    EXPECT_EQ("", filterUnderlines(underlines, 5, 5));
}

TEST(CompositionUnderlineRangeFilterTest, Single)
{
    String testCase = "10,20"; // Semi-closed interval: {10, 11, ..., 19}.
    Vector<CompositionUnderline> underlines;
    initUnderlines(testCase, &underlines);
    // The query intervals are all closed, e.g., [0, 9] = {0, ..., 9}.
    EXPECT_EQ("", filterUnderlines(underlines, 0, 9));
    EXPECT_EQ("A", filterUnderlines(underlines, 5, 10));
    EXPECT_EQ("A", filterUnderlines(underlines, 10, 20));
    EXPECT_EQ("A", filterUnderlines(underlines, 15, 25));
    EXPECT_EQ("A", filterUnderlines(underlines, 19, 30));
    EXPECT_EQ("", filterUnderlines(underlines, 20, 25));
    EXPECT_EQ("A", filterUnderlines(underlines, 5, 25));
}

TEST(CompositionUnderlineRangeFilterTest, Multi)
{
    String testCase = "0,2|0,5|1,3|1,10|3,5|5,8|7,8|8,10";
    Vector<CompositionUnderline> underlines;
    initUnderlines(testCase, &underlines);
    EXPECT_EQ("", filterUnderlines(underlines, 11, 11));
    EXPECT_EQ("ABCDEFGH", filterUnderlines(underlines, 0, 9));
    EXPECT_EQ("BDEF", filterUnderlines(underlines, 4, 5));
    EXPECT_EQ("AB", filterUnderlines(underlines, 0, 0));
    EXPECT_EQ("BDE", filterUnderlines(underlines, 3, 3));
    EXPECT_EQ("DF", filterUnderlines(underlines, 5, 5));
    EXPECT_EQ("DFG", filterUnderlines(underlines, 7, 7));
}

} // namespace
