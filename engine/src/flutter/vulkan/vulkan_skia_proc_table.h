// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/vulkan/procs/vulkan_proc_table.h"

#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace vulkan {

GrVkGetProc CreateSkiaGetProc(const fml::RefPtr<vulkan::VulkanProcTable>& vk);

}  // namespace vulkan
