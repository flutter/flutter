// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_LOG_LEVEL_H_
#define FLUTTER_FML_LOG_LEVEL_H_

namespace fml {

// Default log levels. Negative values can be used for verbose log levels.
typedef int LogSeverity;

constexpr LogSeverity kLogInfo = 0;
constexpr LogSeverity kLogWarning = 1;
constexpr LogSeverity kLogError = 2;
constexpr LogSeverity kLogFatal = 3;
constexpr LogSeverity kLogNumSeverities = 4;

// DEPRECATED: Use |kLogInfo|.
constexpr LogSeverity LOG_INFO = kLogInfo;

// DEPRECATED: Use |kLogWarning|.
constexpr LogSeverity LOG_WARNING = kLogWarning;

// DEPRECATED: Use |kLogError|.
constexpr LogSeverity LOG_ERROR = kLogError;

// DEPRECATED: Use |kLogFatal|.
constexpr LogSeverity LOG_FATAL = kLogFatal;

// DEPRECATED: Use |kLogNumSeverities|.
constexpr LogSeverity LOG_NUM_SEVERITIES = kLogNumSeverities;

// One of the Windows headers defines ERROR to 0. This makes the token
// concatenation in FML_LOG(ERROR) to resolve to LOG_0. We define this back to
// the appropriate log level.
#ifdef _WIN32
#define LOG_0 kLogError
#endif

// kLogDFatal is kLogFatal in debug mode, kLogError in normal mode
#ifdef NDEBUG
const LogSeverity kLogDFatal = kLogError;
#else
const LogSeverity kLogDFatal = kLogFatal;
#endif

// DEPRECATED: Use |kLogDFatal|.
const LogSeverity LOG_DFATAL = kLogDFatal;

}  // namespace fml

#endif  // FLUTTER_FML_LOG_LEVEL_H_
