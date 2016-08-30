// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/systrace_logger.h"
#include "lib/ftl/files/eintr_wrapper.h"

#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

namespace sky {
namespace shell {

static const size_t kBufferSize = 256;

SystraceLogger::SystraceLogger()
    : trace_fd_(HANDLE_EINTR(
          ::open("/sys/kernel/debug/tracing/trace_marker", O_WRONLY))),
      pid_(getpid()) {}

SystraceLogger::~SystraceLogger() {
  IGNORE_EINTR(::close(trace_fd_));
}

void SystraceLogger::TraceBegin(const char* label) const {
  char buffer[kBufferSize];
  int buffer_written = snprintf(buffer, sizeof(buffer), "B|%d|%s", pid_, label);

  if (buffer_written <= 0 || buffer_written > kBufferSize) {
    return;
  }

  HANDLE_EINTR(::write(trace_fd_, buffer, buffer_written));
}

void SystraceLogger::TraceEnd() const {
  HANDLE_EINTR(::write(trace_fd_, "E", 1));
}

void SystraceLogger::TraceCount(const char* label, int count) const {
  char buffer[kBufferSize];

  int buffer_written =
      snprintf(buffer, sizeof(buffer), "C|%d|%s|%d", pid_, label, count);

  if (buffer_written <= 0 || buffer_written > kBufferSize) {
    return;
  }

  HANDLE_EINTR(::write(trace_fd_, buffer, buffer_written));
}

}  // namespace shell
}  // namespace sky
