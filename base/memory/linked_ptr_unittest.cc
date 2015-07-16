// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/memory/linked_ptr.h"
#include "base/strings/stringprintf.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

int num = 0;

std::string history;

// Class which tracks allocation/deallocation
struct A {
  A(): mynum(num++) { history += base::StringPrintf("A%d ctor\n", mynum); }
  virtual ~A() { history += base::StringPrintf("A%d dtor\n", mynum); }
  virtual void Use() { history += base::StringPrintf("A%d use\n", mynum); }
  int mynum;
};

// Subclass
struct B: public A {
  B() { history += base::StringPrintf("B%d ctor\n", mynum); }
  ~B() override { history += base::StringPrintf("B%d dtor\n", mynum); }
  void Use() override { history += base::StringPrintf("B%d use\n", mynum); }
};

}  // namespace

TEST(LinkedPtrTest, Test) {
  {
    linked_ptr<A> a0, a1, a2;
    a0 = a0;
    a1 = a2;
    ASSERT_EQ(a0.get(), static_cast<A*>(NULL));
    ASSERT_EQ(a1.get(), static_cast<A*>(NULL));
    ASSERT_EQ(a2.get(), static_cast<A*>(NULL));
    ASSERT_TRUE(a0 == NULL);
    ASSERT_TRUE(a1 == NULL);
    ASSERT_TRUE(a2 == NULL);

    {
      linked_ptr<A> a3(new A);
      a0 = a3;
      ASSERT_TRUE(a0 == a3);
      ASSERT_TRUE(a0 != NULL);
      ASSERT_TRUE(a0.get() == a3);
      ASSERT_TRUE(a0 == a3.get());
      linked_ptr<A> a4(a0);
      a1 = a4;
      linked_ptr<A> a5(new A);
      ASSERT_TRUE(a5.get() != a3);
      ASSERT_TRUE(a5 != a3.get());
      a2 = a5;
      linked_ptr<B> b0(new B);
      linked_ptr<A> a6(b0);
      ASSERT_TRUE(b0 == a6);
      ASSERT_TRUE(a6 == b0);
      ASSERT_TRUE(b0 != NULL);
      a5 = b0;
      a5 = b0;
      a3->Use();
      a4->Use();
      a5->Use();
      a6->Use();
      b0->Use();
      (*b0).Use();
      b0.get()->Use();
    }

    a0->Use();
    a1->Use();
    a2->Use();

    a1 = a2;
    a2.reset(new A);
    a0.reset();

    linked_ptr<A> a7;
  }

  ASSERT_EQ(history,
    "A0 ctor\n"
    "A1 ctor\n"
    "A2 ctor\n"
    "B2 ctor\n"
    "A0 use\n"
    "A0 use\n"
    "B2 use\n"
    "B2 use\n"
    "B2 use\n"
    "B2 use\n"
    "B2 use\n"
    "B2 dtor\n"
    "A2 dtor\n"
    "A0 use\n"
    "A0 use\n"
    "A1 use\n"
    "A3 ctor\n"
    "A0 dtor\n"
    "A3 dtor\n"
    "A1 dtor\n"
  );
}
