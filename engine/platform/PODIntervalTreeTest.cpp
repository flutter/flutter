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

// Tests for the interval tree class.

#include "config.h"
#include "platform/PODIntervalTree.h"

#include "platform/Logging.h"
#include "platform/testing/TreeTestHelpers.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

#include <gtest/gtest.h>

namespace blink {

using TreeTestHelpers::initRandom;
using TreeTestHelpers::nextRandom;

#ifndef NDEBUG
template<>
struct ValueToString<float> {
    static String string(const float& value) { return String::number(value); }
};

template<>
struct ValueToString<void*> {
    static String string(void* const& value)
    {
        return String::format("0x%p", value);
    }
};
#endif

TEST(PODIntervalTreeTest, TestInsertion)
{
    PODIntervalTree<float> tree;
    tree.add(PODInterval<float>(2, 4));
    ASSERT_TRUE(tree.checkInvariants());
}

TEST(PODIntervalTreeTest, TestInsertionAndQuery)
{
    PODIntervalTree<float> tree;
    tree.add(PODInterval<float>(2, 4));
    ASSERT_TRUE(tree.checkInvariants());
    Vector<PODInterval<float> > result = tree.allOverlaps(PODInterval<float>(1, 3));
    EXPECT_EQ(1U, result.size());
    EXPECT_EQ(2, result[0].low());
    EXPECT_EQ(4, result[0].high());
}

TEST(PODIntervalTreeTest, TestQueryAgainstZeroSizeInterval)
{
    PODIntervalTree<float> tree;
    tree.add(PODInterval<float>(1, 2.5));
    tree.add(PODInterval<float>(3.5, 5));
    tree.add(PODInterval<float>(2, 4));
    ASSERT_TRUE(tree.checkInvariants());
    Vector<PODInterval<float> > result = tree.allOverlaps(PODInterval<float>(3, 3));
    EXPECT_EQ(1U, result.size());
    EXPECT_EQ(2, result[0].low());
    EXPECT_EQ(4, result[0].high());
}

#ifndef NDEBUG
template<>
struct ValueToString<int*> {
    static String string(int* const& value)
    {
        return String::format("0x%p", value);
    }
};
#endif

TEST(PODIntervalTreeTest, TestDuplicateElementInsertion)
{
    PODIntervalTree<float, int*> tree;
    int tmp1 = 1;
    int tmp2 = 2;
    typedef PODIntervalTree<float, int*>::IntervalType IntervalType;
    IntervalType interval1(1, 3, &tmp1);
    IntervalType interval2(1, 3, &tmp2);
    tree.add(interval1);
    tree.add(interval2);
    ASSERT_TRUE(tree.checkInvariants());
    EXPECT_TRUE(tree.contains(interval1));
    EXPECT_TRUE(tree.contains(interval2));
    EXPECT_TRUE(tree.remove(interval1));
    EXPECT_TRUE(tree.contains(interval2));
    EXPECT_FALSE(tree.contains(interval1));
    EXPECT_TRUE(tree.remove(interval2));
    EXPECT_EQ(0, tree.size());
}

namespace {

struct UserData1 {
public:
    UserData1()
        : a(0), b(1) { }

    float a;
    int b;
};

} // anonymous namespace

#ifndef NDEBUG
template<>
struct ValueToString<UserData1> {
    static String string(const UserData1& value)
    {
        return String("[UserData1 a=") + String::number(value.a) + " b=" + String::number(value.b) + "]";
    }
};
#endif

TEST(PODIntervalTreeTest, TestInsertionOfComplexUserData)
{
    PODIntervalTree<float, UserData1> tree;
    UserData1 data1;
    data1.a = 5;
    data1.b = 6;
    tree.add(tree.createInterval(2, 4, data1));
    ASSERT_TRUE(tree.checkInvariants());
}

TEST(PODIntervalTreeTest, TestQueryingOfComplexUserData)
{
    PODIntervalTree<float, UserData1> tree;
    UserData1 data1;
    data1.a = 5;
    data1.b = 6;
    tree.add(tree.createInterval(2, 4, data1));
    ASSERT_TRUE(tree.checkInvariants());
    Vector<PODInterval<float, UserData1> > overlaps = tree.allOverlaps(tree.createInterval(3, 5, data1));
    EXPECT_EQ(1U, overlaps.size());
    EXPECT_EQ(5, overlaps[0].data().a);
    EXPECT_EQ(6, overlaps[0].data().b);
}

namespace {

class EndpointType1 {
public:
    explicit EndpointType1(int value)
        : m_value(value) { }

    int value() const { return m_value; }

