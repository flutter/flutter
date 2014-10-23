/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "wtf/Deque.h"

#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include <gtest/gtest.h>

namespace {

TEST(DequeTest, Basic)
{
    Deque<int> intDeque;
    EXPECT_TRUE(intDeque.isEmpty());
    EXPECT_EQ(0ul, intDeque.size());
}

void checkNumberSequence(Deque<int>& deque, int from, int to, bool increment)
{
    Deque<int>::iterator it = increment ? deque.begin() : deque.end();
    size_t index = increment ? 0 : deque.size();
    int step = from < to ? 1 : -1;
    for (int i = from; i != to + step; i += step) {
        if (!increment) {
            --it;
            --index;
        }

        EXPECT_EQ(i, *it);
        EXPECT_EQ(i, deque[index]);

        if (increment) {
            ++it;
            ++index;
        }
    }
    EXPECT_EQ(increment ? deque.end() : deque.begin(), it);
    EXPECT_EQ(increment ? deque.size() : 0, index);
}

void checkNumberSequenceReverse(Deque<int>& deque, int from, int to, bool increment)
{
    Deque<int>::reverse_iterator it = increment ? deque.rbegin() : deque.rend();
    size_t index = increment ? 0 : deque.size();
    int step = from < to ? 1 : -1;
    for (int i = from; i != to + step; i += step) {
        if (!increment) {
            --it;
            --index;
        }

        EXPECT_EQ(i, *it);
        EXPECT_EQ(i, deque.at(deque.size() - 1 - index));

        if (increment) {
            ++it;
            ++index;
        }
    }
    EXPECT_EQ(increment ? deque.rend() : deque.rbegin(), it);
    EXPECT_EQ(increment ? deque.size() : 0, index);
}

TEST(DequeTest, Reverse)
{
    Deque<int> intDeque;
    intDeque.append(10);
    intDeque.append(11);
    intDeque.append(12);
    intDeque.append(13);

    checkNumberSequence(intDeque, 10, 13, true);
    checkNumberSequence(intDeque, 13, 10, false);
    checkNumberSequenceReverse(intDeque, 13, 10, true);
    checkNumberSequenceReverse(intDeque, 10, 13, false);

    intDeque.append(14);
    intDeque.append(15);
    EXPECT_EQ(10, intDeque.takeFirst());
    EXPECT_EQ(15, intDeque.takeLast());
    checkNumberSequence(intDeque, 11, 14, true);
    checkNumberSequence(intDeque, 14, 11, false);
    checkNumberSequenceReverse(intDeque, 14, 11, true);
    checkNumberSequenceReverse(intDeque, 11, 14, false);

    for (int i = 15; i < 200; ++i)
        intDeque.append(i);
    checkNumberSequence(intDeque, 11, 199, true);
    checkNumberSequence(intDeque, 199, 11, false);
    checkNumberSequenceReverse(intDeque, 199, 11, true);
    checkNumberSequenceReverse(intDeque, 11, 199, false);

    for (int i = 0; i < 180; ++i) {
        EXPECT_EQ(i + 11, intDeque[0]);
        EXPECT_EQ(i + 11, intDeque.takeFirst());
    }
    checkNumberSequence(intDeque, 191, 199, true);
    checkNumberSequence(intDeque, 199, 191, false);
    checkNumberSequenceReverse(intDeque, 199, 191, true);
    checkNumberSequenceReverse(intDeque, 191, 199, false);

    Deque<int> intDeque2;
    swap(intDeque, intDeque2);

    checkNumberSequence(intDeque2, 191, 199, true);
    checkNumberSequence(intDeque2, 199, 191, false);
    checkNumberSequenceReverse(intDeque2, 199, 191, true);
    checkNumberSequenceReverse(intDeque2, 191, 199, false);

    intDeque.swap(intDeque2);

    checkNumberSequence(intDeque, 191, 199, true);
    checkNumberSequence(intDeque, 199, 191, false);
    checkNumberSequenceReverse(intDeque, 199, 191, true);
    checkNumberSequenceReverse(intDeque, 191, 199, false);

    intDeque.swap(intDeque2);

    checkNumberSequence(intDeque2, 191, 199, true);
    checkNumberSequence(intDeque2, 199, 191, false);
    checkNumberSequenceReverse(intDeque2, 199, 191, true);
    checkNumberSequenceReverse(intDeque2, 191, 199, false);
}

class DestructCounter {
public:
    explicit DestructCounter(int i, int* destructNumber)
        : m_i(i)
        , m_destructNumber(destructNumber)
    { }

