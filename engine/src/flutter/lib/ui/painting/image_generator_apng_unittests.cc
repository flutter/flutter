// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/image_generator_apng.h"

#include "flutter/shell/common/shell_test.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

TEST_F(ShellTest, RejectsApngWithFrameDataLengthLessThanFour) {
  auto data = OpenFixtureAsSkData("apng_fdat_len0.apng");
  ASSERT_NE(data, nullptr);

  auto generator = APNGImageGenerator::MakeFromData(std::move(data));
  ASSERT_EQ(generator, nullptr);
}

TEST_F(ShellTest, AcceptsApngWithFrameDataLengthEqualToFour) {
  auto data = OpenFixtureAsSkData("apng_fdat_len4.apng");
  ASSERT_NE(data, nullptr);

  auto generator = APNGImageGenerator::MakeFromData(std::move(data));
  ASSERT_NE(generator, nullptr);
}

}  // namespace testing
}  // namespace flutter
