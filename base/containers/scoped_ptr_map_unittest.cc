// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/containers/scoped_ptr_map.h"

#include <functional>
#include <map>
#include <utility>

#include "base/bind.h"
#include "base/callback.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

// A ScopedDestroyer sets a Boolean to true upon destruction.
class ScopedDestroyer {
 public:
  ScopedDestroyer(bool* destroyed) : destroyed_(destroyed) {
    *destroyed_ = false;
  }

  ~ScopedDestroyer() { *destroyed_ = true; }

 private:
  bool* destroyed_;
};

TEST(ScopedPtrMapTest, Insert) {
  bool destroyed1 = false;
  bool destroyed2 = false;
  {
    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;

    // Insert to new key.
    ScopedDestroyer* elem1 = new ScopedDestroyer(&destroyed1);
    EXPECT_FALSE(destroyed1);
    EXPECT_TRUE(scoped_map.insert(0, make_scoped_ptr(elem1)).second);
    EXPECT_EQ(elem1, scoped_map.find(0)->second);
    EXPECT_FALSE(destroyed1);

    // Insert to existing key.
    ScopedDestroyer* elem2 = new ScopedDestroyer(&destroyed2);
    EXPECT_FALSE(destroyed2);
    EXPECT_FALSE(scoped_map.insert(0, make_scoped_ptr(elem2)).second);
    EXPECT_EQ(elem1, scoped_map.find(0)->second);

    EXPECT_FALSE(destroyed1);
    EXPECT_TRUE(destroyed2);
  }
  EXPECT_TRUE(destroyed1);
}

TEST(ScopedPtrMapTest, Set) {
  bool destroyed1 = false;
  bool destroyed2 = false;
  {
    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;

    // Set a new key.
    ScopedDestroyer* elem1 = new ScopedDestroyer(&destroyed1);
    EXPECT_FALSE(destroyed1);
    scoped_map.set(0, make_scoped_ptr(elem1));
    EXPECT_EQ(elem1, scoped_map.find(0)->second);
    EXPECT_FALSE(destroyed1);

    // Set to replace an existing key.
    ScopedDestroyer* elem2 = new ScopedDestroyer(&destroyed2);
    EXPECT_FALSE(destroyed2);
    scoped_map.set(0, make_scoped_ptr(elem2));
    EXPECT_EQ(elem2, scoped_map.find(0)->second);

    EXPECT_TRUE(destroyed1);
    EXPECT_FALSE(destroyed2);
  }
  EXPECT_TRUE(destroyed1);
  EXPECT_TRUE(destroyed2);
}

TEST(ScopedPtrMapTest, EraseIterator) {
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
  scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed)));
  EXPECT_FALSE(destroyed);
  scoped_map.erase(scoped_map.find(0));
  EXPECT_TRUE(destroyed);
  EXPECT_TRUE(scoped_map.empty());
}

TEST(ScopedPtrMapTest, EraseKey) {
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
  scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed)));
  EXPECT_FALSE(destroyed);
  EXPECT_EQ(1u, scoped_map.erase(0));
  EXPECT_TRUE(destroyed);
  EXPECT_TRUE(scoped_map.empty());

  // Test erase of a non-existent key.
  EXPECT_EQ(0u, scoped_map.erase(7));
}

TEST(ScopedPtrMapTest, EraseRange) {
  bool destroyed1 = false;
  bool destroyed2 = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;

  scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed1)));
  EXPECT_FALSE(destroyed1);

  scoped_map.insert(1, make_scoped_ptr(new ScopedDestroyer(&destroyed2)));
  EXPECT_FALSE(destroyed2);

  scoped_map.erase(scoped_map.find(0), scoped_map.end());
  EXPECT_TRUE(destroyed1);
  EXPECT_TRUE(destroyed2);
  EXPECT_TRUE(scoped_map.empty());
}

