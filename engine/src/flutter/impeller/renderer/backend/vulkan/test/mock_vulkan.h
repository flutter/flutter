// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {
namespace testing {

std::shared_ptr<ContextVK> CreateMockVulkanContext(void);

}
}  // namespace impeller
