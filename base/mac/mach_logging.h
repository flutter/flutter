// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_MACH_LOGGING_H_
#define BASE_MAC_MACH_LOGGING_H_

#include <mach/mach.h>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/logging.h"
#include "build/build_config.h"

// Use the MACH_LOG family of macros along with a mach_error_t (kern_return_t)
// containing a Mach error. The error value will be decoded so that logged
// messages explain the error.
//
// Use the BOOTSTRAP_LOG family of macros specifically for errors that occur
// while interoperating with the bootstrap subsystem. These errors will first
// be looked up as bootstrap error messages. If no match is found, they will
// be treated as generic Mach errors, as in MACH_LOG.
//
// Examples:
//
//   kern_return_t kr = mach_timebase_info(&info);
//   if (kr != KERN_SUCCESS) {
//     MACH_LOG(ERROR, kr) << "mach_timebase_info";
//   }
//
//   kr = vm_deallocate(task, address, size);
//   MACH_DCHECK(kr == KERN_SUCCESS, kr) << "vm_deallocate";

namespace logging {

class BASE_EXPORT MachLogMessage : public logging::LogMessage {
 public:
  MachLogMessage(const char* file_path,
                 int line,
                 LogSeverity severity,
                 mach_error_t mach_err);
  ~MachLogMessage();

 private:
  mach_error_t mach_err_;

  DISALLOW_COPY_AND_ASSIGN(MachLogMessage);
};

}  // namespace logging

#if defined(NDEBUG)
#define MACH_DVLOG_IS_ON(verbose_level) 0
#else
#define MACH_DVLOG_IS_ON(verbose_level) VLOG_IS_ON(verbose_level)
#endif

#define MACH_LOG_STREAM(severity, mach_err) \
    COMPACT_GOOGLE_LOG_EX_ ## severity(MachLogMessage, mach_err).stream()
#define MACH_VLOG_STREAM(verbose_level, mach_err) \
    logging::MachLogMessage(__FILE__, __LINE__, \
                            -verbose_level, mach_err).stream()

#define MACH_LOG(severity, mach_err) \
    LAZY_STREAM(MACH_LOG_STREAM(severity, mach_err), LOG_IS_ON(severity))
#define MACH_LOG_IF(severity, condition, mach_err) \
    LAZY_STREAM(MACH_LOG_STREAM(severity, mach_err), \
                LOG_IS_ON(severity) && (condition))

#define MACH_VLOG(verbose_level, mach_err) \
    LAZY_STREAM(MACH_VLOG_STREAM(verbose_level, mach_err), \
                VLOG_IS_ON(verbose_level))
#define MACH_VLOG_IF(verbose_level, condition, mach_err) \
    LAZY_STREAM(MACH_VLOG_STREAM(verbose_level, mach_err), \
                VLOG_IS_ON(verbose_level) && (condition))

#define MACH_CHECK(condition, mach_err) \
    LAZY_STREAM(MACH_LOG_STREAM(FATAL, mach_err), !(condition)) \
    << "Check failed: " # condition << ". "

#define MACH_DLOG(severity, mach_err) \
    LAZY_STREAM(MACH_LOG_STREAM(severity, mach_err), DLOG_IS_ON(severity))
#define MACH_DLOG_IF(severity, condition, mach_err) \
    LAZY_STREAM(MACH_LOG_STREAM(severity, mach_err), \
                DLOG_IS_ON(severity) && (condition))

#define MACH_DVLOG(verbose_level, mach_err) \
    LAZY_STREAM(MACH_VLOG_STREAM(verbose_level, mach_err), \
                MACH_DVLOG_IS_ON(verbose_level))
#define MACH_DVLOG_IF(verbose_level, condition, mach_err) \
    LAZY_STREAM(MACH_VLOG_STREAM(verbose_level, mach_err), \
                MACH_DVLOG_IS_ON(verbose_level) && (condition))

#define MACH_DCHECK(condition, mach_err)        \
  LAZY_STREAM(MACH_LOG_STREAM(FATAL, mach_err), \
              DCHECK_IS_ON() && !(condition))   \
      << "Check failed: " #condition << ". "

#if !defined(OS_IOS)

namespace logging {

class BASE_EXPORT BootstrapLogMessage : public logging::LogMessage {
 public:
  BootstrapLogMessage(const char* file_path,
                      int line,
                      LogSeverity severity,
                      kern_return_t bootstrap_err);
  ~BootstrapLogMessage();

 private:
  kern_return_t bootstrap_err_;

  DISALLOW_COPY_AND_ASSIGN(BootstrapLogMessage);
};

}  // namespace logging

#define BOOTSTRAP_DVLOG_IS_ON MACH_DVLOG_IS_ON

#define BOOTSTRAP_LOG_STREAM(severity, bootstrap_err) \
    COMPACT_GOOGLE_LOG_EX_ ## severity(BootstrapLogMessage, \
                                       bootstrap_err).stream()
#define BOOTSTRAP_VLOG_STREAM(verbose_level, bootstrap_err) \
    logging::BootstrapLogMessage(__FILE__, __LINE__, \
                                 -verbose_level, bootstrap_err).stream()

#define BOOTSTRAP_LOG(severity, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_LOG_STREAM(severity, \
                                     bootstrap_err), LOG_IS_ON(severity))
#define BOOTSTRAP_LOG_IF(severity, condition, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_LOG_STREAM(severity, bootstrap_err), \
                LOG_IS_ON(severity) && (condition))

#define BOOTSTRAP_VLOG(verbose_level, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_VLOG_STREAM(verbose_level, bootstrap_err), \
                VLOG_IS_ON(verbose_level))
#define BOOTSTRAP_VLOG_IF(verbose_level, condition, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_VLOG_STREAM(verbose_level, bootstrap_err), \
                VLOG_IS_ON(verbose_level) && (condition))

#define BOOTSTRAP_CHECK(condition, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_LOG_STREAM(FATAL, bootstrap_err), !(condition)) \
    << "Check failed: " # condition << ". "

#define BOOTSTRAP_DLOG(severity, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_LOG_STREAM(severity, bootstrap_err), \
                DLOG_IS_ON(severity))
#define BOOTSTRAP_DLOG_IF(severity, condition, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_LOG_STREAM(severity, bootstrap_err), \
                DLOG_IS_ON(severity) && (condition))

#define BOOTSTRAP_DVLOG(verbose_level, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_VLOG_STREAM(verbose_level, bootstrap_err), \
                BOOTSTRAP_DVLOG_IS_ON(verbose_level))
#define BOOTSTRAP_DVLOG_IF(verbose_level, condition, bootstrap_err) \
    LAZY_STREAM(BOOTSTRAP_VLOG_STREAM(verbose_level, bootstrap_err), \
                BOOTSTRAP_DVLOG_IS_ON(verbose_level) && (condition))

#define BOOTSTRAP_DCHECK(condition, bootstrap_err)        \
  LAZY_STREAM(BOOTSTRAP_LOG_STREAM(FATAL, bootstrap_err), \
              DCHECK_IS_ON() && !(condition))             \
      << "Check failed: " #condition << ". "

#endif  // !OS_IOS

#endif  // BASE_MAC_MACH_LOGGING_H_
