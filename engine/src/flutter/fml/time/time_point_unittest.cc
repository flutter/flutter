// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/time/chrono_timestamp_provider.h"

#include "gtest/gtest.h"

namespace fml {
namespace {

TEST(TimePoint, Control) {
  EXPECT_LT(TimePoint::Min(), ChronoTicksSinceEpoch());
  EXPECT_GT(TimePoint::Max(), ChronoTicksSinceEpoch());
}

}  // namespace
}  // namespace fml
