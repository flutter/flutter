// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>

#include "flutter/fml/macros.h"

namespace impeller {

class Context;
class RenderPass;
class RenderPassDescriptor;

//------------------------------------------------------------------------------
/// @brief      A collection of encoded commands to be submitted to the GPU for
///             execution. A command buffer is obtained from a graphics
///             `Context`.
///
class CommandBuffer {
 public:
  enum class CommitResult {
    kPending,
    kError,
    kCompleted,
  };

  using CommitCallback = std::function<void(CommitResult)>;

  virtual ~CommandBuffer();

  virtual bool IsValid() const = 0;

  virtual void Commit(CommitCallback callback) = 0;

  virtual std::shared_ptr<RenderPass> CreateRenderPass(
      const RenderPassDescriptor& desc) const = 0;

 protected:
  CommandBuffer();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(CommandBuffer);
};

}  // namespace impeller
