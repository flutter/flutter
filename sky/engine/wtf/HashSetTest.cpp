/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
#include "flutter/sky/engine/wtf/RefCounted.h"

namespace {

template <int initialCapacity>
struct InitialCapacityTestHashTraits
    : public WTF::UnsignedWithZeroKeyHashTraits<int> {
  static const int minimumTableSize = initialCapacity;
};

template <unsigned size>
void testInitialCapacity() {
  const unsigned initialCapacity = WTF::HashTableCapacityForSize<size>::value;
  HashSet<int, DefaultHash<int>::Hash,
          InitialCapacityTestHashTraits<initialCapacity>>
      testSet;

  // Initial capacity is null.
  EXPECT_EQ(0UL, testSet.capacity());

  // Adding items up to size should never change the capacity.
  for (size_t i = 0; i < size; ++i) {
    testSet.add(i);
    EXPECT_EQ(initialCapacity, testSet.capacity());
  }

  // Adding items up to less than half the capacity should not change the
  // capacity.
  unsigned capacityLimit = initialCapacity / 2 - 1;
  for (size_t i = size; i < capacityLimit; ++i) {
    testSet.add(i);
    EXPECT_EQ(initialCapacity, testSet.capacity());
  }

  // Adding one more item increase the capacity.
  testSet.add(initialCapacity);
  EXPECT_GT(testSet.capacity(), initialCapacity);
}

template <unsigned size>
void generateTestCapacityUpToSize();
template <>
void generateTestCapacityUpToSize<0>() {}
template <unsigned size>
void generateTestCapacityUpToSize() {
  generateTestCapacityUpToSize<size - 1>();
  testInitialCapacity<size>();
}

TEST(HashSetTest, InitialCapacity) {
  generateTestCapacityUpToSize<128>();
}

struct Dummy {
  Dummy(bool& deleted) : deleted(deleted) {}

  ~Dummy() { deleted = true; }

  bool& deleted;
};

TEST(HashSetTest, HashSetOwnPtr) {
  bool deleted1 = false, deleted2 = false;

  typedef HashSet<OwnPtr<Dummy>> OwnPtrSet;
  OwnPtrSet set;

  Dummy* ptr1 = new Dummy(deleted1);
  {
    // AddResult in a separate scope to avoid assertion hit,
    // since we modify the container further.
    HashSet<OwnPtr<Dummy>>::AddResult res1 = set.add(adoptPtr(ptr1));
    EXPECT_EQ(ptr1, res1.storedValue->get());
  }

  EXPECT_FALSE(deleted1);
  EXPECT_EQ(1UL, set.size());
  OwnPtrSet::iterator it1 = set.find(ptr1);
  EXPECT_NE(set.end(), it1);
  EXPECT_EQ(ptr1, (*it1));

  Dummy* ptr2 = new Dummy(deleted2);
  {
    HashSet<OwnPtr<Dummy>>::AddResult res2 = set.add(adoptPtr(ptr2));
    EXPECT_EQ(res2.storedValue->get(), ptr2);
  }

  EXPECT_FALSE(deleted2);
  EXPECT_EQ(2UL, set.size());
  OwnPtrSet::iterator it2 = set.find(ptr2);
  EXPECT_NE(set.end(), it2);
  EXPECT_EQ(ptr2, (*it2));

  set.remove(ptr1);
  EXPECT_TRUE(deleted1);

  set.clear();
  EXPECT_TRUE(deleted2);
  EXPECT_TRUE(set.isEmpty());

  deleted1 = false;
  deleted2 = false;
  {
    OwnPtrSet set;
    set.add(adoptPtr(new Dummy(deleted1)));
    set.add(adoptPtr(new Dummy(deleted2)));
  }
  EXPECT_TRUE(deleted1);
  EXPECT_TRUE(deleted2);

  deleted1 = false;
  deleted2 = false;
  OwnPtr<Dummy> ownPtr1;
  OwnPtr<Dummy> ownPtr2;
  ptr1 = new Dummy(deleted1);
  ptr2 = new Dummy(deleted2);
  {
    OwnPtrSet set;
    set.add(adoptPtr(ptr1));
    set.add(adoptPtr(ptr2));
    ownPtr1 = set.take(ptr1);
    EXPECT_EQ(1UL, set.size());
    ownPtr2 = set.takeAny();
    EXPECT_TRUE(set.isEmpty());
  }
  EXPECT_FALSE(deleted1);
  EXPECT_FALSE(deleted2);

  EXPECT_EQ(ptr1, ownPtr1);
  EXPECT_EQ(ptr2, ownPtr2);
}

class DummyRefCounted : public WTF::RefCounted<DummyRefCounted> {
 public:
  DummyRefCounted(bool& isDeleted) : m_isDeleted(isDeleted) {
    m_isDeleted = false;
  }
  ~DummyRefCounted() { m_isDeleted = true; }

  void ref() {
    WTF::RefCounted<DummyRefCounted>::ref();
    ++s_refInvokesCount;
  }

  static int s_refInvokesCount;

 private:
  bool& m_isDeleted;
};

int DummyRefCounted::s_refInvokesCount = 0;

TEST(HashSetTest, HashSetRefPtr) {
  bool isDeleted = false;
  RefPtr<DummyRefCounted> ptr = adoptRef(new DummyRefCounted(isDeleted));
  EXPECT_EQ(0, DummyRefCounted::s_refInvokesCount);
  HashSet<RefPtr<DummyRefCounted>> set;
  set.add(ptr);
  // Referenced only once (to store a copy in the container).
  EXPECT_EQ(1, DummyRefCounted::s_refInvokesCount);

  DummyRefCounted* rawPtr = ptr.get();

  EXPECT_TRUE(set.contains(rawPtr));
  EXPECT_NE(set.end(), set.find(rawPtr));
  EXPECT_TRUE(set.contains(ptr));
  EXPECT_NE(set.end(), set.find(ptr));

  ptr.clear();
  EXPECT_FALSE(isDeleted);

  set.remove(rawPtr);
  EXPECT_TRUE(isDeleted);
  EXPECT_TRUE(set.isEmpty());
  EXPECT_EQ(1, DummyRefCounted::s_refInvokesCount);
}

}  // namespace
