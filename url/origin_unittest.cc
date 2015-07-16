// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "url/origin.h"

namespace url {

namespace {

// Each test examines the Origin is constructed correctly without
// violating DCHECKs.
TEST(OriginTest, constructEmpty) {
  Origin origin;
  EXPECT_EQ("null", origin.string());
}

TEST(OriginTest, constructNull) {
  Origin origin("null");
  EXPECT_EQ("null", origin.string());
}

TEST(OriginTest, constructValidOrigin) {
  Origin origin("http://example.com:8080");
  EXPECT_EQ("http://example.com:8080", origin.string());
}

TEST(OriginTest, constructValidFileOrigin) {
  Origin origin("file://");
  EXPECT_EQ("file://", origin.string());
}

TEST(OriginTest, constructValidOriginWithoutPort) {
  Origin origin("wss://example2.com");
  EXPECT_EQ("wss://example2.com", origin.string());
}

}  // namespace

}  // namespace url
