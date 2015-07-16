// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_CONFIG_GPU_DRIVER_BUG_LIST_H_
#define GPU_CONFIG_GPU_DRIVER_BUG_LIST_H_

#include <set>
#include <string>

#include "base/command_line.h"
#include "gpu/config/gpu_control_list.h"
#include "gpu/config/gpu_driver_bug_workaround_type.h"
#include "gpu/gpu_export.h"

namespace gpu {

class GPU_EXPORT GpuDriverBugList : public GpuControlList {
 public:
  ~GpuDriverBugList() override;

  static GpuDriverBugList* Create();

  // Append |workarounds| with these passed in through the
  // |command_line|.
  static void AppendWorkaroundsFromCommandLine(
      std::set<int>* workarounds,
      const base::CommandLine& command_line);

 private:
  GpuDriverBugList();

  DISALLOW_COPY_AND_ASSIGN(GpuDriverBugList);
};

}  // namespace gpu

#endif  // GPU_CONFIG_GPU_DRIVER_BUG_LIST_H_

