// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_LOG_LEVEL_H_
#define FLUTTER_FML_LOG_LEVEL_H_

namespace fml {

typedef int LogSeverity;

// Default log levels. Negative values can be used for verbose log levels.
constexpr LogSeverity LOG_INFO = 0;
constexpr LogSeverity LOG_WARNING = 1;
constexpr LogSeverity LOG_ERROR = 2;
constexpr LogSeverity LOG_FATAL = 3;
constexpr LogSeverity LOG_NUM_SEVERITIES = 4;

// LOG_DFATAL is LOG_FATAL in debug mode, ERROR in normal mode
#ifdef NDEBUG
const LogSeverity LOG_DFATAL = LOG_ERROR;
#else
const LogSeverity LOG_DFATAL = LOG_FATAL;
#endif

}  // namespace fml

#endif  // FLUTTER_FML_LOG_LEVEL_H_
