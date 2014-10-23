// Use of this source code is governed by a BSD-style license that can be
// Copyright 2014 The Chromium Authors. All rights reserved.
// found in the LICENSE file.

#include "config.h"
#include "core/css/MediaValues.h"

#include "core/css/CSSPrimitiveValue.h"
#include "wtf/text/StringBuilder.h"

#include <gtest/gtest.h>

namespace blink {

struct TestCase {
    double value;
    CSSPrimitiveValue::UnitType type;
    unsigned fontSize;
    unsigned viewportWidth;
    unsigned viewportHeight;
    bool success;
    int output;
};

TEST(MediaValuesTest, Basic)
{
    TestCase testCases[] = {
        { 40.0, CSSPrimitiveValue::CSS_PX, 16, 300, 300, true, 40 },
        { 40.0, CSSPrimitiveValue::CSS_EMS, 16, 300, 300, true, 640 },
        { 40.0, CSSPrimitiveValue::CSS_REMS, 16, 300, 300, true, 640 },
        { 40.0, CSSPrimitiveValue::CSS_EXS, 16, 300, 300, true, 320 },
        { 40.0, CSSPrimitiveValue::CSS_CHS, 16, 300, 300, true, 320 },
        { 43.0, CSSPrimitiveValue::CSS_VW, 16, 848, 976, true, 364 },
        { 43.0, CSSPrimitiveValue::CSS_VH, 16, 848, 976, true, 419 },
        { 43.0, CSSPrimitiveValue::CSS_VMIN, 16, 848, 976, true, 364 },
        { 43.0, CSSPrimitiveValue::CSS_VMAX, 16, 848, 976, true, 419 },
        { 1.3, CSSPrimitiveValue::CSS_CM, 16, 300, 300, true, 49 },
        { 1.3, CSSPrimitiveValue::CSS_MM, 16, 300, 300, true, 4 },
        { 1.3, CSSPrimitiveValue::CSS_IN, 16, 300, 300, true, 124 },
        { 13, CSSPrimitiveValue::CSS_PT, 16, 300, 300, true, 17 },
        { 1.3, CSSPrimitiveValue::CSS_PC, 16, 300, 300, true, 20 },
        { 1.3, CSSPrimitiveValue::CSS_UNKNOWN, 16, 300, 300, false, 20 },
        { 0.0, CSSPrimitiveValue::CSS_UNKNOWN, 0, 0, 0, false, 0.0 } // Do not remove the terminating line.
    };


    for (unsigned i = 0; testCases[i].viewportWidth; ++i) {
        int output = 0;
        bool success = MediaValues::computeLength(testCases[i].value,
            testCases[i].type,
            testCases[i].fontSize,
            testCases[i].viewportWidth,
            testCases[i].viewportHeight,
            output);
        ASSERT_EQ(testCases[i].success, success);
        if (success)
            ASSERT_EQ(testCases[i].output, output);
    }
}

} // namespace
