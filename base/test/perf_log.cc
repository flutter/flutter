// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/perf_log.h"

#include "base/files/file_util.h"
#include "base/logging.h"

namespace base {

static FILE* perf_log_file = NULL;

bool InitPerfLog(const FilePath& log_file) {
  if (perf_log_file) {
    // trying to initialize twice
    NOTREACHED();
    return false;
  }

  perf_log_file = OpenFile(log_file, "w");
  return perf_log_file != NULL;
}

void FinalizePerfLog() {
  if (!perf_log_file) {
    // trying to cleanup without initializing
    NOTREACHED();
    return;
  }
  base::CloseFile(perf_log_file);
}

void LogPerfResult(const char* test_name, double value, const char* units) {
  if (!perf_log_file) {
    NOTREACHED();
    return;
  }

  fprintf(perf_log_file, "%s\t%g\t%s\n", test_name, value, units);
  printf("%s\t%g\t%s\n", test_name, value, units);
  fflush(stdout);
}

}  // namespace base
