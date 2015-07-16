// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/refptr.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace skia {
namespace {

TEST(RefPtrTest, ReferenceCounting) {
  SkRefCnt* ref = new SkRefCnt();
  EXPECT_TRUE(ref->unique());

  {
    // Adopt the reference from the caller on creation.
    RefPtr<SkRefCnt> refptr1 = AdoptRef(ref);
    EXPECT_TRUE(ref->unique());
    EXPECT_TRUE(refptr1->unique());

    EXPECT_EQ(ref, &*refptr1);
    EXPECT_EQ(ref, refptr1.get());

    {
      // Take a second reference for the second instance.
      RefPtr<SkRefCnt> refptr2(refptr1);
      EXPECT_FALSE(ref->unique());

      RefPtr<SkRefCnt> refptr3;
      EXPECT_FALSE(refptr3);

      // Take a third reference for the third instance.
      refptr3 = refptr1;
      EXPECT_FALSE(ref->unique());

      // Same object, so should have the same refcount.
      refptr2 = refptr3;
      EXPECT_FALSE(ref->unique());

      // Drop the object from refptr2, so it should lose its reference.
      EXPECT_TRUE(refptr2);
      refptr2.clear();
      EXPECT_FALSE(ref->unique());

      EXPECT_FALSE(refptr2);
      EXPECT_EQ(NULL, refptr2.get());

      EXPECT_TRUE(refptr3);
      EXPECT_FALSE(refptr3->unique());
      EXPECT_EQ(ref, &*refptr3);
      EXPECT_EQ(ref, refptr3.get());
    }

    // Drop a reference when the third object is destroyed.
    EXPECT_TRUE(ref->unique());
  }
}

TEST(RefPtrTest, Construct) {
  SkRefCnt* ref = new SkRefCnt();
  EXPECT_TRUE(ref->unique());

  // Adopt the reference from the caller on creation.
  RefPtr<SkRefCnt> refptr1(AdoptRef(ref));
  EXPECT_TRUE(ref->unique());
  EXPECT_TRUE(refptr1->unique());

  EXPECT_EQ(ref, &*refptr1);
  EXPECT_EQ(ref, refptr1.get());

  RefPtr<SkRefCnt> refptr2(refptr1);
  EXPECT_FALSE(ref->unique());
}

TEST(RefPtrTest, DeclareAndAssign) {
  SkRefCnt* ref = new SkRefCnt();
  EXPECT_TRUE(ref->unique());

  // Adopt the reference from the caller on creation.
  RefPtr<SkRefCnt> refptr1 = AdoptRef(ref);
  EXPECT_TRUE(ref->unique());
  EXPECT_TRUE(refptr1->unique());

  EXPECT_EQ(ref, &*refptr1);
  EXPECT_EQ(ref, refptr1.get());

  RefPtr<SkRefCnt> refptr2 = refptr1;
  EXPECT_FALSE(ref->unique());
}

TEST(RefPtrTest, Assign) {
  SkRefCnt* ref = new SkRefCnt();
  EXPECT_TRUE(ref->unique());

  // Adopt the reference from the caller on creation.
  RefPtr<SkRefCnt> refptr1;
  refptr1 = AdoptRef(ref);
  EXPECT_TRUE(ref->unique());
  EXPECT_TRUE(refptr1->unique());

  EXPECT_EQ(ref, &*refptr1);
  EXPECT_EQ(ref, refptr1.get());

  RefPtr<SkRefCnt> refptr2;
  refptr2 = refptr1;
  EXPECT_FALSE(ref->unique());
}

class Subclass : public SkRefCnt {};

TEST(RefPtrTest, Upcast) {
  RefPtr<Subclass> child = AdoptRef(new Subclass());
  EXPECT_TRUE(child->unique());

  RefPtr<SkRefCnt> parent = child;
  EXPECT_TRUE(child);
  EXPECT_TRUE(parent);

  EXPECT_FALSE(child->unique());
  EXPECT_FALSE(parent->unique());
}

}  // namespace
}  // namespace skia
