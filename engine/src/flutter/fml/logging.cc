// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <cstring>
#include <iostream>

#include "flutter/fml/build_config.h"
#include "flutter/fml/log_level.h"
#include "flutter/fml/log_settings.h"
#include "flutter/fml/logging.h"

#if defined(FML_OS_ANDROID)
#include <android/log.h>
#elif defined(FML_OS_IOS)
#include <syslog.h>
#elif defined(OS_FUCHSIA)
#include <lib/syslog/global.h>
#endif

namespace fml {

namespace {

#if !defined(OS_FUCHSIA)
const char* const kLogSeverityNames[kLogNumSeverities] = {"INFO", "WARNING",
                                                          "ERROR", "FATAL"};

const char* GetNameForLogSeverity(LogSeverity severity) {
  if (severity >= kLogInfo && severity < kLogNumSeverities) {
    return kLogSeverityNames[severity];
  }
  return "UNKNOWN";
}

const char* StripDots(const char* path) {
  while (strncmp(path, "../", 3) == 0) {
    path += 3;
  }
  return path;
}

const char* StripPath(const char* path) {
  auto* p = strrchr(path, '/');
  if (p) {
    return p + 1;
  }
  return path;
}
#endif

}  // namespace

LogMessage::LogMessage(LogSeverity severity,
                       const char* file,
                       int line,
                       const char* condition)
    : severity_(severity), file_(file), line_(line) {
#if !defined(OS_FUCHSIA)
  stream_ << "[";
  if (severity >= kLogInfo) {
    stream_ << GetNameForLogSeverity(severity);
  } else {
    stream_ << "VERBOSE" << -severity;
  }
  stream_ << ":" << (severity > kLogInfo ? StripDots(file_) : StripPath(file_))
          << "(" << line_ << ")] ";
#endif

  if (condition) {
    stream_ << "Check failed: " << condition << ". ";
  }
}

// static
thread_local std::ostringstream* LogMessage::capture_next_log_stream_ = nullptr;

namespace testing {

LogCapture::LogCapture() {
  fml::LogMessage::CaptureNextLog(&stream_);
}

LogCapture::~LogCapture() {
  fml::LogMessage::CaptureNextLog(nullptr);
}

std::string LogCapture::str() const {
  return stream_.str();
}

}  // namespace testing

// static
void LogMessage::CaptureNextLog(std::ostringstream* stream) {
  LogMessage::capture_next_log_stream_ = stream;
}

LogMessage::~LogMessage() {
#if !defined(OS_FUCHSIA)
  stream_ << std::endl;
#endif

  if (capture_next_log_stream_) {
    *capture_next_log_stream_ << stream_.str();
    capture_next_log_stream_ = nullptr;
  } else {
#if defined(FML_OS_ANDROID)
    android_LogPriority priority =
        (severity_ < 0) ? ANDROID_LOG_VERBOSE : ANDROID_LOG_UNKNOWN;
    switch (severity_) {
      case kLogInfo:
        priority = ANDROID_LOG_INFO;
        break;
      case kLogWarning:
        priority = ANDROID_LOG_WARN;
        break;
      case kLogError:
        priority = ANDROID_LOG_ERROR;
        break;
      case kLogFatal:
        priority = ANDROID_LOG_FATAL;
        break;
    }
    __android_log_write(priority, "flutter", stream_.str().c_str());
#elif defined(FML_OS_IOS)
    syslog(LOG_ALERT, "%s", stream_.str().c_str());
#elif defined(OS_FUCHSIA)
    fx_log_severity_t fx_severity;
    switch (severity_) {
      case kLogInfo:
        fx_severity = FX_LOG_INFO;
        break;
      case kLogWarning:
        fx_severity = FX_LOG_WARNING;
        break;
      case kLogError:
        fx_severity = FX_LOG_ERROR;
        break;
      case kLogFatal:
        fx_severity = FX_LOG_FATAL;
        break;
      default:
        if (severity_ < 0) {
          fx_severity = fx_log_severity_from_verbosity(-severity_);
        } else {
          // Unknown severity. Use INFO.
          fx_severity = FX_LOG_INFO;
        }
    }
    fx_logger_log_with_source(fx_log_get_logger(), fx_severity, nullptr, file_,
                              line_, stream_.str().c_str());
#else
    // Don't use std::cerr here, because it may not be initialized properly yet.
    fprintf(stderr, "%s", stream_.str().c_str());
    fflush(stderr);
#endif
  }

  if (severity_ >= kLogFatal) {
    KillProcess();
  }
}

int GetVlogVerbosity() {
  return std::max(-1, kLogInfo - GetMinLogLevel());
}

bool ShouldCreateLogMessage(LogSeverity severity) {
  return severity >= GetMinLogLevel();
}

void KillProcess() {
  abort();
}

}  // namespace fml