TEST(ScopedPtrMapTest, TakeAndErase) {
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
  ScopedDestroyer* elem = new ScopedDestroyer(&destroyed);
  scoped_map.insert(0, make_scoped_ptr(elem));
  EXPECT_EQ(elem, scoped_map.find(0)->second);
  EXPECT_FALSE(destroyed);
  scoped_ptr<ScopedDestroyer> object = scoped_map.take_and_erase(0);
  EXPECT_EQ(elem, object.get());
  EXPECT_FALSE(destroyed);
  EXPECT_TRUE(scoped_map.empty());
  object.reset();
  EXPECT_TRUE(destroyed);
}

TEST(ScopedPtrMapTest, Clear) {
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
  scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed)));
  EXPECT_FALSE(destroyed);
  scoped_map.clear();
  EXPECT_TRUE(destroyed);
  EXPECT_TRUE(scoped_map.empty());
}

TEST(ScopedPtrMapTest, Compare) {
  // Construct a ScopedPtrMap with a custom comparison function.
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>, std::greater<int>> scoped_map;
  scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed)));
  scoped_map.insert(1, make_scoped_ptr(new ScopedDestroyer(&destroyed)));

  auto it = scoped_map.begin();
  EXPECT_EQ(1, it->first);
  ++it;
  EXPECT_EQ(0, it->first);
}

TEST(ScopedPtrMapTest, Scope) {
  bool destroyed = false;
  {
    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
    scoped_map.insert(0, make_scoped_ptr(new ScopedDestroyer(&destroyed)));
    EXPECT_FALSE(destroyed);
  }
  EXPECT_TRUE(destroyed);
}

TEST(ScopedPtrMapTest, MoveConstruct) {
  bool destroyed = false;
  {
    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
    ScopedDestroyer* elem = new ScopedDestroyer(&destroyed);
    scoped_map.insert(0, make_scoped_ptr(elem));
    EXPECT_EQ(elem, scoped_map.find(0)->second);
    EXPECT_FALSE(destroyed);
    EXPECT_FALSE(scoped_map.empty());

    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map_copy(
        scoped_map.Pass());
    EXPECT_TRUE(scoped_map.empty());
    EXPECT_FALSE(scoped_map_copy.empty());
    EXPECT_EQ(elem, scoped_map_copy.find(0)->second);
    EXPECT_FALSE(destroyed);
  }
  EXPECT_TRUE(destroyed);
}

TEST(ScopedPtrMapTest, MoveAssign) {
  bool destroyed = false;
  {
    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
    ScopedDestroyer* elem = new ScopedDestroyer(&destroyed);
    scoped_map.insert(0, make_scoped_ptr(elem));
    EXPECT_EQ(elem, scoped_map.find(0)->second);
    EXPECT_FALSE(destroyed);
    EXPECT_FALSE(scoped_map.empty());

    ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map_assign;
    scoped_map_assign = scoped_map.Pass();
    EXPECT_TRUE(scoped_map.empty());
    EXPECT_FALSE(scoped_map_assign.empty());
    EXPECT_EQ(elem, scoped_map_assign.find(0)->second);
    EXPECT_FALSE(destroyed);
  }
  EXPECT_TRUE(destroyed);
}

template <typename Key, typename ScopedPtr>
ScopedPtrMap<Key, ScopedPtr> PassThru(ScopedPtrMap<Key, ScopedPtr> scoper) {
  return scoper;
}

TEST(ScopedPtrMapTest, Passed) {
  bool destroyed = false;
  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> scoped_map;
  ScopedDestroyer* elem = new ScopedDestroyer(&destroyed);
  scoped_map.insert(0, make_scoped_ptr(elem));
  EXPECT_EQ(elem, scoped_map.find(0)->second);
  EXPECT_FALSE(destroyed);

  base::Callback<ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>>(void)>
      callback = base::Bind(&PassThru<int, scoped_ptr<ScopedDestroyer>>,
                            base::Passed(&scoped_map));
  EXPECT_TRUE(scoped_map.empty());
  EXPECT_FALSE(destroyed);

  ScopedPtrMap<int, scoped_ptr<ScopedDestroyer>> result = callback.Run();
  EXPECT_TRUE(scoped_map.empty());
  EXPECT_EQ(elem, result.find(0)->second);
  EXPECT_FALSE(destroyed);

  result.clear();
  EXPECT_TRUE(destroyed);
};

}  // namespace
}  // namespace base
