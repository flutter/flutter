// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_GTEST_PROD_UTIL_H_
#define BASE_GTEST_PROD_UTIL_H_

#include "testing/gtest/include/gtest/gtest_prod.h"

// This is a wrapper for gtest's FRIEND_TEST macro that friends
// test with all possible prefixes. This is very helpful when changing the test
// prefix, because the friend declarations don't need to be updated.
//
// Example usage:
//
// class MyClass {
//  private:
//   void MyMethod();
//   FRIEND_TEST_ALL_PREFIXES(MyClassTest, MyMethod);
// };
#define FRIEND_TEST_ALL_PREFIXES(test_case_name, test_name) \
  FRIEND_TEST(test_case_name, test_name); \
  FRIEND_TEST(test_case_name, DISABLED_##test_name); \
  FRIEND_TEST(test_case_name, FLAKY_##test_name)

// C++ compilers will refuse to compile the following code:
//
// namespace foo {
// class MyClass {
//  private:
//   FRIEND_TEST_ALL_PREFIXES(MyClassTest, TestMethod);
//   bool private_var;
// };
// }  // namespace foo
//
// class MyClassTest::TestMethod() {
//   foo::MyClass foo_class;
//   foo_class.private_var = true;
// }
//
// Unless you forward declare MyClassTest::TestMethod outside of namespace foo.
// Use FORWARD_DECLARE_TEST to do so for all possible prefixes.
//
// Example usage:
//
// FORWARD_DECLARE_TEST(MyClassTest, TestMethod);
//
// namespace foo {
// class MyClass {
//  private:
//   FRIEND_TEST_ALL_PREFIXES(::MyClassTest, TestMethod);  // NOTE use of ::
//   bool private_var;
// };
// }  // namespace foo
//
// class MyClassTest::TestMethod() {
//   foo::MyClass foo_class;
//   foo_class.private_var = true;
// }

#define FORWARD_DECLARE_TEST(test_case_name, test_name) \
  class test_case_name##_##test_name##_Test; \
  class test_case_name##_##DISABLED_##test_name##_Test; \
  class test_case_name##_##FLAKY_##test_name##_Test

#endif  // BASE_GTEST_PROD_UTIL_H_
