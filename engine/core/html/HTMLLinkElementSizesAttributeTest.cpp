// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/HTMLLinkElement.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

class HTMLLinkElementSizesAttributeTest : public testing::Test {
};

TEST(HTMLLinkElementSizesAttributeTest, parseSizes)
{
    AtomicString sizesAttribute = "32x33";
    Vector<IntSize> sizes;
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(1U, sizes.size());
    EXPECT_EQ(32, sizes[0].width());
    EXPECT_EQ(33, sizes[0].height());

    UChar attribute[] = {'3', '2', 'x', '3', '3', 0};
    sizesAttribute = attribute;
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(1U, sizes.size());
    EXPECT_EQ(32, sizes[0].width());
    EXPECT_EQ(33, sizes[0].height());


    sizesAttribute = "   32x33   16X17    128x129   ";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(3U, sizes.size());
    EXPECT_EQ(32, sizes[0].width());
    EXPECT_EQ(33, sizes[0].height());
    EXPECT_EQ(16, sizes[1].width());
    EXPECT_EQ(17, sizes[1].height());
    EXPECT_EQ(128, sizes[2].width());
    EXPECT_EQ(129, sizes[2].height());

    sizesAttribute = "any";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());

    sizesAttribute = "32x33 32";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());

    sizesAttribute = "32x33 32x";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());

    sizesAttribute = "32x33 x32";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());

    sizesAttribute = "32x33 any";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());

    sizesAttribute = "32x33, 64x64";
    sizes.clear();
    HTMLLinkElement::parseSizesAttribute(sizesAttribute, sizes);
    ASSERT_EQ(0U, sizes.size());
}

} //  namespace
