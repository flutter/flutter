// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "url/deprecated_serialized_origin.h"

namespace url {

namespace {

// Each test examines the DeprecatedSerializedOrigin is constructed correctly
// without violating DCHECKs.
TEST(DeprecatedSerializedOriginTest, constructEmpty) {
  DeprecatedSerializedOrigin origin;
  EXPECT_EQ("null", origin.string());
}

TEST(DeprecatedSerializedOriginTest, constructNull) {
  DeprecatedSerializedOrigin origin("null");
  EXPECT_EQ("null", origin.string());
}

TEST(DeprecatedSerializedOriginTest, constructValid) {
  DeprecatedSerializedOrigin origin("http://example.com:8080");
  EXPECT_EQ("http://example.com:8080", origin.string());
}

TEST(DeprecatedSerializedOriginTest, constructValidFile) {
  DeprecatedSerializedOrigin origin("file://");
  EXPECT_EQ("file://", origin.string());
}

TEST(DeprecatedSerializedOriginTest, constructValidWithoutPort) {
  DeprecatedSerializedOrigin origin("wss://example2.com");
  EXPECT_EQ("wss://example2.com", origin.string());
}

}  // namespace

}  // namespace url
