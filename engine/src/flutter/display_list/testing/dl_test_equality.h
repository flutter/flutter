// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_EQUALITY_H_
#define FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_EQUALITY_H_

#include "flutter/display_list/display_list_attributes.h"
#include "flutter/display_list/display_list_comparable.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

template <class T>
static void TestEquals(T& source1, T& source2) {
  ASSERT_TRUE(source1 == source2);
  ASSERT_TRUE(source2 == source1);
  ASSERT_FALSE(source1 != source2);
  ASSERT_FALSE(source2 != source1);
  ASSERT_EQ(source1, source2);
  ASSERT_EQ(source2, source1);
  ASSERT_TRUE(Equals(&source1, &source2));
  ASSERT_TRUE(Equals(&source2, &source1));
}

template <class T>
static void TestNotEquals(T& source1, T& source2, std::string label) {
  ASSERT_FALSE(source1 == source2) << label;
  ASSERT_FALSE(source2 == source1) << label;
  ASSERT_TRUE(source1 != source2) << label;
  ASSERT_TRUE(source2 != source1) << label;
  ASSERT_NE(source1, source2) << label;
  ASSERT_NE(source2, source1) << label;
  ASSERT_TRUE(NotEquals(&source1, &source2));
  ASSERT_TRUE(NotEquals(&source2, &source1));
}

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_TESTING_DL_TEST_EQUALITY_H_
