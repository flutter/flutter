// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_COVERAGE_UTIL_IOS_H_
#define TESTING_COVERAGE_UTIL_IOS_H_

namespace coverage_util {

// Flushes .gcda coverage files if ENABLE_TEST_CODE_COVERAGE is defined. iOS 7
// does not call any code at the "end" of an app so flushing should be
// performed manually.
void FlushCoverageDataIfNecessary();

}  // namespace coverage_util

#endif  // TESTING_COVERAGE_UTIL_IOS_H_
