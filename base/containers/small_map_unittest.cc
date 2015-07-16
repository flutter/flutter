// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/containers/small_map.h"

#include <stddef.h>

#include <algorithm>
#include <functional>
#include <map>

#include "base/containers/hash_tables.h"
#include "base/logging.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(SmallMap, General) {
  SmallMap<hash_map<int, int> > m;

  EXPECT_TRUE(m.empty());

  m[0] = 5;

  EXPECT_FALSE(m.empty());
  EXPECT_EQ(m.size(), 1u);

  m[9] = 2;

  EXPECT_FALSE(m.empty());
  EXPECT_EQ(m.size(), 2u);

  EXPECT_EQ(m[9], 2);
  EXPECT_EQ(m[0], 5);
  EXPECT_FALSE(m.UsingFullMap());

  SmallMap<hash_map<int, int> >::iterator iter(m.begin());
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 0);
  EXPECT_EQ(iter->second, 5);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ((*iter).first, 9);
  EXPECT_EQ((*iter).second, 2);
  ++iter;
  EXPECT_TRUE(iter == m.end());

  m[8] = 23;
  m[1234] = 90;
  m[-5] = 6;

  EXPECT_EQ(m[   9],  2);
  EXPECT_EQ(m[   0],  5);
  EXPECT_EQ(m[1234], 90);
  EXPECT_EQ(m[   8], 23);
  EXPECT_EQ(m[  -5],  6);
  EXPECT_EQ(m.size(), 5u);
  EXPECT_FALSE(m.empty());
  EXPECT_TRUE(m.UsingFullMap());

  iter = m.begin();
  for (int i = 0; i < 5; i++) {
    EXPECT_TRUE(iter != m.end());
    ++iter;
  }
  EXPECT_TRUE(iter == m.end());

  const SmallMap<hash_map<int, int> >& ref = m;
  EXPECT_TRUE(ref.find(1234) != m.end());
  EXPECT_TRUE(ref.find(5678) == m.end());
}

TEST(SmallMap, PostFixIteratorIncrement) {
  SmallMap<hash_map<int, int> > m;
  m[0] = 5;
  m[2] = 3;

  {
    SmallMap<hash_map<int, int> >::iterator iter(m.begin());
    SmallMap<hash_map<int, int> >::iterator last(iter++);
    ++last;
    EXPECT_TRUE(last == iter);
  }

  {
    SmallMap<hash_map<int, int> >::const_iterator iter(m.begin());
    SmallMap<hash_map<int, int> >::const_iterator last(iter++);
    ++last;
    EXPECT_TRUE(last == iter);
  }
}

// Based on the General testcase.
TEST(SmallMap, CopyConstructor) {
  SmallMap<hash_map<int, int> > src;

  {
    SmallMap<hash_map<int, int> > m(src);
    EXPECT_TRUE(m.empty());
  }

  src[0] = 5;

  {
    SmallMap<hash_map<int, int> > m(src);
    EXPECT_FALSE(m.empty());
    EXPECT_EQ(m.size(), 1u);
  }

  src[9] = 2;

  {
    SmallMap<hash_map<int, int> > m(src);
    EXPECT_FALSE(m.empty());
    EXPECT_EQ(m.size(), 2u);

    EXPECT_EQ(m[9], 2);
    EXPECT_EQ(m[0], 5);
    EXPECT_FALSE(m.UsingFullMap());
  }

  src[8] = 23;
  src[1234] = 90;
  src[-5] = 6;

  {
    SmallMap<hash_map<int, int> > m(src);
    EXPECT_EQ(m[   9],  2);
    EXPECT_EQ(m[   0],  5);
    EXPECT_EQ(m[1234], 90);
    EXPECT_EQ(m[   8], 23);
    EXPECT_EQ(m[  -5],  6);
    EXPECT_EQ(m.size(), 5u);
    EXPECT_FALSE(m.empty());
    EXPECT_TRUE(m.UsingFullMap());
  }
}

