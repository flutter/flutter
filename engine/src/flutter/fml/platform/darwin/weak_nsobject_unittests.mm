// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/fml/platform/darwin/weak_nsobject.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "gtest/gtest.h"

namespace fml {
namespace {

TEST(WeakNSObjectTest, WeakNSObject) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  EXPECT_TRUE(w1);
  p1.reset();
  EXPECT_FALSE(w1);
}

TEST(WeakNSObjectTest, MultipleWeakNSObject) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
  WeakNSObject<NSObject> w2(w1);
  EXPECT_TRUE(w1);
  EXPECT_TRUE(w2);
  EXPECT_TRUE(w1.get() == w2.get());
  p1.reset();
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}

TEST(WeakNSObjectTest, WeakNSObjectDies) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  {
    WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
    EXPECT_TRUE(w1);
  }
}

TEST(WeakNSObjectTest, WeakNSObjectReset) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  EXPECT_TRUE(w1);
  w1.reset();
  EXPECT_FALSE(w1);
  EXPECT_TRUE(p1);
  EXPECT_TRUE([p1 description]);
}

TEST(WeakNSObjectTest, WeakNSObjectEmpty) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObject<NSObject> w1;
  EXPECT_FALSE(w1);
  WeakNSObjectFactory factory(p1.get());
  w1 = factory.GetWeakNSObject();
  EXPECT_TRUE(w1);
  p1.reset();
  EXPECT_FALSE(w1);
}

TEST(WeakNSObjectTest, WeakNSObjectCopy) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
  WeakNSObject<NSObject> w2(w1);
  EXPECT_TRUE(w1);
  EXPECT_TRUE(w2);
  p1.reset();
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}

TEST(WeakNSObjectTest, WeakNSObjectAssignment) {
  scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  WeakNSObjectFactory factory(p1.get());
  WeakNSObject<NSObject> w1 = factory.GetWeakNSObject();
  // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
  WeakNSObject<NSObject> w2 = w1;
  EXPECT_TRUE(w1);
  EXPECT_TRUE(w2);
  p1.reset();
  EXPECT_FALSE(w1);
  EXPECT_FALSE(w2);
}
}  // namespace
}  // namespace fml
