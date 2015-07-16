// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/id_map.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace {

class TestObject {
};

class DestructorCounter {
 public:
  explicit DestructorCounter(int* counter) : counter_(counter) {}
  ~DestructorCounter() { ++(*counter_); }

 private:
  int* counter_;
};

TEST(IDMapTest, Basic) {
  IDMap<TestObject> map;
  EXPECT_TRUE(map.IsEmpty());
  EXPECT_EQ(0U, map.size());

  TestObject obj1;
  TestObject obj2;

  int32 id1 = map.Add(&obj1);
  EXPECT_FALSE(map.IsEmpty());
  EXPECT_EQ(1U, map.size());
  EXPECT_EQ(&obj1, map.Lookup(id1));

  int32 id2 = map.Add(&obj2);
  EXPECT_FALSE(map.IsEmpty());
  EXPECT_EQ(2U, map.size());

  EXPECT_EQ(&obj1, map.Lookup(id1));
  EXPECT_EQ(&obj2, map.Lookup(id2));

  map.Remove(id1);
  EXPECT_FALSE(map.IsEmpty());
  EXPECT_EQ(1U, map.size());

  map.Remove(id2);
  EXPECT_TRUE(map.IsEmpty());
  EXPECT_EQ(0U, map.size());

  map.AddWithID(&obj1, 1);
  map.AddWithID(&obj2, 2);
  EXPECT_EQ(&obj1, map.Lookup(1));
  EXPECT_EQ(&obj2, map.Lookup(2));

  EXPECT_EQ(&obj2, map.Replace(2, &obj1));
  EXPECT_EQ(&obj1, map.Lookup(2));

  EXPECT_EQ(0, map.iteration_depth());
}

TEST(IDMapTest, IteratorRemainsValidWhenRemovingCurrentElement) {
  IDMap<TestObject> map;

  TestObject obj1;
  TestObject obj2;
  TestObject obj3;

  map.Add(&obj1);
  map.Add(&obj2);
  map.Add(&obj3);

  {
    IDMap<TestObject>::const_iterator iter(&map);

    EXPECT_EQ(1, map.iteration_depth());

    while (!iter.IsAtEnd()) {
      map.Remove(iter.GetCurrentKey());
      iter.Advance();
    }

    // Test that while an iterator is still in scope, we get the map emptiness
    // right (http://crbug.com/35571).
    EXPECT_TRUE(map.IsEmpty());
    EXPECT_EQ(0U, map.size());
  }

  EXPECT_TRUE(map.IsEmpty());
  EXPECT_EQ(0U, map.size());

  EXPECT_EQ(0, map.iteration_depth());
}

TEST(IDMapTest, IteratorRemainsValidWhenRemovingOtherElements) {
  IDMap<TestObject> map;

  const int kCount = 5;
  TestObject obj[kCount];

  for (int i = 0; i < kCount; i++)
    map.Add(&obj[i]);

  // IDMap uses a hash_map, which has no predictable iteration order.
  int32 ids_in_iteration_order[kCount];
  const TestObject* objs_in_iteration_order[kCount];
  int counter = 0;
  for (IDMap<TestObject>::const_iterator iter(&map);
       !iter.IsAtEnd(); iter.Advance()) {
    ids_in_iteration_order[counter] = iter.GetCurrentKey();
    objs_in_iteration_order[counter] = iter.GetCurrentValue();
    counter++;
  }

  counter = 0;
  for (IDMap<TestObject>::const_iterator iter(&map);
       !iter.IsAtEnd(); iter.Advance()) {
    EXPECT_EQ(1, map.iteration_depth());

    switch (counter) {
      case 0:
        EXPECT_EQ(ids_in_iteration_order[0], iter.GetCurrentKey());
        EXPECT_EQ(objs_in_iteration_order[0], iter.GetCurrentValue());
        map.Remove(ids_in_iteration_order[1]);
        break;
      case 1:
        EXPECT_EQ(ids_in_iteration_order[2], iter.GetCurrentKey());
        EXPECT_EQ(objs_in_iteration_order[2], iter.GetCurrentValue());
        map.Remove(ids_in_iteration_order[3]);
        break;
      case 2:
        EXPECT_EQ(ids_in_iteration_order[4], iter.GetCurrentKey());
        EXPECT_EQ(objs_in_iteration_order[4], iter.GetCurrentValue());
        map.Remove(ids_in_iteration_order[0]);
        break;
      default:
        FAIL() << "should not have that many elements";
        break;
    }

    counter++;
  }

  EXPECT_EQ(0, map.iteration_depth());
}

TEST(IDMapTest, CopyIterator) {
  IDMap<TestObject> map;

  TestObject obj1;
  TestObject obj2;
  TestObject obj3;

  map.Add(&obj1);
  map.Add(&obj2);
  map.Add(&obj3);

  EXPECT_EQ(0, map.iteration_depth());

  {
    IDMap<TestObject>::const_iterator iter1(&map);
    EXPECT_EQ(1, map.iteration_depth());

    // Make sure that copying the iterator correctly increments
    // map's iteration depth.
    IDMap<TestObject>::const_iterator iter2(iter1);
    EXPECT_EQ(2, map.iteration_depth());
  }

  // Make sure after destroying all iterators the map's iteration depth
  // returns to initial state.
  EXPECT_EQ(0, map.iteration_depth());
}

