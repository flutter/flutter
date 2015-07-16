// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_LAUNCHD_H_
#define BASE_MAC_LAUNCHD_H_

#include <launch.h>
#include <sys/types.h>

#include <string>

#include "base/base_export.h"

namespace base {
namespace mac {

// MessageForJob sends a single message to launchd with a simple dictionary
// mapping |operation| to |job_label|, and returns the result of calling
// launch_msg to send that message. On failure, returns NULL. The caller
// assumes ownership of the returned launch_data_t object.
BASE_EXPORT
launch_data_t MessageForJob(const std::string& job_label,
                            const char* operation);

// Returns the process ID for |job_label| if the job is running, 0 if the job
// is loaded but not running, or -1 on error.
BASE_EXPORT
pid_t PIDForJob(const std::string& job_label);

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_LAUNCHD_H_
