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

#include <gtest/gtest.h>
#include "flutter/sky/engine/wtf/HashSet.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace {

TEST(VectorTest, Basic) {
  Vector<int> intVector;
  EXPECT_TRUE(intVector.isEmpty());
  EXPECT_EQ(0ul, intVector.size());
  EXPECT_EQ(0ul, intVector.capacity());
}

TEST(VectorTest, Reverse) {
  Vector<int> intVector;
  intVector.append(10);
  intVector.append(11);
  intVector.append(12);
  intVector.append(13);
  intVector.reverse();

  EXPECT_EQ(13, intVector[0]);
  EXPECT_EQ(12, intVector[1]);
  EXPECT_EQ(11, intVector[2]);
  EXPECT_EQ(10, intVector[3]);

  intVector.append(9);
  intVector.reverse();

  EXPECT_EQ(9, intVector[0]);
  EXPECT_EQ(10, intVector[1]);
  EXPECT_EQ(11, intVector[2]);
  EXPECT_EQ(12, intVector[3]);
  EXPECT_EQ(13, intVector[4]);
}

TEST(VectorTest, Iterator) {
  Vector<int> intVector;
  intVector.append(10);
  intVector.append(11);
  intVector.append(12);
  intVector.append(13);

  Vector<int>::iterator it = intVector.begin();
  Vector<int>::iterator end = intVector.end();
  EXPECT_TRUE(end != it);

  EXPECT_EQ(10, *it);
  ++it;
  EXPECT_EQ(11, *it);
  ++it;
  EXPECT_EQ(12, *it);
  ++it;
  EXPECT_EQ(13, *it);
  ++it;

  EXPECT_TRUE(end == it);
}

TEST(VectorTest, ReverseIterator) {
  Vector<int> intVector;
  intVector.append(10);
  intVector.append(11);
  intVector.append(12);
  intVector.append(13);

  Vector<int>::reverse_iterator it = intVector.rbegin();
  Vector<int>::reverse_iterator end = intVector.rend();
  EXPECT_TRUE(end != it);

  EXPECT_EQ(13, *it);
  ++it;
  EXPECT_EQ(12, *it);
  ++it;
  EXPECT_EQ(11, *it);
  ++it;
  EXPECT_EQ(10, *it);
  ++it;

  EXPECT_TRUE(end == it);
}

class DestructCounter {
 public:
  explicit DestructCounter(int i, int* destructNumber)
      : m_i(i), m_destructNumber(destructNumber) {}

  ~DestructCounter() { ++(*m_destructNumber); }
  int get() const { return m_i; }

 private:
  int m_i;
  int* m_destructNumber;
};

typedef WTF::Vector<OwnPtr<DestructCounter>> OwnPtrVector;

TEST(VectorTest, OwnPtr) {
  int destructNumber = 0;
  OwnPtrVector vector;
  vector.append(adoptPtr(new DestructCounter(0, &destructNumber)));
  vector.append(adoptPtr(new DestructCounter(1, &destructNumber)));
  EXPECT_EQ(2u, vector.size());

  OwnPtr<DestructCounter>& counter0 = vector.first();
  ASSERT_EQ(0, counter0->get());
  int counter1 = vector.last()->get();
  ASSERT_EQ(1, counter1);
  ASSERT_EQ(0, destructNumber);

  size_t index = 0;
  for (OwnPtrVector::iterator iter = vector.begin(); iter != vector.end();
       ++iter) {
    OwnPtr<DestructCounter>* refCounter = iter;
    EXPECT_EQ(index, static_cast<size_t>(refCounter->get()->get()));
    EXPECT_EQ(index, static_cast<size_t>((*refCounter)->get()));
    index++;
  }
  EXPECT_EQ(0, destructNumber);

  for (index = 0; index < vector.size(); index++) {
    OwnPtr<DestructCounter>& refCounter = vector[index];
    EXPECT_EQ(index, static_cast<size_t>(refCounter->get()));
    index++;
  }
  EXPECT_EQ(0, destructNumber);

  EXPECT_EQ(0, vector[0]->get());
  EXPECT_EQ(1, vector[1]->get());
  vector.remove(0);
  EXPECT_EQ(1, vector[0]->get());
  EXPECT_EQ(1u, vector.size());
  EXPECT_EQ(1, destructNumber);

  OwnPtr<DestructCounter> ownCounter1 = vector[0].release();
  vector.remove(0);
  ASSERT_EQ(counter1, ownCounter1->get());
  ASSERT_EQ(0u, vector.size());
  ASSERT_EQ(1, destructNumber);

  ownCounter1.clear();
  EXPECT_EQ(2, destructNumber);

  size_t count = 1025;
  destructNumber = 0;
  for (size_t i = 0; i < count; i++)
    vector.prepend(adoptPtr(new DestructCounter(i, &destructNumber)));

  // Vector relocation must not destruct OwnPtr element.
  EXPECT_EQ(0, destructNumber);
  EXPECT_EQ(count, vector.size());

  OwnPtrVector copyVector;
  vector.swap(copyVector);
  EXPECT_EQ(0, destructNumber);
  EXPECT_EQ(count, copyVector.size());
  EXPECT_EQ(0u, vector.size());

  copyVector.clear();
  EXPECT_EQ(count, static_cast<size_t>(destructNumber));
}