    ~DestructCounter() { ++(*m_destructNumber); }
    int get() const { return m_i; }

private:
    int m_i;
    int* m_destructNumber;
};

typedef WTF::Deque<OwnPtr<DestructCounter> > OwnPtrDeque;

TEST(DequeTest, OwnPtr)
{
    int destructNumber = 0;
    OwnPtrDeque deque;
    deque.append(adoptPtr(new DestructCounter(0, &destructNumber)));
    deque.append(adoptPtr(new DestructCounter(1, &destructNumber)));
    EXPECT_EQ(2u, deque.size());

    OwnPtr<DestructCounter>& counter0 = deque.first();
    EXPECT_EQ(0, counter0->get());
    int counter1 = deque.last()->get();
    EXPECT_EQ(1, counter1);
    EXPECT_EQ(0, destructNumber);

    size_t index = 0;
    for (OwnPtrDeque::iterator iter = deque.begin(); iter != deque.end(); ++iter) {
        OwnPtr<DestructCounter>& refCounter = *iter;
        EXPECT_EQ(index, static_cast<size_t>(refCounter->get()));
        EXPECT_EQ(index, static_cast<size_t>((*refCounter).get()));
        index++;
    }
    EXPECT_EQ(0, destructNumber);

    OwnPtrDeque::iterator it = deque.begin();
    for (index = 0; index < deque.size(); ++index) {
        OwnPtr<DestructCounter>& refCounter = *it;
        EXPECT_EQ(index, static_cast<size_t>(refCounter->get()));
        index++;
        ++it;
    }
    EXPECT_EQ(0, destructNumber);

    EXPECT_EQ(0, deque.first()->get());
    deque.removeFirst();
    EXPECT_EQ(1, deque.first()->get());
    EXPECT_EQ(1u, deque.size());
    EXPECT_EQ(1, destructNumber);

    OwnPtr<DestructCounter> ownCounter1 = deque.first().release();
    deque.removeFirst();
    EXPECT_EQ(counter1, ownCounter1->get());
    EXPECT_EQ(0u, deque.size());
    EXPECT_EQ(1, destructNumber);

    ownCounter1.clear();
    EXPECT_EQ(2, destructNumber);

    size_t count = 1025;
    destructNumber = 0;
    for (size_t i = 0; i < count; ++i)
        deque.prepend(adoptPtr(new DestructCounter(i, &destructNumber)));

    // Deque relocation must not destruct OwnPtr element.
    EXPECT_EQ(0, destructNumber);
    EXPECT_EQ(count, deque.size());

    OwnPtrDeque copyDeque;
    deque.swap(copyDeque);
    EXPECT_EQ(0, destructNumber);
    EXPECT_EQ(count, copyDeque.size());
    EXPECT_EQ(0u, deque.size());

    copyDeque.clear();
    EXPECT_EQ(count, static_cast<size_t>(destructNumber));
}

// WrappedInt class will fail if it was memmoved or memcpyed.
static HashSet<void*> constructedWrappedInts;
class WrappedInt {
public:
    WrappedInt(int i = 0)
        : m_originalThisPtr(this)
        , m_i(i)
    {
        constructedWrappedInts.add(this);
    }

    WrappedInt(const WrappedInt& other)
        : m_originalThisPtr(this)
        , m_i(other.m_i)
    {
        constructedWrappedInts.add(this);
    }

    WrappedInt& operator=(const WrappedInt& other)
    {
        m_i = other.m_i;
        return *this;
    }

    ~WrappedInt()
    {
        EXPECT_EQ(m_originalThisPtr, this);
        EXPECT_TRUE(constructedWrappedInts.contains(this));
        constructedWrappedInts.remove(this);
    }

    int get() const { return m_i; }

private:
    void* m_originalThisPtr;
    int m_i;
};

TEST(DequeTest, SwapWithoutInlineCapacity)
{
    Deque<WrappedInt> dequeA;
    dequeA.append(WrappedInt(1));
    Deque<WrappedInt> dequeB;
    dequeB.append(WrappedInt(2));

    ASSERT_EQ(dequeA.size(), dequeB.size());
    dequeA.swap(dequeB);

    ASSERT_EQ(1u, dequeA.size());
    EXPECT_EQ(2, dequeA.first().get());
    ASSERT_EQ(1u, dequeB.size());
    EXPECT_EQ(1, dequeB.first().get());

    dequeA.append(WrappedInt(3));

    ASSERT_GT(dequeA.size(), dequeB.size());
    dequeA.swap(dequeB);

    ASSERT_EQ(1u, dequeA.size());
    EXPECT_EQ(1, dequeA.first().get());
    ASSERT_EQ(2u, dequeB.size());
    EXPECT_EQ(2, dequeB.first().get());

    ASSERT_LT(dequeA.size(), dequeB.size());
    dequeA.swap(dequeB);

    ASSERT_EQ(2u, dequeA.size());
    EXPECT_EQ(2, dequeA.first().get());
    ASSERT_EQ(1u, dequeB.size());
    EXPECT_EQ(1, dequeB.first().get());

    dequeA.append(WrappedInt(4));
    dequeA.swap(dequeB);

    ASSERT_EQ(1u, dequeA.size());
    EXPECT_EQ(1, dequeA.first().get());
    ASSERT_EQ(3u, dequeB.size());
    EXPECT_EQ(2, dequeB.first().get());

    dequeB.swap(dequeA);
}

} // namespace
