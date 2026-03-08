// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/workarounds_vk.h"
#include "impeller/renderer/backend/vulkan/driver_info_vk.h"

namespace impeller {

WorkaroundsVK GetWorkaroundsFromDriverInfo(DriverInfoVK& driver_info) {
  WorkaroundsVK workarounds;

  const auto& adreno_gpu = driver_info.GetAdrenoGPUInfo();
  const auto& powervr_gpu = driver_info.GetPowerVRGPUInfo();

  if (adreno_gpu.has_value()) {
    workarounds.slow_primitive_restart_performance = true;
    workarounds.broken_mipmap_generation = true;

    if (adreno_gpu.value() <= AdrenoGPU::kAdreno630) {
      workarounds.input_attachment_self_dependency_broken = true;
      workarounds.batch_submit_command_buffer_timeout = true;
    }
  } else if (powervr_gpu.has_value()) {
    workarounds.input_attachment_self_dependency_broken = true;
  }

  // Mesa's "dozen" (dzn) driver translates Vulkan to D3D12. D3D12 has no
  // native subpass concept, so the subpass self-dependency used for
  // programmable blending (framebuffer fetch) fails at vkEndCommandBuffer
  // with ErrorOutOfHostMemory. Disable framebuffer fetch on this driver.
  //
  // Detection strategy:
  //  1. Prefer VkPhysicalDeviceDriverProperties::driverID (Vulkan 1.2+)
  //     which reliably identifies the driver via an enum.
  //  2. Fall back to device name string matching for pre-1.2 drivers.
  //     The device name is "Microsoft Direct3D12 (<GPU name>)".
  //     Note: dzn reports the underlying GPU's vendorID (e.g. 0x1002 for
  //     AMD), not VK_VENDOR_ID_MESA, so vendorID alone is insufficient.
  bool is_mesa_dzn =
      driver_info.GetDriverID() == vk::DriverId::eMesaDozen ||
      driver_info.GetDriverName().find("D3D12") != std::string::npos;
  if (is_mesa_dzn) {
    workarounds.input_attachment_self_dependency_broken = true;
    workarounds.skip_sub_region_buffer_to_image_copy = true;
  }

  return workarounds;
}

}  // namespace impeller