// WrappedInt class will fail if it was memmoved or memcpyed.
static HashSet<void*> constructedWrappedInts;
class WrappedInt {
 public:
  WrappedInt(int i = 0) : m_originalThisPtr(this), m_i(i) {
    constructedWrappedInts.add(this);
  }

  WrappedInt(const WrappedInt& other)
      : m_originalThisPtr(this), m_i(other.m_i) {
    constructedWrappedInts.add(this);
  }

  WrappedInt& operator=(const WrappedInt& other) {
    m_i = other.m_i;
    return *this;
  }

  ~WrappedInt() {
    EXPECT_EQ(m_originalThisPtr, this);
    EXPECT_TRUE(constructedWrappedInts.contains(this));
    constructedWrappedInts.remove(this);
  }

  int get() const { return m_i; }

 private:
  void* m_originalThisPtr;
  int m_i;
};

TEST(VectorTest, SwapWithInlineCapacity) {
  const size_t inlineCapacity = 2;
  Vector<WrappedInt, inlineCapacity> vectorA;
  vectorA.append(WrappedInt(1));
  Vector<WrappedInt, inlineCapacity> vectorB;
  vectorB.append(WrappedInt(2));

  EXPECT_EQ(vectorA.size(), vectorB.size());
  vectorA.swap(vectorB);

  EXPECT_EQ(1u, vectorA.size());
  EXPECT_EQ(2, vectorA.at(0).get());
  EXPECT_EQ(1u, vectorB.size());
  EXPECT_EQ(1, vectorB.at(0).get());

  vectorA.append(WrappedInt(3));

  EXPECT_GT(vectorA.size(), vectorB.size());
  vectorA.swap(vectorB);

  EXPECT_EQ(1u, vectorA.size());
  EXPECT_EQ(1, vectorA.at(0).get());
  EXPECT_EQ(2u, vectorB.size());
  EXPECT_EQ(2, vectorB.at(0).get());
  EXPECT_EQ(3, vectorB.at(1).get());

  EXPECT_LT(vectorA.size(), vectorB.size());
  vectorA.swap(vectorB);

  EXPECT_EQ(2u, vectorA.size());
  EXPECT_EQ(2, vectorA.at(0).get());
  EXPECT_EQ(3, vectorA.at(1).get());
  EXPECT_EQ(1u, vectorB.size());
  EXPECT_EQ(1, vectorB.at(0).get());

  vectorA.append(WrappedInt(4));
  EXPECT_GT(vectorA.size(), inlineCapacity);
  vectorA.swap(vectorB);

  EXPECT_EQ(1u, vectorA.size());
  EXPECT_EQ(1, vectorA.at(0).get());
  EXPECT_EQ(3u, vectorB.size());
  EXPECT_EQ(2, vectorB.at(0).get());
  EXPECT_EQ(3, vectorB.at(1).get());
  EXPECT_EQ(4, vectorB.at(2).get());

  vectorB.swap(vectorA);
}

class Comparable {};
bool operator==(const Comparable& a, const Comparable& b) {
  return true;
}

template <typename T>
void compare() {
  EXPECT_TRUE(Vector<T>() == Vector<T>());
  EXPECT_FALSE(Vector<T>(1) == Vector<T>(0));
  EXPECT_FALSE(Vector<T>() == Vector<T>(1));
  EXPECT_TRUE(Vector<T>(1) == Vector<T>(1));
}

TEST(VectorTest, Compare) {
  compare<int>();
  compare<Comparable>();
  compare<WTF::String>();
}
}  // namespace
