// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_LAUNCH_SERVICES_UTIL_H_
#define BASE_MAC_LAUNCH_SERVICES_UTIL_H_

#include <CoreServices/CoreServices.h>

#include "base/base_export.h"
#include "base/command_line.h"
#include "base/files/file_path.h"

struct ProcessSerialNumber;

namespace base {
namespace mac {

// Launches the application bundle at |bundle_path|, passing argv[1..] from
// |command_line| as command line arguments if the app isn't already running.
// |launch_flags| are passed directly to LSApplicationParameters.
// |out_psn|, if not NULL, will be set to the process serial number of the
// application's main process if the app was successfully launched.
// Returns true if the app was successfully launched.
BASE_EXPORT bool OpenApplicationWithPath(const FilePath& bundle_path,
                                         const CommandLine& command_line,
                                         LSLaunchFlags launch_flags,
                                         ProcessSerialNumber* out_psn);

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_LAUNCH_SERVICES_UTIL_H_
