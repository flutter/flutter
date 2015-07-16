// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logging macros, similar to Chromium's base/logging.h, except with |MOJO_|
// prefixes and missing some features (notably |CHECK_EQ()|, etc.).

// TODO(vtl): It's weird that this is in the environment directory, since its
// implementation (in environment/lib) is meant to be used by any implementation
// of the environment.

#ifndef MOJO_PUBLIC_CPP_ENVIRONMENT_LOGGING_H_
#define MOJO_PUBLIC_CPP_ENVIRONMENT_LOGGING_H_

#include <sstream>

#include "mojo/public/c/environment/logger.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/macros.h"

#define MOJO_LOG_STREAM(level)                                             \
  ::mojo::internal::LogMessage(MOJO_LOG_LEVEL_##level, __FILE__, __LINE__) \
      .stream()

#define MOJO_LAZY_LOG_STREAM(level, condition) \
  !(condition) ? (void)0                       \
               : ::mojo::internal::VoidifyOstream() & MOJO_LOG_STREAM(level)

#define MOJO_SHOULD_LOG(level) \
  (MOJO_LOG_LEVEL_##level >=   \
   ::mojo::Environment::GetDefaultLogger()->GetMinimumLogLevel())

#define MOJO_LOG(level) MOJO_LAZY_LOG_STREAM(level, MOJO_SHOULD_LOG(level))

#define MOJO_LOG_IF(level, condition) \
  MOJO_LAZY_LOG_STREAM(level, MOJO_SHOULD_LOG(level) && (condition))

#define MOJO_CHECK(condition)                                                  \
  MOJO_LAZY_LOG_STREAM(FATAL, !(condition)) << "Check failed: " #condition "." \
                                                                           " "

// Note: For non-debug builds, |MOJO_DLOG_IF()| *eliminates* (i.e., doesn't
// compile) the condition, whereas |MOJO_DCHECK()| "neuters" the condition
// (i.e., compiles, but doesn't evaluate).
#ifdef NDEBUG
#define MOJO_DLOG(level) MOJO_LAZY_LOG_STREAM(level, false)
#define MOJO_DLOG_IF(level, condition) MOJO_LAZY_LOG_STREAM(level, false)
#else
#define MOJO_DLOG(level) MOJO_LOG(level)
#define MOJO_DLOG_IF(level, condition) MOJO_LOG_IF(level, condition)
#endif  // NDEBUG

#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
#define MOJO_DCHECK(condition) \
  MOJO_LAZY_LOG_STREAM(FATAL, false ? !(condition) : false)
#else
#define MOJO_DCHECK(condition) MOJO_CHECK(condition)
#endif  // NDEBUG && !defined(DCHECK_ALWAYS_ON)

#define MOJO_NOTREACHED() MOJO_DCHECK(false)

namespace mojo {
namespace internal {

class LogMessage {
 public:
  LogMessage(MojoLogLevel log_level, const char* file, int line);
  ~LogMessage();

  std::ostream& stream() { return stream_; }

 private:
  const MojoLogLevel log_level_;
  const char* const file_;
  const int line_;
  std::ostringstream stream_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LogMessage);
};

// Used to ignore a stream.
struct VoidifyOstream {
  // Use & since it has precedence lower than << but higher than ?:.
  void operator&(std::ostream&) {}
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_ENVIRONMENT_LOGGING_H_
