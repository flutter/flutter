// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_ASSERT_OK_H_
#define FLUTTER_TESTING_ASSERT_OK_H_

#include "gtest/gtest.h"

// Asserts that the given absl::Status or absl::StatusOr is OK.
// If it is not OK, the status error message is printed.
#ifdef ASSERT_OK
#error "ASSERT_OK is already defined"
#endif
#define ASSERT_OK(status_or) \
  ASSERT_TRUE(status_or.ok()) << status_or.status().ToString()

// Expects that the given absl::Status or absl::StatusOr is OK.
// If it is not OK, the status error message is printed.
#ifdef EXPECT_OK
#error "EXPECT_OK is already defined"
#endif
#define EXPECT_OK(status_or) \
  EXPECT_TRUE(status_or.ok()) << status_or.status().ToString()

#endif  // FLUTTER_TESTING_ASSERT_OK_H_
