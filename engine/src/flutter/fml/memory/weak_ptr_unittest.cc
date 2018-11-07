// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/memory/weak_ptr.h"

#include <utility>

#include "gtest/gtest.h"

namespace fml {
namespace {

TEST(WeakPtrTest, Basic) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr = factory.GetWeakPtr();
  EXPECT_EQ(&data, ptr.get());
}

TEST(WeakPtrTest, CopyConstruction) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr = factory.GetWeakPtr();
  WeakPtr<int> ptr2(ptr);
  EXPECT_EQ(&data, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, MoveConstruction) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr = factory.GetWeakPtr();
  WeakPtr<int> ptr2(std::move(ptr));
  EXPECT_EQ(nullptr, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, CopyAssignment) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr = factory.GetWeakPtr();
  WeakPtr<int> ptr2;
  EXPECT_EQ(nullptr, ptr2.get());
  ptr2 = ptr;
  EXPECT_EQ(&data, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, MoveAssignment) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr = factory.GetWeakPtr();
  WeakPtr<int> ptr2;
  EXPECT_EQ(nullptr, ptr2.get());
  ptr2 = std::move(ptr);
  EXPECT_EQ(nullptr, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, Testable) {
  int data = 0;
  WeakPtrFactory<int> factory(&data);
  WeakPtr<int> ptr;
  EXPECT_EQ(nullptr, ptr.get());
  EXPECT_FALSE(ptr);
  ptr = factory.GetWeakPtr();
  EXPECT_EQ(&data, ptr.get());
  EXPECT_TRUE(ptr);
}

TEST(WeakPtrTest, OutOfScope) {
  WeakPtr<int> ptr;
  EXPECT_EQ(nullptr, ptr.get());
  {
    int data = 0;
    WeakPtrFactory<int> factory(&data);
    ptr = factory.GetWeakPtr();
  }
  EXPECT_EQ(nullptr, ptr.get());
}

TEST(WeakPtrTest, Multiple) {
  WeakPtr<int> a;
  WeakPtr<int> b;
  {
    int data = 0;
    WeakPtrFactory<int> factory(&data);
    a = factory.GetWeakPtr();
    b = factory.GetWeakPtr();
    EXPECT_EQ(&data, a.get());
    EXPECT_EQ(&data, b.get());
  }
  EXPECT_EQ(nullptr, a.get());
  EXPECT_EQ(nullptr, b.get());
}

TEST(WeakPtrTest, MultipleStaged) {
  WeakPtr<int> a;
  {
    int data = 0;
    WeakPtrFactory<int> factory(&data);
    a = factory.GetWeakPtr();
    { WeakPtr<int> b = factory.GetWeakPtr(); }
    EXPECT_NE(a.get(), nullptr);
  }
  EXPECT_EQ(nullptr, a.get());
}

struct Base {
  double member = 0.;
};
struct Derived : public Base {};

TEST(WeakPtrTest, Dereference) {
  Base data;
  data.member = 123456.;
  WeakPtrFactory<Base> factory(&data);
  WeakPtr<Base> ptr = factory.GetWeakPtr();
  EXPECT_EQ(&data, ptr.get());
  EXPECT_EQ(data.member, (*ptr).member);
  EXPECT_EQ(data.member, ptr->member);
}

TEST(WeakPtrTest, UpcastCopyConstruction) {
  Derived data;
  WeakPtrFactory<Derived> factory(&data);
  WeakPtr<Derived> ptr = factory.GetWeakPtr();
  WeakPtr<Base> ptr2(ptr);
  EXPECT_EQ(&data, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, UpcastMoveConstruction) {
  Derived data;
  WeakPtrFactory<Derived> factory(&data);
  WeakPtr<Derived> ptr = factory.GetWeakPtr();
  WeakPtr<Base> ptr2(std::move(ptr));
  EXPECT_EQ(nullptr, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, UpcastCopyAssignment) {
  Derived data;
  WeakPtrFactory<Derived> factory(&data);
  WeakPtr<Derived> ptr = factory.GetWeakPtr();
  WeakPtr<Base> ptr2;
  EXPECT_EQ(nullptr, ptr2.get());
  ptr2 = ptr;
  EXPECT_EQ(&data, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

TEST(WeakPtrTest, UpcastMoveAssignment) {
  Derived data;
  WeakPtrFactory<Derived> factory(&data);
  WeakPtr<Derived> ptr = factory.GetWeakPtr();
  WeakPtr<Base> ptr2;
  EXPECT_EQ(nullptr, ptr2.get());
  ptr2 = std::move(ptr);
  EXPECT_EQ(nullptr, ptr.get());
  EXPECT_EQ(&data, ptr2.get());
}

}  // namespace
}  // namespace fml
