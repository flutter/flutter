// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/status.h"

#include <string>

#include "gtest/gtest.h"

namespace fml {
namespace testing {

TEST(StatusTest, DefaultIsOk) {
  Status status;
  EXPECT_TRUE(status.ok());
  EXPECT_EQ(status.code(), StatusCode::kOk);
  EXPECT_TRUE(status.message().empty());
}

TEST(StatusTest, KeepsLiteralMessage) {
  Status status(StatusCode::kInternal, "literal");
  EXPECT_FALSE(status.ok());
  EXPECT_EQ(status.code(), StatusCode::kInternal);
  EXPECT_EQ(status.message(), "literal");
}

TEST(StatusTest, OwnsMessageBuiltAtRuntime) {
  std::string message = "first";
  Status status(StatusCode::kInternal, message);

  // Reuse the caller's buffer. A status that only viewed it would now read
  // "secon".
  message.assign("second");

  EXPECT_EQ(status.message(), "first");
}

TEST(StatusTest, MessageOutlivesTheString) {
  Status status;
  {
    std::string message =
        "Failed to submit command: a message long enough to live on the heap";
    status = Status(StatusCode::kCancelled, message);
  }
  // Overwrite freed memory the old message might still point into.
  std::string other(128, 'x');

  EXPECT_EQ(status.message(),
            "Failed to submit command: a message long enough to live on the "
            "heap");
}

TEST(StatusTest, CopiesKeepTheirOwnMessage) {
  Status copy;
  {
    std::string message = "copied";
    Status original(StatusCode::kAborted, message);
    copy = original;
    message.assign("change");
  }
  EXPECT_EQ(copy.code(), StatusCode::kAborted);
  EXPECT_EQ(copy.message(), "copied");
}

}  // namespace testing
}  // namespace fml