    bool operator<(const EndpointType1& other) const { return m_value < other.m_value; }
    bool operator==(const EndpointType1& other) const { return m_value == other.m_value; }

private:
    int m_value;
    // These operators should not be called by the interval tree.
    bool operator>(const EndpointType1& other);
    bool operator<=(const EndpointType1& other);
    bool operator>=(const EndpointType1& other);
    bool operator!=(const EndpointType1& other);
};

} // anonymous namespace

#ifndef NDEBUG
template<>
struct ValueToString<EndpointType1> {
    static String string(const EndpointType1& value)
    {
        return String("[EndpointType1 value=") + String::number(value.value()) + "]";
    }
};
#endif

TEST(PODIntervalTreeTest, TestTreeDoesNotRequireMostOperators)
{
    PODIntervalTree<EndpointType1> tree;
    tree.add(tree.createInterval(EndpointType1(1), EndpointType1(2)));
    ASSERT_TRUE(tree.checkInvariants());
}

// Uncomment to debug a failure of the insertion and deletion test. Won't work
// in release builds.
// #define DEBUG_INSERTION_AND_DELETION_TEST

#ifndef NDEBUG
template<>
struct ValueToString<int> {
    static String string(const int& value) { return String::number(value); }
};
#endif

namespace {

void InsertionAndDeletionTest(int32_t seed, int treeSize)
{
    initRandom(seed);
    int maximumValue = treeSize;
    // Build the tree
    PODIntervalTree<int> tree;
    Vector<PODInterval<int> > addedElements;
    Vector<PODInterval<int> > removedElements;
    for (int i = 0; i < treeSize; i++) {
        int left = nextRandom(maximumValue);
        int length = nextRandom(maximumValue);
        PODInterval<int> interval(left, left + length);
        tree.add(interval);
#ifdef DEBUG_INSERTION_AND_DELETION_TEST
        WTF_LOG_ERROR("*** Adding element %s", ValueToString<PODInterval<int> >::string(interval).ascii().data());
#endif
        addedElements.append(interval);
    }
    // Churn the tree's contents.
    // First remove half of the elements in random order.
    for (int i = 0; i < treeSize / 2; i++) {
        int index = nextRandom(addedElements.size());
#ifdef DEBUG_INSERTION_AND_DELETION_TEST
        WTF_LOG_ERROR("*** Removing element %s", ValueToString<PODInterval<int> >::string(addedElements[index]).ascii().data());
#endif
        ASSERT_TRUE(tree.contains(addedElements[index])) << "Test failed for seed " << seed;
        tree.remove(addedElements[index]);
        removedElements.append(addedElements[index]);
        addedElements.remove(index);
        ASSERT_TRUE(tree.checkInvariants()) << "Test failed for seed " << seed;
    }
    // Now randomly add or remove elements.
    for (int i = 0; i < 2 * treeSize; i++) {
        bool add = false;
        if (!addedElements.size())
            add = true;
        else if (!removedElements.size())
            add = false;
        else
            add = (nextRandom(2) == 1);
        if (add) {
            int index = nextRandom(removedElements.size());
#ifdef DEBUG_INSERTION_AND_DELETION_TEST
            WTF_LOG_ERROR("*** Adding element %s", ValueToString<PODInterval<int> >::string(removedElements[index]).ascii().data());
#endif
            tree.add(removedElements[index]);
            addedElements.append(removedElements[index]);
            removedElements.remove(index);
        } else {
            int index = nextRandom(addedElements.size());
#ifdef DEBUG_INSERTION_AND_DELETION_TEST
            WTF_LOG_ERROR("*** Removing element %s", ValueToString<PODInterval<int> >::string(addedElements[index]).ascii().data());
#endif
            ASSERT_TRUE(tree.contains(addedElements[index])) << "Test failed for seed " << seed;
            ASSERT_TRUE(tree.remove(addedElements[index])) << "Test failed for seed " << seed;
            removedElements.append(addedElements[index]);
            addedElements.remove(index);
        }
        ASSERT_TRUE(tree.checkInvariants()) << "Test failed for seed " << seed;
    }
}

} // anonymous namespace

TEST(PODIntervalTreeTest, RandomDeletionAndInsertionRegressionTest1)
{
    InsertionAndDeletionTest(13972, 100);
}

TEST(PODIntervalTreeTest, RandomDeletionAndInsertionRegressionTest2)
{
    InsertionAndDeletionTest(1283382113, 10);
}

TEST(PODIntervalTreeTest, RandomDeletionAndInsertionRegressionTest3)
{
    // This is the sequence of insertions and deletions that triggered
    // the failure in RandomDeletionAndInsertionRegressionTest2.
    PODIntervalTree<int> tree;
    tree.add(tree.createInterval(0, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(4, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(8, 9));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(1, 4));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(3, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(4, 12));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(0, 2));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(0, 2));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(9, 13));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(0, 1));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(0, 2));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(9, 13));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(0, 2));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(0, 1));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(4, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(4, 12));
    ASSERT_TRUE(tree.checkInvariants());
}

TEST(PODIntervalTreeTest, RandomDeletionAndInsertionRegressionTest4)
{
    // Even further reduced test case for RandomDeletionAndInsertionRegressionTest3.
    PODIntervalTree<int> tree;
    tree.add(tree.createInterval(0, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(8, 9));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(1, 4));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(3, 5));
    ASSERT_TRUE(tree.checkInvariants());
    tree.add(tree.createInterval(4, 12));
    ASSERT_TRUE(tree.checkInvariants());
    tree.remove(tree.createInterval(4, 12));
    ASSERT_TRUE(tree.checkInvariants());
}

} // namespace blink
