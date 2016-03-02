// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Utilities for (non-test) code to help with testing that code with gtest.
// (Note that this file does not imply any dependency on gtest.)

#ifndef MOJO_EDK_UTIL_GTEST_PROD_UTILS_H_
#define MOJO_EDK_UTIL_GTEST_PROD_UTILS_H_

// Like gtest's |FRIEND_TEST()| macro, but friends the given test with all
// possible prefixes, so that when the test prefix is changed the friend
// declarations won't need to be updated. For example:
//
//   class MyClass {
//    private:
//     void MyMethod();
//     FRIEND_TEST_ALL_PREFIXES(MyClassTest, MyMethod);
//   };
#define FRIEND_TEST_ALL_PREFIXES(test_case_name, test_name)    \
  friend class test_case_name##_##test_name##_Test;            \
  friend class test_case_name##_##DISABLED_##test_name##_Test; \
  friend class test_case_name##_##FLAKY_##test_name##_Test

// Macro to forward-declare tests (with all possible prefixes).
//
// C++ compilers will refuse to compile the following code:
//
//   namespace foo {
//   class MyClass {
//    private:
//     FRIEND_TEST_ALL_PREFIXES(MyClassTest, TestMethod);
//     bool private_var;
//   };
//   }  // namespace foo
//
//   class MyClassTest::TestMethod() {
//     foo::MyClass foo_class;
//     foo_class.private_var = true;
//   }
//
// unless you forward-declare |MyClassTest::TestMethod| outside of the |foo|
// namespace. Use |FORWARD_DECLARE_TEST()| to do this. For example, in the code,
// add the following at the top:
//
//   FORWARD_DECLARE_TEST(MyClassTest, TestMethod);
#define FORWARD_DECLARE_TEST(test_case_name, test_name) \
  class test_case_name##_##test_name##_Test;            \
  class test_case_name##_##DISABLED_##test_name##_Test; \
  class test_case_name##_##FLAKY_##test_name##_Test

#endif  // MOJO_EDK_UTIL_GTEST_PROD_UTILS_H_
