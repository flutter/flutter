// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "debug.h"

#include <stdlib.h>
#include <iostream>
#include <string>

namespace relocation_packer {

// Construct a new message logger.  Prints if level is less than or equal to
// the level set with SetVerbose() and predicate is true.
Logger::Logger(Severity severity, int level, bool predicate) {
  severity_ = severity;
  level_ = level;
  predicate_ = predicate;
}

// On destruction, flush and print the strings accumulated.  Abort if FATAL.
Logger::~Logger() {
  if (predicate_) {
    if (level_ <= max_level_) {
      std::ostream* log = severity_ == INFO ? info_stream_ : error_stream_;
      std::string tag;
      switch (severity_) {
        case INFO: tag = "INFO"; break;
        case WARNING: tag = "WARNING"; break;
        case ERROR: tag = "ERROR"; break;
        case FATAL: tag = "FATAL"; break;
      }
      stream_.flush();
      *log << tag << ": " << stream_.str() << std::endl;
    }
    if (severity_ == FATAL)
      abort();
  }
}

// Reset to initial state.
void Logger::Reset() {
  max_level_ = -1;
  info_stream_ = &std::cout;
  error_stream_ = &std::cerr;
}

// Verbosity.  Not thread-safe.
int Logger::max_level_ = -1;

// Logging streams.  Not thread-safe.
std::ostream* Logger::info_stream_ = &std::cout;
std::ostream* Logger::error_stream_ = &std::cerr;

}  // namespace relocation_packer