template<class inner>
static bool SmallMapIsSubset(SmallMap<inner> const& a,
                             SmallMap<inner> const& b) {
  typename SmallMap<inner>::const_iterator it;
  for (it = a.begin(); it != a.end(); ++it) {
    typename SmallMap<inner>::const_iterator it_in_b = b.find(it->first);
    if (it_in_b == b.end() || it_in_b->second != it->second)
      return false;
  }
  return true;
}

template<class inner>
static bool SmallMapEqual(SmallMap<inner> const& a,
                          SmallMap<inner> const& b) {
  return SmallMapIsSubset(a, b) && SmallMapIsSubset(b, a);
}

TEST(SmallMap, AssignmentOperator) {
  SmallMap<hash_map<int, int> > src_small;
  SmallMap<hash_map<int, int> > src_large;

  src_small[1] = 20;
  src_small[2] = 21;
  src_small[3] = 22;
  EXPECT_FALSE(src_small.UsingFullMap());

  src_large[1] = 20;
  src_large[2] = 21;
  src_large[3] = 22;
  src_large[5] = 23;
  src_large[6] = 24;
  src_large[7] = 25;
  EXPECT_TRUE(src_large.UsingFullMap());

  // Assignments to empty.
  SmallMap<hash_map<int, int> > dest_small;
  dest_small = src_small;
  EXPECT_TRUE(SmallMapEqual(dest_small, src_small));
  EXPECT_EQ(dest_small.UsingFullMap(),
            src_small.UsingFullMap());

  SmallMap<hash_map<int, int> > dest_large;
  dest_large = src_large;
  EXPECT_TRUE(SmallMapEqual(dest_large, src_large));
  EXPECT_EQ(dest_large.UsingFullMap(),
            src_large.UsingFullMap());

  // Assignments which assign from full to small, and vice versa.
  dest_small = src_large;
  EXPECT_TRUE(SmallMapEqual(dest_small, src_large));
  EXPECT_EQ(dest_small.UsingFullMap(),
            src_large.UsingFullMap());

  dest_large = src_small;
  EXPECT_TRUE(SmallMapEqual(dest_large, src_small));
  EXPECT_EQ(dest_large.UsingFullMap(),
            src_small.UsingFullMap());

  // Double check that SmallMapEqual works:
  dest_large[42] = 666;
  EXPECT_FALSE(SmallMapEqual(dest_large, src_small));
}

TEST(SmallMap, Insert) {
  SmallMap<hash_map<int, int> > sm;

  // loop through the transition from small map to map.
  for (int i = 1; i <= 10; ++i) {
    VLOG(1) << "Iteration " << i;
    // insert an element
    std::pair<SmallMap<hash_map<int, int> >::iterator,
        bool> ret;
    ret = sm.insert(std::make_pair(i, 100*i));
    EXPECT_TRUE(ret.second);
    EXPECT_TRUE(ret.first == sm.find(i));
    EXPECT_EQ(ret.first->first, i);
    EXPECT_EQ(ret.first->second, 100*i);

    // try to insert it again with different value, fails, but we still get an
    // iterator back with the original value.
    ret = sm.insert(std::make_pair(i, -i));
    EXPECT_FALSE(ret.second);
    EXPECT_TRUE(ret.first == sm.find(i));
    EXPECT_EQ(ret.first->first, i);
    EXPECT_EQ(ret.first->second, 100*i);

    // check the state of the map.
    for (int j = 1; j <= i; ++j) {
      SmallMap<hash_map<int, int> >::iterator it = sm.find(j);
      EXPECT_TRUE(it != sm.end());
      EXPECT_EQ(it->first, j);
      EXPECT_EQ(it->second, j * 100);
    }
    EXPECT_EQ(sm.size(), static_cast<size_t>(i));
    EXPECT_FALSE(sm.empty());
  }
}

