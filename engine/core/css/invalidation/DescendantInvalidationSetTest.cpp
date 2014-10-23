// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/invalidation/DescendantInvalidationSet.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

// Once we setWholeSubtreeInvalid, we should not keep the HashSets.
TEST(DescendantInvalidationSetTest, SubtreeInvalid_AddBefore)
{
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set = DescendantInvalidationSet::create();
    set->addClass("a");
    set->setWholeSubtreeInvalid();

    ASSERT_TRUE(set->isEmpty());
}

// Don't (re)create HashSets if we've already setWholeSubtreeInvalid.
TEST(DescendantInvalidationSetTest, SubtreeInvalid_AddAfter)
{
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set = DescendantInvalidationSet::create();
    set->setWholeSubtreeInvalid();
    set->addTagName("a");

    ASSERT_TRUE(set->isEmpty());
}

// No need to keep the HashSets when combining with a wholeSubtreeInvalid set.
TEST(DescendantInvalidationSetTest, SubtreeInvalid_Combine_1)
{
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set1 = DescendantInvalidationSet::create();
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set2 = DescendantInvalidationSet::create();

    set1->addId("a");
    set2->setWholeSubtreeInvalid();

    set1->combine(*set2);

    ASSERT_TRUE(set1->wholeSubtreeInvalid());
    ASSERT_TRUE(set1->isEmpty());
}

// No need to add HashSets from combining set when we already have wholeSubtreeInvalid.
TEST(DescendantInvalidationSetTest, SubtreeInvalid_Combine_2)
{
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set1 = DescendantInvalidationSet::create();
    RefPtrWillBeRawPtr<DescendantInvalidationSet> set2 = DescendantInvalidationSet::create();

    set1->setWholeSubtreeInvalid();
    set2->addAttribute("a");

    set1->combine(*set2);

    ASSERT_TRUE(set1->wholeSubtreeInvalid());
    ASSERT_TRUE(set1->isEmpty());
}

} // namespace
