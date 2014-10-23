// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/parser/SizesCalcParser.h"

#include "core/MediaTypeNames.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/MediaValuesCached.h"
#include "core/css/StylePropertySet.h"
#include "core/css/parser/MediaQueryTokenizer.h"

#include <gtest/gtest.h>

namespace blink {

struct TestCase {
    const char* input;
    const unsigned output;
    const bool valid;
    const bool dontRunInCSSCalc;
    const bool viewportDependant;
};

static void initLengthArray(CSSLengthArray& lengthArray)
{
    lengthArray.resize(CSSPrimitiveValue::LengthUnitTypeCount);
    for (size_t i = 0; i < CSSPrimitiveValue::LengthUnitTypeCount; ++i)
        lengthArray.at(i) = 0;
}

static void verifyCSSCalc(String text, double value, bool valid, unsigned fontSize, unsigned viewportWidth, unsigned viewportHeight)
{
    CSSLengthArray lengthArray;
    initLengthArray(lengthArray);
    RefPtrWillBeRawPtr<MutableStylePropertySet> propertySet = MutableStylePropertySet::create();
    propertySet->setProperty(CSSPropertyLeft, text);
    RefPtrWillBeRawPtr<CSSValue> cssValue = propertySet->getPropertyCSSValue(CSSPropertyLeft);
    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(cssValue.get());
    if (primitiveValue)
        primitiveValue->accumulateLengthArray(lengthArray);
    else
        ASSERT_EQ(valid, false);
    int length = lengthArray.at(CSSPrimitiveValue::UnitTypePixels);
    length += lengthArray.at(CSSPrimitiveValue::UnitTypeFontSize) * fontSize;
    length += lengthArray.at(CSSPrimitiveValue::UnitTypeViewportWidth) * viewportWidth / 100.0;
    length += lengthArray.at(CSSPrimitiveValue::UnitTypeViewportHeight) * viewportHeight / 100.0;
    ASSERT_EQ(value, length);
}


TEST(SizesCalcParserTest, Basic)
{
    TestCase testCases[] = {
        {"calc(500px + 10em)", 660, true, false, false},
        {"calc(500px + 2 * 10em)", 820, true, false, false},
        {"calc(500px + 2*10em)", 820, true, false, false},
        {"calc(500px + 0.5*10em)", 580, true, false, false},
        {"calc(500px + (0.5*10em + 13px))", 593, true, false, false},
        {"calc(100vw + (0.5*10em + 13px))", 593, true, false, true},
        {"calc(100vh + (0.5*10em + 13px))", 736, true, false, true},
        {"calc(100vh + calc(0.5*10em + 13px))", 736, true, true, true}, // CSSCalculationValue does not parse internal "calc(".
        {"calc(100vh + (50%*10em + 13px))", 0, false, false, true},
        {"calc(50em+13px)", 0, false, false, false},
        {"calc(50em-13px)", 0, false, false, false},
        {"calc(500px + 10)", 0, false, false, false},
        {"calc(500 + 10)", 0, false, false, false},
        {"calc(500px + 10s)", 0, false, true, false}, // This test ASSERTs in CSSCalculationValue.
        {"calc(500px + 1cm)", 537, true, false, false},
        {"calc(500px - 10s)", 0, false, true, false}, // This test ASSERTs in CSSCalculationValue.
        {"calc(500px - 1cm)", 462, true, false, false},
        {"calc(500px - 1vw)", 495, true, false, true},
        {"calc(50px*10)", 500, true, false, false},
        {"calc(50px*10px)", 0, false, false, false},
        {"calc(50px/10px)", 0, false, false, false},
        {"calc(500px/10)", 50, true, false, false},
        {"calc(500/10)", 0, false, false, false},
        {"calc(500px/0.5)", 1000, true, false, false},
        {"calc(500px/.5)", 1000, true, false, false},
        {"calc(500/0)", 0, false, false, false},
        {"calc(500px/0)", 0, false, false, false},
        {"calc(-500px/10)", 0, true, true, false}, // CSSCalculationValue does not clamp negative values to 0.
        {"calc(((4) * ((10px))))", 40, true, false, false},
        {"calc(50px / 0)", 0, false, false, false},
        {"calc(50px / (10 + 10))", 2, true, false, false},
        {"calc(50px / (10 - 10))", 0, false, false, false},
        {"calc(50px / (10 * 10))", 0, true, false, false},
        {"calc(50px / (10 / 10))", 50, true, false, false},
        {"calc(200px*)", 0, false, false, false},
        {"calc(+ +200px)", 0, false, false, false},
        {"calc()", 0, false, false, false},
        {"calc(100px + + +100px)", 0, false, false, false},
        {"calc(200px 200px)", 0, false, false, false},
        {"calc(100px * * 2)", 0, false, false, false},
        {"calc(100px @ 2)", 0, false, false, false},
        {"calc(1 flim 2)", 0, false, false, false},
        {"calc(100px @ 2)", 0, false, false, false},
        {"calc(1 flim 2)", 0, false, false, false},
        {"calc(1 flim (2))", 0, false, false, false},
        {0, 0, true, false, false} // Do not remove the terminator line.
    };


    MediaValuesCached::MediaValuesCachedData data;
    data.viewportWidth = 500;
    data.viewportHeight = 643;
    data.deviceWidth = 500;
    data.deviceHeight = 643;
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
        Vector<MediaQueryToken> tokens;
        MediaQueryTokenizer::tokenize(testCases[i].input, tokens);
        SizesCalcParser calcParser(tokens.begin(), tokens.end(), mediaValues);
        ASSERT_EQ(testCases[i].valid, calcParser.isValid());
        if (calcParser.isValid()) {
            ASSERT_EQ(testCases[i].output, calcParser.result());
            ASSERT_EQ(testCases[i].viewportDependant, calcParser.viewportDependant());
        }
    }

    for (unsigned i = 0; testCases[i].input; ++i) {
        if (testCases[i].dontRunInCSSCalc)
            continue;
        verifyCSSCalc(testCases[i].input, testCases[i].output, testCases[i].valid, data.defaultFontSize, data.viewportWidth, data.viewportHeight);
    }
}

} // namespace