TEST(SmallMap, InsertRange) {
  // loop through the transition from small map to map.
  for (int elements = 0; elements <= 10; ++elements) {
    VLOG(1) << "Elements " << elements;
    hash_map<int, int> normal_map;
    for (int i = 1; i <= elements; ++i) {
      normal_map.insert(std::make_pair(i, 100*i));
    }

    SmallMap<hash_map<int, int> > sm;
    sm.insert(normal_map.begin(), normal_map.end());
    EXPECT_EQ(normal_map.size(), sm.size());
    for (int i = 1; i <= elements; ++i) {
      VLOG(1) << "Iteration " << i;
      EXPECT_TRUE(sm.find(i) != sm.end());
      EXPECT_EQ(sm.find(i)->first, i);
      EXPECT_EQ(sm.find(i)->second, 100*i);
    }
  }
}

TEST(SmallMap, Erase) {
  SmallMap<hash_map<std::string, int> > m;
  SmallMap<hash_map<std::string, int> >::iterator iter;

  m["monday"] = 1;
  m["tuesday"] = 2;
  m["wednesday"] = 3;

  EXPECT_EQ(m["monday"   ], 1);
  EXPECT_EQ(m["tuesday"  ], 2);
  EXPECT_EQ(m["wednesday"], 3);
  EXPECT_EQ(m.count("tuesday"), 1u);
  EXPECT_FALSE(m.UsingFullMap());

  iter = m.begin();
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, "monday");
  EXPECT_EQ(iter->second, 1);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, "tuesday");
  EXPECT_EQ(iter->second, 2);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, "wednesday");
  EXPECT_EQ(iter->second, 3);
  ++iter;
  EXPECT_TRUE(iter == m.end());

  EXPECT_EQ(m.erase("tuesday"), 1u);

  EXPECT_EQ(m["monday"   ], 1);
  EXPECT_EQ(m["wednesday"], 3);
  EXPECT_EQ(m.count("tuesday"), 0u);
  EXPECT_EQ(m.erase("tuesday"), 0u);

  iter = m.begin();
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, "monday");
  EXPECT_EQ(iter->second, 1);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, "wednesday");
  EXPECT_EQ(iter->second, 3);
  ++iter;
  EXPECT_TRUE(iter == m.end());

  m["thursday"] = 4;
  m["friday"] = 5;
  EXPECT_EQ(m.size(), 4u);
  EXPECT_FALSE(m.empty());
  EXPECT_FALSE(m.UsingFullMap());

  m["saturday"] = 6;
  EXPECT_TRUE(m.UsingFullMap());

  EXPECT_EQ(m.count("friday"), 1u);
  EXPECT_EQ(m.erase("friday"), 1u);
  EXPECT_TRUE(m.UsingFullMap());
  EXPECT_EQ(m.count("friday"), 0u);
  EXPECT_EQ(m.erase("friday"), 0u);

  EXPECT_EQ(m.size(), 4u);
  EXPECT_FALSE(m.empty());
  EXPECT_EQ(m.erase("monday"), 1u);
  EXPECT_EQ(m.size(), 3u);
  EXPECT_FALSE(m.empty());

  m.clear();
  EXPECT_FALSE(m.UsingFullMap());
  EXPECT_EQ(m.size(), 0u);
  EXPECT_TRUE(m.empty());
}

