// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

class Context;

class CommandBuffer {
 public:
  ~CommandBuffer();

  bool IsValid() const;

  enum class CommitResult {
    kPending,
    kError,
    kCompleted,
  };

  using CommitCallback = std::function<void(CommitResult)>;
  void Commit(CommitCallback callback);

  std::shared_ptr<RenderPass> CreateRenderPass(
      const RenderPassDescriptor& desc) const;

 private:
  friend class Context;

  id<MTLCommandBuffer> buffer_ = nullptr;
  bool is_valid_ = false;

  CommandBuffer(id<MTLCommandQueue> queue);

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBuffer);
};

}  // namespace impeller
