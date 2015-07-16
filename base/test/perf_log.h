// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TEST_PERF_LOG_H_
#define BASE_TEST_PERF_LOG_H_

namespace base {

class FilePath;

// Initializes and finalizes the perf log. These functions should be
// called at the beginning and end (respectively) of running all the
// performance tests. The init function returns true on success.
bool InitPerfLog(const FilePath& log_path);
void FinalizePerfLog();

// Writes to the perf result log the given 'value' resulting from the
// named 'test'. The units are to aid in reading the log by people.
void LogPerfResult(const char* test_name, double value, const char* units);

}  // namespace base

#endif  // BASE_TEST_PERF_LOG_H_