TEST(SmallMap, NonHashMap) {
  SmallMap<std::map<int, int>, 4, std::equal_to<int> > m;
  EXPECT_TRUE(m.empty());

  m[9] = 2;
  m[0] = 5;

  EXPECT_EQ(m[9], 2);
  EXPECT_EQ(m[0], 5);
  EXPECT_EQ(m.size(), 2u);
  EXPECT_FALSE(m.empty());
  EXPECT_FALSE(m.UsingFullMap());

  SmallMap<std::map<int, int>, 4, std::equal_to<int> >::iterator iter(
      m.begin());
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 9);
  EXPECT_EQ(iter->second, 2);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 0);
  EXPECT_EQ(iter->second, 5);
  ++iter;
  EXPECT_TRUE(iter == m.end());
  --iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 0);
  EXPECT_EQ(iter->second, 5);

  m[8] = 23;
  m[1234] = 90;
  m[-5] = 6;

  EXPECT_EQ(m[   9],  2);
  EXPECT_EQ(m[   0],  5);
  EXPECT_EQ(m[1234], 90);
  EXPECT_EQ(m[   8], 23);
  EXPECT_EQ(m[  -5],  6);
  EXPECT_EQ(m.size(), 5u);
  EXPECT_FALSE(m.empty());
  EXPECT_TRUE(m.UsingFullMap());

  iter = m.begin();
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, -5);
  EXPECT_EQ(iter->second, 6);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 0);
  EXPECT_EQ(iter->second, 5);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 8);
  EXPECT_EQ(iter->second, 23);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 9);
  EXPECT_EQ(iter->second, 2);
  ++iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 1234);
  EXPECT_EQ(iter->second, 90);
  ++iter;
  EXPECT_TRUE(iter == m.end());
  --iter;
  ASSERT_TRUE(iter != m.end());
  EXPECT_EQ(iter->first, 1234);
  EXPECT_EQ(iter->second, 90);
}

TEST(SmallMap, DefaultEqualKeyWorks) {
  // If these tests compile, they pass. The EXPECT calls are only there to avoid
  // unused variable warnings.
  SmallMap<hash_map<int, int> > hm;
  EXPECT_EQ(0u, hm.size());
  SmallMap<std::map<int, int> > m;
  EXPECT_EQ(0u, m.size());
}

namespace {

class hash_map_add_item : public hash_map<int, int> {
 public:
  hash_map_add_item() {}
  explicit hash_map_add_item(const std::pair<int, int>& item) {
    insert(item);
  }
};

void InitMap(ManualConstructor<hash_map_add_item>* map_ctor) {
  map_ctor->Init(std::make_pair(0, 0));
}

class hash_map_add_item_initializer {
 public:
  explicit hash_map_add_item_initializer(int item_to_add)
      : item_(item_to_add) {}
  hash_map_add_item_initializer()
      : item_(0) {}
  void operator()(ManualConstructor<hash_map_add_item>* map_ctor) const {
    map_ctor->Init(std::make_pair(item_, item_));
  }

  int item_;
};

}  // anonymous namespace

TEST(SmallMap, SubclassInitializationWithFunctionPointer) {
  SmallMap<hash_map_add_item, 4, std::equal_to<int>,
      void (&)(ManualConstructor<hash_map_add_item>*)> m(InitMap);

  EXPECT_TRUE(m.empty());

  m[1] = 1;
  m[2] = 2;
  m[3] = 3;
  m[4] = 4;

  EXPECT_EQ(4u, m.size());
  EXPECT_EQ(0u, m.count(0));

  m[5] = 5;
  EXPECT_EQ(6u, m.size());
  // Our function adds an extra item when we convert to a map.
  EXPECT_EQ(1u, m.count(0));
}

TEST(SmallMap, SubclassInitializationWithFunctionObject) {
  SmallMap<hash_map_add_item, 4, std::equal_to<int>,
      hash_map_add_item_initializer> m(hash_map_add_item_initializer(-1));

  EXPECT_TRUE(m.empty());

  m[1] = 1;
  m[2] = 2;
  m[3] = 3;
  m[4] = 4;

  EXPECT_EQ(4u, m.size());
  EXPECT_EQ(0u, m.count(-1));

  m[5] = 5;
  EXPECT_EQ(6u, m.size());
  // Our functor adds an extra item when we convert to a map.
  EXPECT_EQ(1u, m.count(-1));
}

}  // namespace base
