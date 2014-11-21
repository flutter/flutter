// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/animation/AnimationHelpers.h"

#include <gtest/gtest.h>

namespace blink {

TEST(AnimationAnimationHelpersTest, ParseCamelCasePropertyNames)
{
    EXPECT_EQ(CSSPropertyInvalid, camelCaseCSSPropertyNameToID(String("line-height")));
    EXPECT_EQ(CSSPropertyLineHeight, camelCaseCSSPropertyNameToID(String("lineHeight")));
    EXPECT_EQ(CSSPropertyBorderTopWidth, camelCaseCSSPropertyNameToID(String("borderTopWidth")));
    EXPECT_EQ(CSSPropertyWidth, camelCaseCSSPropertyNameToID(String("width")));
    EXPECT_EQ(CSSPropertyInvalid, camelCaseCSSPropertyNameToID(String("Width")));
    EXPECT_EQ(CSSPropertyInvalid, camelCaseCSSPropertyNameToID(String("-webkit-transform")));
    EXPECT_EQ(CSSPropertyInvalid, camelCaseCSSPropertyNameToID(String("webkitTransform")));
    EXPECT_EQ(CSSPropertyInvalid, camelCaseCSSPropertyNameToID(String("cssFloat")));
}

} // namespace blink
