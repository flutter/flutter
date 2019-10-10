// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#include "flutter/testing/testing.h"

namespace flutter_tests {

TEST(SmokeTest, Success) {
  EXPECT_EQ(1, 1);
}

TEST(SmokeTest, Fail) {
  EXPECT_EQ(1, 2);
}

}
