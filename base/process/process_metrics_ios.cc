// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_metrics.h"

#include <mach/task.h>

#include "base/logging.h"

namespace base {

namespace {

bool GetTaskInfo(task_basic_info_64* task_info_data) {
  mach_msg_type_number_t count = TASK_BASIC_INFO_64_COUNT;
  kern_return_t kr = task_info(mach_task_self(),
                               TASK_BASIC_INFO_64,
                               reinterpret_cast<task_info_t>(task_info_data),
                               &count);
  return kr == KERN_SUCCESS;
}

}  // namespace

ProcessMetrics::ProcessMetrics(ProcessHandle process) {}

ProcessMetrics::~ProcessMetrics() {}

// static
ProcessMetrics* ProcessMetrics::CreateProcessMetrics(ProcessHandle process) {
  return new ProcessMetrics(process);
}

double ProcessMetrics::GetCPUUsage() {
  NOTIMPLEMENTED();
  return 0;
}

size_t ProcessMetrics::GetPagefileUsage() const {
  task_basic_info_64 task_info_data;
  if (!GetTaskInfo(&task_info_data))
    return 0;
  return task_info_data.virtual_size;
}

size_t ProcessMetrics::GetWorkingSetSize() const {
  task_basic_info_64 task_info_data;
  if (!GetTaskInfo(&task_info_data))
    return 0;
  return task_info_data.resident_size;
}

size_t GetMaxFds() {
  static const rlim_t kSystemDefaultMaxFds = 256;
  rlim_t max_fds;
  struct rlimit nofile;
  if (getrlimit(RLIMIT_NOFILE, &nofile)) {
    // Error case: Take a best guess.
    max_fds = kSystemDefaultMaxFds;
  } else {
    max_fds = nofile.rlim_cur;
  }

  if (max_fds > INT_MAX)
    max_fds = INT_MAX;

  return static_cast<size_t>(max_fds);
}

void SetFdLimit(unsigned int max_descriptors) {
  // Unimplemented.
}

size_t GetPageSize() {
  return getpagesize();
}

// Bytes committed by the system.
size_t GetSystemCommitCharge() {
  NOTIMPLEMENTED();
  return 0;
}

}  // namespace base
