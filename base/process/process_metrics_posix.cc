// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <sys/resource.h>
#include <sys/time.h>

#include "base/logging.h"

namespace base {

int64 TimeValToMicroseconds(const struct timeval& tv) {
  int64 ret = tv.tv_sec;  // Avoid (int * int) integer overflow.
  ret *= Time::kMicrosecondsPerSecond;
  ret += tv.tv_usec;
  return ret;
}

ProcessMetrics::~ProcessMetrics() { }

#if defined(OS_LINUX)
static const rlim_t kSystemDefaultMaxFds = 8192;
#elif defined(OS_MACOSX)
static const rlim_t kSystemDefaultMaxFds = 256;
#elif defined(OS_SOLARIS)
static const rlim_t kSystemDefaultMaxFds = 8192;
#elif defined(OS_FREEBSD)
static const rlim_t kSystemDefaultMaxFds = 8192;
#elif defined(OS_OPENBSD)
static const rlim_t kSystemDefaultMaxFds = 256;
#elif defined(OS_ANDROID)
static const rlim_t kSystemDefaultMaxFds = 1024;
#endif

size_t GetMaxFds() {
  rlim_t max_fds;
  struct rlimit nofile;
  if (getrlimit(RLIMIT_NOFILE, &nofile)) {
    // getrlimit failed. Take a best guess.
    max_fds = kSystemDefaultMaxFds;
    RAW_LOG(ERROR, "getrlimit(RLIMIT_NOFILE) failed");
  } else {
    max_fds = nofile.rlim_cur;
  }

  if (max_fds > INT_MAX)
    max_fds = INT_MAX;

  return static_cast<size_t>(max_fds);
}


void SetFdLimit(unsigned int max_descriptors) {
  struct rlimit limits;
  if (getrlimit(RLIMIT_NOFILE, &limits) == 0) {
    unsigned int new_limit = max_descriptors;
    if (limits.rlim_max > 0 && limits.rlim_max < max_descriptors) {
      new_limit = limits.rlim_max;
    }
    limits.rlim_cur = new_limit;
    if (setrlimit(RLIMIT_NOFILE, &limits) != 0) {
      PLOG(INFO) << "Failed to set file descriptor limit";
    }
  } else {
    PLOG(INFO) << "Failed to get file descriptor limit";
  }
}

size_t GetPageSize() {
  return getpagesize();
}

}  // namespace base
