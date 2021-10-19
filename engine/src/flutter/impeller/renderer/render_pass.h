// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include <map>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/render_pass_descriptor.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class CommandBuffer;

class RenderPass {
 public:
  ~RenderPass();

  bool IsValid() const;

  void SetLabel(std::string label);

  HostBuffer& GetTransientsBuffer();

  [[nodiscard]] bool RecordCommand(Command command);

  //----------------------------------------------------------------------------
  /// @brief      Commit the recorded commands to the underlying command buffer.
  ///             Any completion handlers must on the underlying command buffer
  ///             must have already been added by this point.
  ///
  /// @param      transients_allocator  The transients allocator.
  ///
  /// @return     If the commands were committed to the underlying command
  ///             buffer.
  ///
  [[nodiscard]] bool Commit(Allocator& transients_allocator) const;

 private:
  friend class CommandBuffer;

  id<MTLCommandBuffer> buffer_ = nil;
  MTLRenderPassDescriptor* desc_ = nil;
  std::vector<Command> commands_;
  std::shared_ptr<HostBuffer> transients_buffer_;
  std::string label_;
  bool is_valid_ = false;

  RenderPass(id<MTLCommandBuffer> buffer, const RenderPassDescriptor& desc);

  bool EncodeCommands(Allocator& transients_allocator,
                      id<MTLRenderCommandEncoder> pass) const;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
