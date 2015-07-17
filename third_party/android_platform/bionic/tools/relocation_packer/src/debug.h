// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Logging and checks.  Avoids a dependency on base.
//
// LOG(tag) prints messages.  Tags are INFO, WARNING, ERROR and FATAL.
// INFO prints to stdout, the others to stderr.  FATAL aborts after printing.
//
// LOG_IF(tag, predicate) logs if predicate evaluates to true, else silent.
//
// VLOG(level) logs INFO messages where level is less than or equal to the
// verbosity level set with SetVerbose().
//
// VLOG_IF(level, predicate) logs INFO if predicate evaluates to true,
// else silent.
//
// CHECK(predicate) logs a FATAL error if predicate is false.
// NOTREACHED() always aborts.
// Log streams can be changed with SetStreams().  Logging is not thread-safe.
//

#ifndef TOOLS_RELOCATION_PACKER_SRC_DEBUG_H_
#define TOOLS_RELOCATION_PACKER_SRC_DEBUG_H_

#include <limits.h>
#include <ostream>
#include <sstream>

namespace relocation_packer {

class Logger {
 public:
  enum Severity {INFO = 0, WARNING, ERROR, FATAL};

  // Construct a new message logger.  Prints if level is less than or
  // equal to the level set with SetVerbose() and predicate is true.
  // |severity| is an enumerated severity.
  // |level| is the verbosity level.
  // |predicate| controls if the logger prints or is silent.
  Logger(Severity severity, int level, bool predicate);

  // On destruction, flush and print the strings accumulated in stream_.
  ~Logger();

  // Return the stream for this logger.
  std::ostream& GetStream() { return stream_; }

  // Set verbosity level.  Messages with a level less than or equal to
  // this level are printed, others are discarded.  Static, not thread-safe.
  static void SetVerbose(int level) { max_level_ = level; }

  // Set info and error logging streams.  Static, not thread-safe.
  static void SetStreams(std::ostream* info_stream,
                         std::ostream* error_stream) {
    info_stream_ = info_stream;
    error_stream_ = error_stream;
  }

  // Reset to initial state.
  static void Reset();

 private:
  // Message severity, verbosity level, and predicate.
  Severity severity_;
  int level_;
  bool predicate_;

  // String stream, accumulates message text.
  std::ostringstream stream_;

  // Verbosity for INFO messages.  Not thread-safe.
  static int max_level_;

  // Logging streams.  Not thread-safe.
  static std::ostream* info_stream_;
  static std::ostream* error_stream_;
};

}  // namespace relocation_packer

// Make logging severities visible globally.
typedef relocation_packer::Logger::Severity LogSeverity;
using LogSeverity::INFO;
using LogSeverity::WARNING;
using LogSeverity::ERROR;
using LogSeverity::FATAL;

// LOG(severity) prints a message with the given severity, and aborts if
// severity is FATAL.  LOG_IF(severity, predicate) does the same but only if
// predicate is true.  INT_MIN is guaranteed to be less than or equal to
// any verbosity level.
#define LOG(severity) \
    (relocation_packer::Logger(severity, INT_MIN, true).GetStream())
#define LOG_IF(severity, predicate) \
    (relocation_packer::Logger(severity, INT_MIN, (predicate)).GetStream())

// VLOG(level) prints its message as INFO if level is less than or equal to
// the current verbosity level.
#define VLOG(level) \
    (relocation_packer::Logger(INFO, (level), true).GetStream())
#define VLOG_IF(level, predicate) \
    (relocation_packer::Logger(INFO, (level), (predicate)).GetStream())

// CHECK(predicate) fails with a FATAL log message if predicate is false.
#define CHECK(predicate) (LOG_IF(FATAL, !(predicate)) \
    << __FILE__ << ":" << __LINE__ << ": " \
    << __FUNCTION__ << ": CHECK '" #predicate "' failed")

// NOTREACHED() always fails with a FATAL log message.
#define NOTREACHED(_) (LOG(FATAL) \
    << __FILE__ << ":" << __LINE__ << ": " \
    << __FUNCTION__ << ": NOTREACHED() hit")

#endif  // TOOLS_RELOCATION_PACKER_SRC_DEBUG_H_
