// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/workarounds_vk.h"
#include "impeller/renderer/backend/vulkan/driver_info_vk.h"

namespace impeller {

WorkaroundsVK GetWorkaroundsFromDriverInfo(DriverInfoVK& driver_info) {
  WorkaroundsVK workarounds;

  const auto& adreno_gpu = driver_info.GetAdrenoGPUInfo();
  const auto& mali_gpu = driver_info.GetMaliGPUInfo();

  workarounds.batch_submit_command_buffer_timeout = true;
  if (adreno_gpu.has_value()) {
    workarounds.slow_primitive_restart_performance = true;
    workarounds.broken_mipmap_generation = true;

    if (adreno_gpu.value() <= AdrenoGPU::kAdreno630) {
      workarounds.input_attachment_self_dependency_broken = true;
    }

    if (adreno_gpu.value() >= AdrenoGPU::kAdreno702) {
      workarounds.batch_submit_command_buffer_timeout = false;
    }
  } else if (mali_gpu.has_value()) {
    workarounds.batch_submit_command_buffer_timeout = false;
  }
  return workarounds;
}

}  // namespace impeller
