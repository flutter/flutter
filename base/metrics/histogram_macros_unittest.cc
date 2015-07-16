// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_macros.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(ScopedHistogramTimer, TwoTimersOneScope) {
  SCOPED_UMA_HISTOGRAM_TIMER("TestTimer0");
  SCOPED_UMA_HISTOGRAM_TIMER("TestTimer1");
  SCOPED_UMA_HISTOGRAM_LONG_TIMER("TestLongTimer0");
  SCOPED_UMA_HISTOGRAM_LONG_TIMER("TestLongTimer1");
}

}  // namespace base
