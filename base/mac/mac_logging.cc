// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/mac_logging.h"

#include <iomanip>

#if !defined(OS_IOS)
#include <CoreServices/CoreServices.h>
#endif

namespace logging {

OSStatusLogMessage::OSStatusLogMessage(const char* file_path,
                                       int line,
                                       LogSeverity severity,
                                       OSStatus status)
    : LogMessage(file_path, line, severity),
      status_(status) {
}

OSStatusLogMessage::~OSStatusLogMessage() {
#if defined(OS_IOS)
  // TODO(ios): Consider using NSError with NSOSStatusErrorDomain to try to
  // get a description of the failure.
  stream() << ": " << status_;
#else
  stream() << ": "
           << GetMacOSStatusErrorString(status_)
           << " ("
           << status_
           << ")";
#endif
}

}  // namespace logging
