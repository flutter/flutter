// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/basictypes.h"
#include "base/mac/scoped_nsautorelease_pool.h"
#include "base/mac/scoped_nsobject.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

TEST(ScopedNSObjectTest, ScopedNSObject) {
  base::scoped_nsobject<NSObject> p1([[NSObject alloc] init]);
  ASSERT_TRUE(p1.get());
  ASSERT_EQ(1u, [p1 retainCount]);
  base::scoped_nsobject<NSObject> p2(p1);
  ASSERT_EQ(p1.get(), p2.get());
  ASSERT_EQ(2u, [p1 retainCount]);
  p2.reset();
  ASSERT_EQ(nil, p2.get());
  ASSERT_EQ(1u, [p1 retainCount]);
  {
    base::scoped_nsobject<NSObject> p3 = p1;
    ASSERT_EQ(p1.get(), p3.get());
    ASSERT_EQ(2u, [p1 retainCount]);
    p3 = p1;
    ASSERT_EQ(p1.get(), p3.get());
    ASSERT_EQ(2u, [p1 retainCount]);
  }
  ASSERT_EQ(1u, [p1 retainCount]);
  base::scoped_nsobject<NSObject> p4([p1.get() retain]);
  ASSERT_EQ(2u, [p1 retainCount]);
  ASSERT_TRUE(p1 == p1.get());
  ASSERT_TRUE(p1 == p1);
  ASSERT_FALSE(p1 != p1);
  ASSERT_FALSE(p1 != p1.get());
  base::scoped_nsobject<NSObject> p5([[NSObject alloc] init]);
  ASSERT_TRUE(p1 != p5);
  ASSERT_TRUE(p1 != p5.get());
  ASSERT_FALSE(p1 == p5);
  ASSERT_FALSE(p1 == p5.get());

  base::scoped_nsobject<NSObject> p6 = p1;
  ASSERT_EQ(3u, [p6 retainCount]);
  {
    base::mac::ScopedNSAutoreleasePool pool;
    p6.autorelease();
    ASSERT_EQ(nil, p6.get());
    ASSERT_EQ(3u, [p1 retainCount]);
  }
  ASSERT_EQ(2u, [p1 retainCount]);
}

TEST(ScopedNSObjectTest, ScopedNSObjectInContainer) {
  base::scoped_nsobject<id> p([[NSObject alloc] init]);
  ASSERT_TRUE(p.get());
  ASSERT_EQ(1u, [p retainCount]);
  {
    std::vector<base::scoped_nsobject<id>> objects;
    objects.push_back(p);
    ASSERT_EQ(2u, [p retainCount]);
    ASSERT_EQ(p.get(), objects[0].get());
    objects.push_back(base::scoped_nsobject<id>([[NSObject alloc] init]));
    ASSERT_TRUE(objects[1].get());
    ASSERT_EQ(1u, [objects[1] retainCount]);
  }
  ASSERT_EQ(1u, [p retainCount]);
}

TEST(ScopedNSObjectTest, ScopedNSObjectFreeFunctions) {
  base::scoped_nsobject<id> p1([[NSObject alloc] init]);
  id o1 = p1.get();
  ASSERT_TRUE(o1 == p1);
  ASSERT_FALSE(o1 != p1);
  base::scoped_nsobject<id> p2([[NSObject alloc] init]);
  ASSERT_TRUE(o1 != p2);
  ASSERT_FALSE(o1 == p2);
  id o2 = p2.get();
  swap(p1, p2);
  ASSERT_EQ(o2, p1.get());
  ASSERT_EQ(o1, p2.get());
}

}  // namespace
