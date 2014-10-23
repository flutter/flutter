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

#include "config.h"
#include "platform/PODArena.h"

#include "platform/testing/ArenaTestHelpers.h"
#include "wtf/FastMalloc.h"
#include "wtf/RefPtr.h"

#include <algorithm>
#include <gtest/gtest.h>

namespace blink {

using ArenaTestHelpers::TrackedAllocator;

namespace {

// A couple of simple structs to allocate.
struct TestClass1 {
    TestClass1()
        : x(0), y(0), z(0), w(1) { }

    float x, y, z, w;
};

struct TestClass2 {
    TestClass2()
        : a(1), b(2), c(3), d(4) { }

    float a, b, c, d;
};

} // anonymous namespace

class PODArenaTest : public testing::Test {
};

// Make sure the arena can successfully allocate from more than one
// region.
TEST_F(PODArenaTest, CanAllocateFromMoreThanOneRegion)
{
    RefPtr<TrackedAllocator> allocator = TrackedAllocator::create();
    RefPtr<PODArena> arena = PODArena::create(allocator);
    int numIterations = 10 * PODArena::DefaultChunkSize / sizeof(TestClass1);
    for (int i = 0; i < numIterations; ++i)
        arena->allocateObject<TestClass1>();
    EXPECT_GT(allocator->numRegions(), 1);
}

// Make sure the arena frees all allocated regions during destruction.
TEST_F(PODArenaTest, FreesAllAllocatedRegions)
{
    RefPtr<TrackedAllocator> allocator = TrackedAllocator::create();
    {
        RefPtr<PODArena> arena = PODArena::create(allocator);
        for (int i = 0; i < 3; i++)
            arena->allocateObject<TestClass1>();
        EXPECT_GT(allocator->numRegions(), 0);
    }
    EXPECT_TRUE(allocator->isEmpty());
}

// Make sure the arena runs constructors of the objects allocated within.
TEST_F(PODArenaTest, RunsConstructors)
{
    RefPtr<PODArena> arena = PODArena::create();
    for (int i = 0; i < 10000; i++) {
        TestClass1* tc1 = arena->allocateObject<TestClass1>();
        EXPECT_EQ(0, tc1->x);
        EXPECT_EQ(0, tc1->y);
        EXPECT_EQ(0, tc1->z);
        EXPECT_EQ(1, tc1->w);
        TestClass2* tc2 = arena->allocateObject<TestClass2>();
        EXPECT_EQ(1, tc2->a);
        EXPECT_EQ(2, tc2->b);
        EXPECT_EQ(3, tc2->c);
        EXPECT_EQ(4, tc2->d);
    }
}

} // namespace blink
