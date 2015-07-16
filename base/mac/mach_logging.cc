// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/mach_logging.h"

#include <iomanip>
#include <string>

#include "base/strings/stringprintf.h"

#if !defined(OS_IOS)
#include <servers/bootstrap.h>
#endif  // !OS_IOS

namespace {

std::string FormatMachErrorNumber(mach_error_t mach_err) {
  // For the os/kern subsystem, give the error number in decimal as in
  // <mach/kern_return.h>. Otherwise, give it in hexadecimal to make it easier
  // to visualize the various bits. See <mach/error.h>.
  if (mach_err >= 0 && mach_err < KERN_RETURN_MAX) {
    return base::StringPrintf(" (%d)", mach_err);
  }
  return base::StringPrintf(" (0x%08x)", mach_err);
}

}  // namespace

namespace logging {

MachLogMessage::MachLogMessage(const char* file_path,
                               int line,
                               LogSeverity severity,
                               mach_error_t mach_err)
    : LogMessage(file_path, line, severity),
      mach_err_(mach_err) {
}

MachLogMessage::~MachLogMessage() {
  stream() << ": "
           << mach_error_string(mach_err_)
           << FormatMachErrorNumber(mach_err_);
}

#if !defined(OS_IOS)

BootstrapLogMessage::BootstrapLogMessage(const char* file_path,
                                         int line,
                                         LogSeverity severity,
                                         kern_return_t bootstrap_err)
    : LogMessage(file_path, line, severity),
      bootstrap_err_(bootstrap_err) {
}

BootstrapLogMessage::~BootstrapLogMessage() {
  stream() << ": "
           << bootstrap_strerror(bootstrap_err_);

  switch (bootstrap_err_) {
    case BOOTSTRAP_SUCCESS:
    case BOOTSTRAP_NOT_PRIVILEGED:
    case BOOTSTRAP_NAME_IN_USE:
    case BOOTSTRAP_UNKNOWN_SERVICE:
    case BOOTSTRAP_SERVICE_ACTIVE:
    case BOOTSTRAP_BAD_COUNT:
    case BOOTSTRAP_NO_MEMORY:
    case BOOTSTRAP_NO_CHILDREN: {
      // Show known bootstrap errors in decimal because that's how they're
      // defined in <servers/bootstrap.h>.
      stream() << " (" << bootstrap_err_ << ")";
      break;
    }

    default: {
      // bootstrap_strerror passes unknown errors to mach_error_string, so
      // format them as they would be if they were handled by
      // MachErrorMessage.
      stream() << FormatMachErrorNumber(bootstrap_err_);
      break;
    }
  }
}

#endif  // !OS_IOS

}  // namespace logging
