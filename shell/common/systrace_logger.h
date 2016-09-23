// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_SYSTRACE_LOGGER_H_
#define SHELL_COMMON_SYSTRACE_LOGGER_H_

#include "lib/ftl/macros.h"

#include <sys/types.h>

namespace shell {

class SystraceLogger {
 public:
  SystraceLogger();

  ~SystraceLogger();

  void TraceBegin(const char* label) const;

  void TraceEnd() const;

  void TraceCount(const char* label, int count) const;

 private:
  int trace_fd_;
  int pid_;

  FTL_DISALLOW_COPY_AND_ASSIGN(SystraceLogger);
};

}  // namespace shell

#endif  // SHELL_COMMON_SYSTRACE_LOGGER_H_
