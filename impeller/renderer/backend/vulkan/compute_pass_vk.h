// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/compute_pass.h"

namespace impeller {

class CommandBufferVK;

class ComputePassVK final : public ComputePass {
 public:
  // |ComputePass|
  ~ComputePassVK() override;

 private:
  friend class CommandBufferVK;

  std::weak_ptr<CommandBufferVK> command_buffer_;
  std::string label_;
  bool is_valid_ = false;

  ComputePassVK(std::weak_ptr<const Context> context,
                std::weak_ptr<CommandBufferVK> command_buffer);

  // |ComputePass|
  bool IsValid() const override;

  // |ComputePass|
  void OnSetLabel(const std::string& label) override;

  // |ComputePass|
  bool OnEncodeCommands(const Context& context,
                        const ISize& grid_size,
                        const ISize& thread_group_size) const override;
};

}  // namespace impeller