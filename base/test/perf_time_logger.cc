// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/perf_time_logger.h"

#include "base/test/perf_log.h"

namespace base {

PerfTimeLogger::PerfTimeLogger(const char* test_name)
    : logged_(false), test_name_(test_name) {}

PerfTimeLogger::~PerfTimeLogger() {
  if (!logged_)
    Done();
}

void PerfTimeLogger::Done() {
  // we use a floating-point millisecond value because it is more
  // intuitive than microseconds and we want more precision than
  // integer milliseconds
  LogPerfResult(test_name_.c_str(), timer_.Elapsed().InMillisecondsF(), "ms");
  logged_ = true;
}

}  // namespace base
