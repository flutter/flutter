// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "wtf/DoubleBufferedDeque.h"

#include <gtest/gtest.h>

namespace {

typedef testing::Test DoubleBufferedDequeTest;

TEST(DoubleBufferedDequeTest, TestIsEmpty)
{
    DoubleBufferedDeque<int> queue;

    EXPECT_TRUE(queue.isEmpty());
    queue.append(1);
    EXPECT_FALSE(queue.isEmpty());
}

TEST(DoubleBufferedDequeTest, TestIsEmptyAfterSwapBuffers)
{
    DoubleBufferedDeque<int> queue;
    queue.append(1);

    queue.swapBuffers();
    EXPECT_TRUE(queue.isEmpty());
}

TEST(DoubleBufferedDequeTest, TestDoubleBuffering)
{
    DoubleBufferedDeque<int> queue;
    queue.append(1);
    queue.append(10);
    queue.append(100);

    {
        Deque<int>& deque = queue.swapBuffers();
        EXPECT_EQ(1, deque.takeFirst());
        EXPECT_EQ(10, deque.takeFirst());
        EXPECT_EQ(100, deque.takeFirst());
    }
    queue.append(2);

    EXPECT_EQ(2, queue.swapBuffers().takeFirst());
    queue.append(3);

    EXPECT_EQ(3, queue.swapBuffers().takeFirst());
}

} // namespace
