// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/CSSTestHelper.h"
#include "core/css/RuleSet.h"

#include <gtest/gtest.h>

namespace blink {

TEST(CSSSelector, Representations)
{
    CSSTestHelper helper;

    const char* cssRules =
    "summary::-webkit-details-marker { }"
    "* {}"
    "div {}"
    "#id {}"
    ".class {}"
    "[attr] {}"
    "div:hover {}"
    "div:nth-child(2){}"
    ".class#id { }"
    "#id.class { }"
    "[attr]#id { }"
    "div[attr]#id { }"
    "div::content { }"
    "div::first-line { }"
    ".a.b.c { }"
    "div:not(.a) { }" // without class a
    "div:not(:visited) { }" // without the visited pseudo class

    "[attr=\"value\"] { }" // Exact equality
    "[attr~=\"value\"] { }" // One of a space-separated list
    "[attr^=\"value\"] { }" // Begins with
    "[attr$=\"value\"] { }" // Ends with
    "[attr*=\"value\"] { }" // Substring equal to
    "[attr|=\"value\"] { }" // One of a hyphen-separated list

    ".a .b { }" // .b is a descendant of .a
    ".a > .b { }" // .b is a direct descendant of .a
    ".a ~ .b { }" // .a precedes .b in sibling order
    ".a + .b { }" // .a element immediately precedes .b in sibling order
    ".a, .b { }" // matches .a or .b

    ".a.b .c {}";

    helper.addCSSRules(cssRules);
    EXPECT_EQ(30u, helper.ruleSet().ruleCount()); // .a, .b counts as two rules.
#ifndef NDEBUG
    helper.ruleSet().show();
#endif
}

} // namespace blink
