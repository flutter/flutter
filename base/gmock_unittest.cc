// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This test is a simple sanity check to make sure gmock is able to build/link
// correctly.  It just instantiates a mock object and runs through a couple of
// the basic mock features.

#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

// Gmock matchers and actions that we use below.
using testing::AnyOf;
using testing::Eq;
using testing::Return;
using testing::SetArgumentPointee;
using testing::WithArg;
using testing::_;

namespace {

// Simple class that we can mock out the behavior for.  Everything is virtual
// for easy mocking.
class SampleClass {
 public:
  SampleClass() {}
  virtual ~SampleClass() {}

  virtual int ReturnSomething() {
    return -1;
  }

  virtual void ReturnNothingConstly() const {
  }

  virtual void OutputParam(int* a) {
  }

  virtual int ReturnSecond(int a, int b) {
    return b;
  }
};

// Declare a mock for the class.
class MockSampleClass : public SampleClass {
 public:
  MOCK_METHOD0(ReturnSomething, int());
  MOCK_CONST_METHOD0(ReturnNothingConstly, void());
  MOCK_METHOD1(OutputParam, void(int* a));
  MOCK_METHOD2(ReturnSecond, int(int a, int b));
};

// Create a couple of custom actions.  Custom actions can be used for adding
// more complex behavior into your mock...though if you start needing these, ask
// if you're asking your mock to do too much.
ACTION(ReturnVal) {
  // Return the first argument received.
  return arg0;
}
ACTION(ReturnSecond) {
  // Returns the second argument.  This basically implemetns ReturnSecond.
  return arg1;
}

TEST(GmockTest, SimpleMatchAndActions) {
  // Basic test of some simple gmock matchers, actions, and cardinality
  // expectations.
  MockSampleClass mock;

  EXPECT_CALL(mock, ReturnSomething())
      .WillOnce(Return(1))
      .WillOnce(Return(2))
      .WillOnce(Return(3));
  EXPECT_EQ(1, mock.ReturnSomething());
  EXPECT_EQ(2, mock.ReturnSomething());
  EXPECT_EQ(3, mock.ReturnSomething());

  EXPECT_CALL(mock, ReturnNothingConstly()).Times(2);
  mock.ReturnNothingConstly();
  mock.ReturnNothingConstly();
}

TEST(GmockTest, AssignArgument) {
  // Capture an argument for examination.
  MockSampleClass mock;

  EXPECT_CALL(mock, OutputParam(_))
      .WillRepeatedly(SetArgumentPointee<0>(5));

  int arg = 0;
  mock.OutputParam(&arg);
  EXPECT_EQ(5, arg);
}

TEST(GmockTest, SideEffects) {
  // Capture an argument for examination.
  MockSampleClass mock;

  EXPECT_CALL(mock, OutputParam(_))
      .WillRepeatedly(SetArgumentPointee<0>(5));

  int arg = 0;
  mock.OutputParam(&arg);
  EXPECT_EQ(5, arg);
}

TEST(GmockTest, CustomAction_ReturnSecond) {
  // Test a mock of the ReturnSecond behavior using an action that provides an
  // alternate implementation of the function.  Danger here though, this is
  // starting to add too much behavior of the mock, which means the mock
  // implementation might start to have bugs itself.
  MockSampleClass mock;

  EXPECT_CALL(mock, ReturnSecond(_, AnyOf(Eq(4), Eq(5))))
      .WillRepeatedly(ReturnSecond());
  EXPECT_EQ(4, mock.ReturnSecond(-1, 4));
  EXPECT_EQ(5, mock.ReturnSecond(0, 5));
  EXPECT_EQ(4, mock.ReturnSecond(0xdeadbeef, 4));
  EXPECT_EQ(4, mock.ReturnSecond(112358, 4));
  EXPECT_EQ(5, mock.ReturnSecond(1337, 5));
}

TEST(GmockTest, CustomAction_ReturnVal) {
  // Alternate implemention of ReturnSecond using a more general custom action,
  // and a WithArg adapter to bridge the interfaces.
  MockSampleClass mock;

  EXPECT_CALL(mock, ReturnSecond(_, AnyOf(Eq(4), Eq(5))))
      .WillRepeatedly(WithArg<1>(ReturnVal()));
  EXPECT_EQ(4, mock.ReturnSecond(-1, 4));
  EXPECT_EQ(5, mock.ReturnSecond(0, 5));
  EXPECT_EQ(4, mock.ReturnSecond(0xdeadbeef, 4));
  EXPECT_EQ(4, mock.ReturnSecond(112358, 4));
  EXPECT_EQ(5, mock.ReturnSecond(1337, 5));
}

}  // namespace
