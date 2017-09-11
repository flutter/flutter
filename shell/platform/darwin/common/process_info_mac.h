// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_PROCESS_INFO_MAC_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_PROCESS_INFO_MAC_H_

#include <mach/mach.h>
#include <mach/task.h>
#include <cstdlib>
#include "flutter/flow/process_info.h"
#include "lib/fxl/macros.h"

namespace shell {

class ProcessInfoMac : public flow::ProcessInfo {
 public:
  ProcessInfoMac();

  ~ProcessInfoMac();

  bool SampleNow() override;

  size_t GetVirtualMemorySize() override;

  size_t GetResidentMemorySize() override;

 private:
  struct mach_task_basic_info last_sample_;

  FXL_DISALLOW_COPY_AND_ASSIGN(ProcessInfoMac);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_PROCESS_INFO_MAC_H_