TEST(IDMapTest, AssignIterator) {
  IDMap<TestObject> map;

  TestObject obj1;
  TestObject obj2;
  TestObject obj3;

  map.Add(&obj1);
  map.Add(&obj2);
  map.Add(&obj3);

  EXPECT_EQ(0, map.iteration_depth());

  {
    IDMap<TestObject>::const_iterator iter1(&map);
    EXPECT_EQ(1, map.iteration_depth());

    IDMap<TestObject>::const_iterator iter2(&map);
    EXPECT_EQ(2, map.iteration_depth());

    // Make sure that assigning the iterator correctly updates
    // map's iteration depth (-1 for destruction, +1 for assignment).
    EXPECT_EQ(2, map.iteration_depth());
  }

  // Make sure after destroying all iterators the map's iteration depth
  // returns to initial state.
  EXPECT_EQ(0, map.iteration_depth());
}

TEST(IDMapTest, IteratorRemainsValidWhenClearing) {
  IDMap<TestObject> map;

  const int kCount = 5;
  TestObject obj[kCount];

  for (int i = 0; i < kCount; i++)
    map.Add(&obj[i]);

  // IDMap uses a hash_map, which has no predictable iteration order.
  int32 ids_in_iteration_order[kCount];
  const TestObject* objs_in_iteration_order[kCount];
  int counter = 0;
  for (IDMap<TestObject>::const_iterator iter(&map);
       !iter.IsAtEnd(); iter.Advance()) {
    ids_in_iteration_order[counter] = iter.GetCurrentKey();
    objs_in_iteration_order[counter] = iter.GetCurrentValue();
    counter++;
  }

  counter = 0;
  for (IDMap<TestObject>::const_iterator iter(&map);
       !iter.IsAtEnd(); iter.Advance()) {
    switch (counter) {
      case 0:
        EXPECT_EQ(ids_in_iteration_order[0], iter.GetCurrentKey());
        EXPECT_EQ(objs_in_iteration_order[0], iter.GetCurrentValue());
        break;
      case 1:
        EXPECT_EQ(ids_in_iteration_order[1], iter.GetCurrentKey());
        EXPECT_EQ(objs_in_iteration_order[1], iter.GetCurrentValue());
        map.Clear();
        EXPECT_TRUE(map.IsEmpty());
        EXPECT_EQ(0U, map.size());
        break;
      default:
        FAIL() << "should not have that many elements";
        break;
    }
    counter++;
  }

  EXPECT_TRUE(map.IsEmpty());
  EXPECT_EQ(0U, map.size());
}

TEST(IDMapTest, OwningPointersDeletesThemOnRemove) {
  const int kCount = 3;

  int external_del_count = 0;
  DestructorCounter* external_obj[kCount];
  int map_external_ids[kCount];

  int owned_del_count = 0;
  DestructorCounter* owned_obj[kCount];
  int map_owned_ids[kCount];

  IDMap<DestructorCounter> map_external;
  IDMap<DestructorCounter, IDMapOwnPointer> map_owned;

  for (int i = 0; i < kCount; ++i) {
    external_obj[i] = new DestructorCounter(&external_del_count);
    map_external_ids[i] = map_external.Add(external_obj[i]);

    owned_obj[i] = new DestructorCounter(&owned_del_count);
    map_owned_ids[i] = map_owned.Add(owned_obj[i]);
  }

  for (int i = 0; i < kCount; ++i) {
    EXPECT_EQ(external_del_count, 0);
    EXPECT_EQ(owned_del_count, i);

    map_external.Remove(map_external_ids[i]);
    map_owned.Remove(map_owned_ids[i]);
  }

  for (int i = 0; i < kCount; ++i) {
    delete external_obj[i];
  }

  EXPECT_EQ(external_del_count, kCount);
  EXPECT_EQ(owned_del_count, kCount);
}

TEST(IDMapTest, OwningPointersDeletesThemOnClear) {
  const int kCount = 3;

  int external_del_count = 0;
  DestructorCounter* external_obj[kCount];

  int owned_del_count = 0;
  DestructorCounter* owned_obj[kCount];

  IDMap<DestructorCounter> map_external;
  IDMap<DestructorCounter, IDMapOwnPointer> map_owned;

  for (int i = 0; i < kCount; ++i) {
    external_obj[i] = new DestructorCounter(&external_del_count);
    map_external.Add(external_obj[i]);

    owned_obj[i] = new DestructorCounter(&owned_del_count);
    map_owned.Add(owned_obj[i]);
  }

  EXPECT_EQ(external_del_count, 0);
  EXPECT_EQ(owned_del_count, 0);

  map_external.Clear();
  map_owned.Clear();

  EXPECT_EQ(external_del_count, 0);
  EXPECT_EQ(owned_del_count, kCount);

  for (int i = 0; i < kCount; ++i) {
    delete external_obj[i];
  }

  EXPECT_EQ(external_del_count, kCount);
  EXPECT_EQ(owned_del_count, kCount);
}

TEST(IDMapTest, OwningPointersDeletesThemOnDestruct) {
  const int kCount = 3;

  int external_del_count = 0;
  DestructorCounter* external_obj[kCount];

  int owned_del_count = 0;
  DestructorCounter* owned_obj[kCount];

  {
    IDMap<DestructorCounter> map_external;
    IDMap<DestructorCounter, IDMapOwnPointer> map_owned;

    for (int i = 0; i < kCount; ++i) {
      external_obj[i] = new DestructorCounter(&external_del_count);
      map_external.Add(external_obj[i]);

      owned_obj[i] = new DestructorCounter(&owned_del_count);
      map_owned.Add(owned_obj[i]);
    }
  }

  EXPECT_EQ(external_del_count, 0);

  for (int i = 0; i < kCount; ++i) {
    delete external_obj[i];
  }

  EXPECT_EQ(external_del_count, kCount);
  EXPECT_EQ(owned_del_count, kCount);
}

}  // namespace
