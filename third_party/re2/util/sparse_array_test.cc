// Copyright 2006 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Simple tests that SparseArray behaves.

#include "util/util.h"
#include "utest/utest.h"

namespace re2 {

static const string kNotFound = "NOT FOUND";

TEST(SparseArray, BasicOperations) {
  static const int n = 50;
  SparseArray<int> set(n);

  int order[n];
  int value[n];
  for (int i = 0; i < n; i++)
    order[i] = i;
  for (int i = 0; i < n; i++)
    value[i] = rand()%1000 + 1;
  for (int i = 1; i < n; i++) {
    int j = rand()%i;
    int t = order[i];
    order[i] = order[j];
    order[j] = t;
  }

  for (int i = 0;; i++) {
    for (int j = 0; j < i; j++) {
      ASSERT_TRUE(set.has_index(order[j]));
      ASSERT_EQ(value[order[j]], set.get(order[j], -1));
    }
    if (i >= n)
      break;
    for (int j = i; j < n; j++)
      ASSERT_FALSE(set.has_index(order[j]));
    set.set(order[i], value[order[i]]);
  }

  int nn = 0;
  for (SparseArray<int>::iterator i = set.begin(); i != set.end(); ++i) {
    ASSERT_EQ(order[nn++], i->index());
    ASSERT_EQ(value[i->index()], i->value());
  }
  ASSERT_EQ(nn, n);

  set.clear();
  for (int i = 0; i < n; i++)
    ASSERT_FALSE(set.has_index(i));

  ASSERT_EQ(0, set.size());
  ASSERT_EQ(0, distance(set.begin(), set.end()));
}

class SparseArrayStringTest : public testing::Test {
 protected:
  SparseArrayStringTest()
      : str_map_(10) {
    InsertOrUpdate(&str_map_, 1, "a");
    InsertOrUpdate(&str_map_, 5, "b");
    InsertOrUpdate(&str_map_, 2, "c");
    InsertOrUpdate(&str_map_, 7, "d");
  }

  SparseArray<string> str_map_;
  typedef SparseArray<string>::iterator iterator;
};

TEST_F(SparseArrayStringTest, FindGetsPresentElement) {
  iterator it = str_map_.find(2);
  ASSERT_TRUE(str_map_.end() != it);
  EXPECT_EQ("c", it->second);
}

TEST_F(SparseArrayStringTest, FindDoesNotFindAbsentElement) {
  iterator it = str_map_.find(3);
  ASSERT_TRUE(str_map_.end() == it);
}

TEST_F(SparseArrayStringTest, ContainsKey) {
  EXPECT_TRUE(ContainsKey(str_map_, 1));
  EXPECT_TRUE(ContainsKey(str_map_, 2));
  EXPECT_FALSE(ContainsKey(str_map_, 3));
}

TEST_F(SparseArrayStringTest, InsertIfNotPresent) {
  EXPECT_FALSE(ContainsKey(str_map_, 3));
  EXPECT_TRUE(InsertIfNotPresent(&str_map_, 3, "r"));
  EXPECT_EQ("r", FindWithDefault(str_map_, 3, kNotFound));
  EXPECT_FALSE(InsertIfNotPresent(&str_map_, 3, "other value"));
  EXPECT_EQ("r", FindWithDefault(str_map_, 3, kNotFound));
}

TEST(SparseArrayTest, Erase) {
  SparseArray<string> str_map(5);
  str_map.set(1, "a");
  str_map.set(2, "b");
  EXPECT_EQ("a", FindWithDefault(str_map, 1, kNotFound));
  EXPECT_EQ("b", FindWithDefault(str_map, 2, kNotFound));
  str_map.erase(1);
  EXPECT_EQ("NOT FOUND", FindWithDefault(str_map, 1, kNotFound));
  EXPECT_EQ("b", FindWithDefault(str_map, 2, kNotFound));
}

typedef SparseArrayStringTest SparseArrayStringSurvivesInvalidIndexTest;
// TODO(jyasskin): Cover invalid arguments to every method.

TEST_F(SparseArrayStringSurvivesInvalidIndexTest, SetNegative) {
  EXPECT_DEBUG_DEATH(str_map_.set(-123456789, "hi"),
                     "\\(jyasskin\\) Illegal index -123456789 passed to"
                     " SparseArray\\(10\\).set\\(\\).");
  EXPECT_EQ(4, str_map_.size());
}

TEST_F(SparseArrayStringSurvivesInvalidIndexTest, SetTooBig) {
  EXPECT_DEBUG_DEATH(str_map_.set(12345678, "hi"),
                     "\\(jyasskin\\) Illegal index 12345678 passed to"
                     " SparseArray\\(10\\).set\\(\\).");
  EXPECT_EQ(4, str_map_.size());
}

TEST_F(SparseArrayStringSurvivesInvalidIndexTest, SetNew_Negative) {
  EXPECT_DEBUG_DEATH(str_map_.set_new(-123456789, "hi"),
                     "\\(jyasskin\\) Illegal index -123456789 passed to"
                     " SparseArray\\(10\\).set_new\\(\\).");
  EXPECT_EQ(4, str_map_.size());
}

TEST_F(SparseArrayStringSurvivesInvalidIndexTest, SetNew_Existing) {
  EXPECT_DEBUG_DEATH({
    str_map_.set_new(2, "hi");
    EXPECT_EQ("hi", FindWithDefault(str_map_, 2, kNotFound));

    // The old value for 2 is still present, but can never be removed.
    // This risks crashing later, if the map fills up.
    EXPECT_EQ(5, str_map_.size());
  }, "Check failed: !has_index\\(i\\)");
}

TEST_F(SparseArrayStringSurvivesInvalidIndexTest, SetNew_TooBig) {
  EXPECT_DEBUG_DEATH(str_map_.set_new(12345678, "hi"),
                     "\\(jyasskin\\) Illegal index 12345678 passed to"
                     " SparseArray\\(10\\).set_new\\(\\).");
  EXPECT_EQ(4, str_map_.size());
}

}  // namespace re2
