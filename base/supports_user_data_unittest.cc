// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/supports_user_data.h"

#include <vector>

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

struct TestSupportsUserData : public SupportsUserData {};

struct UsesItself : public SupportsUserData::Data {
  UsesItself(SupportsUserData* supports_user_data, const void* key)
      : supports_user_data_(supports_user_data),
        key_(key) {
  }

  ~UsesItself() override {
    EXPECT_EQ(NULL, supports_user_data_->GetUserData(key_));
  }

  SupportsUserData* supports_user_data_;
  const void* key_;
};

TEST(SupportsUserDataTest, ClearWorksRecursively) {
  TestSupportsUserData supports_user_data;
  char key = 0;
  supports_user_data.SetUserData(&key,
                                 new UsesItself(&supports_user_data, &key));
  // Destruction of supports_user_data runs the actual test.
}

}  // namespace
}  // namespace base
