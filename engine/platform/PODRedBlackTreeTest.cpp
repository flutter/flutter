/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// Tests for the red-black tree class.

#include "config.h"
#include "platform/PODRedBlackTree.h"

#include "platform/testing/ArenaTestHelpers.h"
#include "platform/testing/TreeTestHelpers.h"
#include "wtf/Vector.h"

#include <gtest/gtest.h>

namespace blink {

using ArenaTestHelpers::TrackedAllocator;
using TreeTestHelpers::initRandom;
using TreeTestHelpers::nextRandom;

TEST(PODRedBlackTreeTest, TestTreeAllocatesFromArena)
{
    RefPtr<TrackedAllocator> allocator = TrackedAllocator::create();
    {
        typedef PODFreeListArena<PODRedBlackTree<int>::Node> PODIntegerArena;
        RefPtr<PODIntegerArena> arena = PODIntegerArena::create(allocator);
        PODRedBlackTree<int> tree(arena);
        int numAdditions = 2 * PODArena::DefaultChunkSize / sizeof(int);
        for (int i = 0; i < numAdditions; ++i)
            tree.add(i);
        EXPECT_GT(allocator->numRegions(), 1);
    }
    EXPECT_EQ(allocator->numRegions(), 0);
}

TEST(PODRedBlackTreeTest, TestSingleElementInsertion)
{
    PODRedBlackTree<int> tree;
    tree.add(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(5));
}

TEST(PODRedBlackTreeTest, TestMultipleElementInsertion)
{
    PODRedBlackTree<int> tree;
    tree.add(4);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(4));
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(3));
    tree.add(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(5));
    EXPECT_TRUE(tree.contains(4));
    EXPECT_TRUE(tree.contains(3));
}

TEST(PODRedBlackTreeTest, TestDuplicateElementInsertion)
{
    PODRedBlackTree<int> tree;
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_EQ(3, tree.size());
    EXPECT_TRUE(tree.contains(3));
}

TEST(PODRedBlackTreeTest, TestSingleElementInsertionAndDeletion)
{
    PODRedBlackTree<int> tree;
    tree.add(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(5));
    tree.remove(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_FALSE(tree.contains(5));
}

TEST(PODRedBlackTreeTest, TestMultipleElementInsertionAndDeletion)
{
    PODRedBlackTree<int> tree;
    tree.add(4);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(4));
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(3));
    tree.add(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(5));
    EXPECT_TRUE(tree.contains(4));
    EXPECT_TRUE(tree.contains(3));
    tree.remove(4);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(3));
    EXPECT_FALSE(tree.contains(4));
    EXPECT_TRUE(tree.contains(5));
    tree.remove(5);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(3));
    EXPECT_FALSE(tree.contains(4));
    EXPECT_FALSE(tree.contains(5));
    EXPECT_EQ(1, tree.size());
}

TEST(PODRedBlackTreeTest, TestDuplicateElementInsertionAndDeletion)
{
    PODRedBlackTree<int> tree;
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_EQ(3, tree.size());
    EXPECT_TRUE(tree.contains(3));
    tree.remove(3);
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_EQ(1, tree.size());
    EXPECT_TRUE(tree.contains(3));
    tree.remove(3);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_EQ(0, tree.size());
    EXPECT_FALSE(tree.contains(3));
}

TEST(PODRedBlackTreeTest, FailingInsertionRegressionTest1)
{
    // These numbers came from a previously-failing randomized test run.
    PODRedBlackTree<int> tree;
    tree.add(5113);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(4517);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(3373);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(9307);
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(7077);
    ASSERT_TRUE(tree.checkInvariants());
}

namespace {
void InsertionAndDeletionTest(const int32_t seed, const int treeSize)
{
    initRandom(seed);
    const int maximumValue = treeSize;
    // Build the tree.
    PODRedBlackTree<int> tree;
    Vector<int> values;
    for (int i = 0; i < treeSize; i++) {
        int value = nextRandom(maximumValue);
        tree.add(value);
        ASSERT_TRUE(tree.checkInvariants()) << "Test failed for seed " << seed;
        values.append(value);
    }
    // Churn the tree's contents.
    for (int i = 0; i < treeSize; i++) {
        // Pick a random value to remove.
        int index = nextRandom(treeSize);
        int value = values[index];
        // Remove this value.
        tree.remove(value);
        ASSERT_TRUE(tree.checkInvariants()) << "Test failed for seed " << seed;
        // Replace it with a new one.
        value = nextRandom(maximumValue);
        values[index] = value;
        tree.add(value);
        ASSERT_TRUE(tree.checkInvariants()) << "Test failed for seed " << seed;
    }
}
} // anonymous namespace

TEST(PODRedBlackTreeTest, RandomDeletionAndInsertionRegressionTest1)
{
    InsertionAndDeletionTest(12311, 100);
}

} // namespace blink
