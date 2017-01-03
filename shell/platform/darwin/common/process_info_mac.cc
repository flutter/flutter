// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/process_info_mac.h"

namespace shell {

ProcessInfoMac::ProcessInfoMac() = default;

ProcessInfoMac::~ProcessInfoMac() = default;

bool ProcessInfoMac::SampleNow() {
  mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
  kern_return_t result =
      task_info(mach_task_self(),                              //
                MACH_TASK_BASIC_INFO,                          //
                reinterpret_cast<task_info_t>(&last_sample_),  //
                &size);
  if (result == KERN_SUCCESS) {
    return true;
  }

  last_sample_ = {};
  return false;
}

size_t ProcessInfoMac::GetVirtualMemorySize() {
  return last_sample_.virtual_size;
}

size_t ProcessInfoMac::GetResidentMemorySize() {
  return last_sample_.resident_size;
}

}  // namespace shell
