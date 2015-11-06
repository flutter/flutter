// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/perf_log.h"

#include "base/test/perf_log.h"

namespace mojo {
namespace system {
namespace test {

void LogPerfResult(const char* test_name, double value, const char* units) {
  base::LogPerfResult(test_name, value, units);
}

}  // namespace test
}  // namespace system
}  // namespace mojo
