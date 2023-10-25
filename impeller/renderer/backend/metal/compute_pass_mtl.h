// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/compute_pass.h"

namespace impeller {

class ComputePassMTL final : public ComputePass {
 public:
  // |RenderPass|
  ~ComputePassMTL() override;

 private:
  friend class CommandBufferMTL;

  id<MTLCommandBuffer> buffer_ = nil;
  std::string label_;
  bool is_valid_ = false;

  ComputePassMTL(std::weak_ptr<const Context> context,
                 id<MTLCommandBuffer> buffer);

  // |ComputePass|
  bool IsValid() const override;

  // |ComputePass|
  void OnSetLabel(const std::string& label) override;

  // |ComputePass|
  bool OnEncodeCommands(const Context& context,
                        const ISize& grid_size,
                        const ISize& thread_group_size) const override;

  bool EncodeCommands(const std::shared_ptr<Allocator>& allocator,
                      id<MTLComputeCommandEncoder> pass,
                      const ISize& grid_size,
                      const ISize& thread_group_size) const;

  ComputePassMTL(const ComputePassMTL&) = delete;

  ComputePassMTL& operator=(const ComputePassMTL&) = delete;
};

}  // namespace impeller
