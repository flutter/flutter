// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/fml/platform/darwin/weak_nsobject.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "gtest/gtest.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

namespace fml {
namespace {

TEST(WeakNSObjectTestARC, WeakNSObject) {
  scoped_nsobject<NSObject> p1;
  WeakNSObject<NSObject> w1;
  @autoreleasepool {
    p1.reset(([[NSObject alloc] init]));
    WeakNSObjectFactory factory(p1.get());
    w1 = factory.GetWeakNSObject();
    EXPECT_TRUE(w1);
    p1.reset();
  }
  EXPECT_FALSE(w1);
}

TEST(WeakNSObjectTestARC, MultipleWeakNSObject) {
  scoped_nsobject<NSObject> p1;
  WeakNSObject<NSObject> w1;
  WeakNSObject<NSObject> w2;
  @autoreleasepool {
    p1.reset([[NSObject alloc] init]);
    WeakNSObjectFactory factory(p1.get());
    w1 = factory.GetWeakNSObject();
    // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
    w2 = w1;
    EXPECT_TRUE(w1);
    EXPECT_TRUE(w2);
    EXPECT_TRUE(w1.get() == w2.get());
    p1.reset();
  }
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}

TEST(WeakNSObjectTestARC, WeakNSObjectDies) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  {
    WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
    EXPECT_TRUE(w1);
  }
}

TEST(WeakNSObjectTestARC, WeakNSObjectReset) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  EXPECT_TRUE(w1);
  w1.reset();
  EXPECT_FALSE(w1);
  EXPECT_TRUE(p1);
  EXPECT_TRUE([p1 description]);
}

TEST(WeakNSObjectTestARC, WeakNSObjectEmpty) {
  scoped_nsobject<NSObject> p1;
  WeakNSObject<NSObject> w1;
  @autoreleasepool {
    scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
    EXPECT_FALSE(w1);
    WeakNSObjectFactory factory(p1.get());
    w1 = factory.GetWeakNSObject();
    EXPECT_TRUE(w1);
    p1.reset();
  }
  EXPECT_FALSE(w1);
}

TEST(WeakNSObjectTestARC, WeakNSObjectCopy) {
  scoped_nsobject<NSObject> p1;
  WeakNSObject<NSObject> w1;
  WeakNSObject<NSObject> w2;
  @autoreleasepool {
    scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
    WeakNSObjectFactory factory(p1.get());
    w1 = factory.GetWeakNSObject();
    // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
    w2 = w1;
    EXPECT_TRUE(w1);
    EXPECT_TRUE(w2);
    p1.reset();
  }
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}

TEST(WeakNSObjectTestARC, WeakNSObjectAssignment) {
  scoped_nsobject<NSObject> p1;
  WeakNSObject<NSObject> w1;
  WeakNSObject<NSObject> w2;
  @autoreleasepool {
    scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
    WeakNSObjectFactory factory(p1.get());
    w1 = factory.GetWeakNSObject();
    // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
    w2 = w1;
    EXPECT_TRUE(w1);
    EXPECT_TRUE(w2);
    p1.reset();
  }
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}
}  // namespace
}  // namespace fml
