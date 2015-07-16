// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extern "C" void __gcov_flush();

namespace coverage_util {

void FlushCoverageDataIfNecessary() {
#if defined(ENABLE_TEST_CODE_COVERAGE)
  __gcov_flush();
#endif
}

}  // namespace coverage_util
