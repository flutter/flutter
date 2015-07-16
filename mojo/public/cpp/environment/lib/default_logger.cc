// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/lib/default_logger.h"

#include <stdio.h>
#include <stdlib.h>  // For |abort()|.

#include <algorithm>

#include "mojo/public/c/environment/logger.h"

namespace mojo {

namespace {

MojoLogLevel g_minimum_log_level = MOJO_LOG_LEVEL_INFO;

const char* GetLogLevelString(MojoLogLevel log_level) {
  if (log_level <= MOJO_LOG_LEVEL_VERBOSE - 3)
    return "VERBOSE4+";
  switch (log_level) {
    case MOJO_LOG_LEVEL_VERBOSE - 2:
      return "VERBOSE3";
    case MOJO_LOG_LEVEL_VERBOSE - 1:
      return "VERBOSE2";
    case MOJO_LOG_LEVEL_VERBOSE:
      return "VERBOSE1";
    case MOJO_LOG_LEVEL_INFO:
      return "INFO";
    case MOJO_LOG_LEVEL_WARNING:
      return "WARNING";
    case MOJO_LOG_LEVEL_ERROR:
      return "ERROR";
  }
  // Consider everything higher to be fatal.
  return "FATAL";
}

void LogMessage(MojoLogLevel log_level,
                const char* source_file,
                uint32_t source_line,
                const char* message) {
  if (log_level < g_minimum_log_level)
    return;

  // TODO(vtl): Add timestamp also?
  if (source_file) {
    fprintf(stderr, "%s: %s(%u): %s\n", GetLogLevelString(log_level),
            source_file, static_cast<unsigned>(source_line), message);
  } else {
    fprintf(stderr, "%s: %s\n", GetLogLevelString(log_level), message);
  }
  if (log_level >= MOJO_LOG_LEVEL_FATAL)
    abort();
}

MojoLogLevel GetMinimumLogLevel() {
  return g_minimum_log_level;
}

void SetMinimumLogLevel(MojoLogLevel minimum_log_level) {
  g_minimum_log_level = std::min(minimum_log_level, MOJO_LOG_LEVEL_FATAL);
}

}  // namespace

namespace internal {

const MojoLogger kDefaultLogger = {LogMessage,
                                   GetMinimumLogLevel,
                                   SetMinimumLogLevel};

}  // namespace internal

}  // namespace mojo
