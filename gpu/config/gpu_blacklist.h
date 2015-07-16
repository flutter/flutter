// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_CONFIG_GPU_BLACKLIST_H_
#define GPU_CONFIG_GPU_BLACKLIST_H_

#include <string>

#include "gpu/config/gpu_control_list.h"

namespace gpu {

class GPU_EXPORT GpuBlacklist : public GpuControlList {
 public:
  ~GpuBlacklist() override;

  static GpuBlacklist* Create();

 private:
  GpuBlacklist();

  DISALLOW_COPY_AND_ASSIGN(GpuBlacklist);
};

}  // namespace gpu

#endif  // GPU_CONFIG_GPU_BLACKLIST_H_
