// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/environment/default_logger_impl.h"

#include "base/logging.h"
#include "base/macros.h"

namespace mojo {
namespace internal {
namespace {

// We rely on log levels being the same numerically:
COMPILE_ASSERT(logging::LOG_VERBOSE == MOJO_LOG_LEVEL_VERBOSE,
               verbose_log_level_value_mismatch);
COMPILE_ASSERT(logging::LOG_INFO == MOJO_LOG_LEVEL_INFO,
               info_log_level_value_mismatch);
COMPILE_ASSERT(logging::LOG_WARNING == MOJO_LOG_LEVEL_WARNING,
               warning_log_level_value_mismatch);
COMPILE_ASSERT(logging::LOG_ERROR == MOJO_LOG_LEVEL_ERROR,
               error_log_level_value_mismatch);
COMPILE_ASSERT(logging::LOG_FATAL == MOJO_LOG_LEVEL_FATAL,
               fatal_log_level_value_mismatch);

int MojoToChromiumLogLevel(MojoLogLevel log_level) {
  // See the compile asserts above.
  return static_cast<int>(log_level);
}

MojoLogLevel ChromiumToMojoLogLevel(int chromium_log_level) {
  // See the compile asserts above.
  return static_cast<MojoLogLevel>(chromium_log_level);
}

void LogMessage(MojoLogLevel log_level,
                const char* source_file,
                uint32_t source_line,
                const char* message) {
  int chromium_log_level = MojoToChromiumLogLevel(log_level);
  int chromium_min_log_level = logging::GetMinLogLevel();
  // "Fatal" errors aren't suppressable.
  DCHECK_LE(chromium_min_log_level, logging::LOG_FATAL);
  if (chromium_log_level < chromium_min_log_level)
    return;

  if (source_file) {
    logging::LogMessage(source_file, static_cast<int>(source_line),
                        chromium_log_level).stream()
        << message;
  } else {
    logging::LogMessage("(no file)", 0, chromium_log_level).stream() << message;
  }
}

MojoLogLevel GetMinimumLogLevel() {
  return ChromiumToMojoLogLevel(logging::GetMinLogLevel());
}

void SetMinimumLogLevel(MojoLogLevel log_level) {
  logging::SetMinLogLevel(MojoToChromiumLogLevel(log_level));
}

const MojoLogger kDefaultLogger = {
  LogMessage,
  GetMinimumLogLevel,
  SetMinimumLogLevel
};

}  // namespace

const MojoLogger* GetDefaultLoggerImpl() {
  return &kDefaultLogger;
}

}  // namespace internal
}  // namespace mojo
