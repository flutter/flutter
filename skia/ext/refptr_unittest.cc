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
      EXPECT_EQ(nullptr, refptr2.get());

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

// Counts the number of ref/unref operations (which require atomic operations)
// that are done.
class RefCountCounter : public SkRefCnt {
 public:
  void ref() const {
    ref_count_changes_++;
    SkRefCnt::ref();
  }
  void unref() const {
    ref_count_changes_++;
    SkRefCnt::unref();
  }
  int ref_count_changes() const { return ref_count_changes_; }
  void ResetRefCountChanges() { ref_count_changes_ = 0; }

 private:
  mutable int ref_count_changes_ = 0;
};

TEST(RefPtrTest, ConstructionFromTemporary) {
  // No ref count changes to move temporary into a local.
  RefPtr<RefCountCounter> object = skia::AdoptRef(new RefCountCounter);
  EXPECT_EQ(0, object->ref_count_changes());

  // Only one change to share the pointer.
  object->ResetRefCountChanges();
  RefPtr<RefCountCounter> shared = skia::SharePtr(object.get());
  EXPECT_EQ(1, object->ref_count_changes());

  // Two ref count changes for the extra ref when passed as an argument, but no
  // more.
  object->ResetRefCountChanges();
  auto do_nothing = [](RefPtr<RefCountCounter>) {};
  do_nothing(object);
  EXPECT_EQ(2, object->ref_count_changes());

  // No ref count changes when passing a newly adopted ref as an argument.
  auto lambda = [](RefPtr<RefCountCounter> arg) {
    EXPECT_EQ(0, arg->ref_count_changes());
  };
  lambda(skia::AdoptRef(new RefCountCounter));
}

TEST(RefPtrTest, AssignmentFromTemporary) {
  // No ref count changes to move temporary into a local.
  RefPtr<RefCountCounter> object;
  object = skia::AdoptRef(new RefCountCounter);
  EXPECT_EQ(0, object->ref_count_changes());

  // Only one change to share the pointer.
  object->ResetRefCountChanges();
  RefPtr<RefCountCounter> shared;
  shared = skia::SharePtr(object.get());
  EXPECT_EQ(1, object->ref_count_changes());
}

TEST(RefPtrTest, PassIntoArguments) {
  // No ref count changes when passing an argument with Pass().
  RefPtr<RefCountCounter> object = skia::AdoptRef(new RefCountCounter);
  RefPtr<RefCountCounter> object2 = std::move(object);
  auto lambda = [](RefPtr<RefCountCounter> arg) {
    EXPECT_EQ(0, arg->ref_count_changes());
  };
  lambda(std::move(object2));
}

class DestructionNotifier : public SkRefCnt {
 public:
  DestructionNotifier(bool* flag) : flag_(flag) {}
  ~DestructionNotifier() override { *flag_ = true; }

 private:
  bool* flag_;
};

TEST(RefPtrTest, Nullptr) {
  RefPtr<SkRefCnt> null(nullptr);
  EXPECT_FALSE(null);

  bool is_destroyed = false;
  RefPtr<DestructionNotifier> destroy_me =
      skia::AdoptRef(new DestructionNotifier(&is_destroyed));
  destroy_me = nullptr;
  EXPECT_TRUE(is_destroyed);
  EXPECT_FALSE(destroy_me);

  // Check that returning nullptr from a function correctly causes an implicit
  // conversion.
  auto lambda = []() -> RefPtr<SkRefCnt> { return nullptr; };
  RefPtr<SkRefCnt> returned = lambda();
  EXPECT_FALSE(returned);
}

}  // namespace
}  // namespace skia
