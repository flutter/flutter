// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for logging perf test results.

#ifndef MOJO_EDK_SYSTEM_TEST_PERF_LOG_H_
#define MOJO_EDK_SYSTEM_TEST_PERF_LOG_H_

namespace mojo {
namespace system {
namespace test {

// TODO(vtl): Possibly should have our own "InitPerfLog()" and
// "FinalizePerfLog()" functions, but we can't do that until we stop using
// |base::PerfTestSuite()|. Currently,

// Logs the result of a perf test. You may only call this while running inside a
// perf test suite (using the :run_all_perftests from this directory).
void LogPerfResult(const char* test_name, double value, const char* units);

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_PERF_LOG_H_
