// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "impeller/renderer/command.h"
#include "impeller/renderer/render_target.h"

namespace impeller {

class HostBuffer;
class Allocator;

//------------------------------------------------------------------------------
/// @brief      Render passes encode render commands directed as one specific
///             render target into an underlying command buffer.
///
///             Render passes can be obtained from the command buffer in which
///             the pass is meant to encode commands into.
///
/// @see        `CommandBuffer`
///
class RenderPass {
 public:
  virtual ~RenderPass();

  const RenderTarget& GetRenderTarget() const;

  ISize GetRenderTargetSize() const;

  virtual bool IsValid() const = 0;

  virtual void SetLabel(std::string label) = 0;

  virtual HostBuffer& GetTransientsBuffer() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Record a command for subsequent encoding to the underlying
  ///             command buffer. No work is encoded into the command buffer at
  ///             this time.
  ///
  /// @param[in]  command  The command
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  virtual bool AddCommand(Command command) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Encode the recorded commands to the underlying command buffer.
  ///
  /// @param      transients_allocator  The transients allocator.
  ///
  /// @return     If the commands were encoded to the underlying command
  ///             buffer.
  ///
  virtual bool EncodeCommands(Allocator& transients_allocator) const = 0;

 protected:
  RenderPass(RenderTarget target);

 private:
  const RenderTarget render_target_;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
