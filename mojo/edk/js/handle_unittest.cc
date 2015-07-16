// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/macros.h"
#include "mojo/edk/js/handle.h"
#include "mojo/edk/js/handle_close_observer.h"
#include "mojo/public/cpp/system/core.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace js {

class HandleWrapperTest : public testing::Test,
                          public HandleCloseObserver {
 public:
  HandleWrapperTest() : closes_observed_(0) {}

  void OnWillCloseHandle() override { closes_observed_++; }

 protected:
  int closes_observed_;

 private:
  DISALLOW_COPY_AND_ASSIGN(HandleWrapperTest);
};

class TestHandleWrapper : public HandleWrapper {
 public:
  explicit TestHandleWrapper(MojoHandle handle) : HandleWrapper(handle) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(TestHandleWrapper);
};

// Test that calling Close() on a HandleWrapper for an invalid handle does not
// notify observers.
TEST_F(HandleWrapperTest, CloseWithInvalidHandle) {
  {
    TestHandleWrapper wrapper(MOJO_HANDLE_INVALID);
    wrapper.AddCloseObserver(this);
    ASSERT_EQ(0, closes_observed_);
    wrapper.Close();
    EXPECT_EQ(0, closes_observed_);
  }
  EXPECT_EQ(0, closes_observed_);
}

// Test that destroying a HandleWrapper for an invalid handle does not notify
// observers.
TEST_F(HandleWrapperTest, DestroyWithInvalidHandle) {
  {
    TestHandleWrapper wrapper(MOJO_HANDLE_INVALID);
    wrapper.AddCloseObserver(this);
    ASSERT_EQ(0, closes_observed_);
  }
  EXPECT_EQ(0, closes_observed_);
}

// Test that calling Close on a HandleWrapper for a valid handle notifies
// observers once.
TEST_F(HandleWrapperTest, CloseWithValidHandle) {
  {
    mojo::MessagePipe pipe;
    TestHandleWrapper wrapper(pipe.handle0.release().value());
    wrapper.AddCloseObserver(this);
    ASSERT_EQ(0, closes_observed_);
    wrapper.Close();
    EXPECT_EQ(1, closes_observed_);
    // Check that calling close again doesn't notify observers.
    wrapper.Close();
    EXPECT_EQ(1, closes_observed_);
  }
  // Check that destroying a closed HandleWrapper doesn't notify observers.
  EXPECT_EQ(1, closes_observed_);
}

// Test that destroying a HandleWrapper for a valid handle notifies observers.
TEST_F(HandleWrapperTest, DestroyWithValidHandle) {
  {
    mojo::MessagePipe pipe;
    TestHandleWrapper wrapper(pipe.handle0.release().value());
    wrapper.AddCloseObserver(this);
    ASSERT_EQ(0, closes_observed_);
  }
  EXPECT_EQ(1, closes_observed_);
}

}  // namespace js
}  // namespace mojo
