// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

enum class DescriptorType {
  kSampledImage,
  kUniformBuffer,
};

struct DescriptorSetLayout {
  uint32_t binding;
  DescriptorType descriptor_type;
  uint32_t descriptor_count;
  ShaderStage shader_stage;
};

}  // namespace impeller
