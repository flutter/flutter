// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/launchd.h"

#include "base/logging.h"
#include "base/mac/scoped_launch_data.h"

namespace base {
namespace mac {

// MessageForJob sends a single message to launchd with a simple dictionary
// mapping |operation| to |job_label|, and returns the result of calling
// launch_msg to send that message. On failure, returns NULL. The caller
// assumes ownership of the returned launch_data_t object.
launch_data_t MessageForJob(const std::string& job_label,
                            const char* operation) {
  // launch_data_alloc returns something that needs to be freed.
  ScopedLaunchData message(launch_data_alloc(LAUNCH_DATA_DICTIONARY));
  if (!message) {
    LOG(ERROR) << "launch_data_alloc";
    return NULL;
  }

  // launch_data_new_string returns something that needs to be freed, but
  // the dictionary will assume ownership when launch_data_dict_insert is
  // called, so put it in a scoper and .release() it when given to the
  // dictionary.
  ScopedLaunchData job_label_launchd(launch_data_new_string(job_label.c_str()));
  if (!job_label_launchd) {
    LOG(ERROR) << "launch_data_new_string";
    return NULL;
  }

  if (!launch_data_dict_insert(message,
                               job_label_launchd.release(),
                               operation)) {
    return NULL;
  }

  return launch_msg(message);
}

pid_t PIDForJob(const std::string& job_label) {
  ScopedLaunchData response(MessageForJob(job_label, LAUNCH_KEY_GETJOB));
  if (!response) {
    return -1;
  }

  launch_data_type_t response_type = launch_data_get_type(response);
  if (response_type != LAUNCH_DATA_DICTIONARY) {
    if (response_type == LAUNCH_DATA_ERRNO) {
      LOG(ERROR) << "PIDForJob: error " << launch_data_get_errno(response);
    } else {
      LOG(ERROR) << "PIDForJob: expected dictionary, got " << response_type;
    }
    return -1;
  }

  launch_data_t pid_data = launch_data_dict_lookup(response,
                                                   LAUNCH_JOBKEY_PID);
  if (!pid_data)
    return 0;

  if (launch_data_get_type(pid_data) != LAUNCH_DATA_INTEGER) {
    LOG(ERROR) << "PIDForJob: expected integer";
    return -1;
  }

  return launch_data_get_integer(pid_data);
}

}  // namespace mac
}  // namespace base
