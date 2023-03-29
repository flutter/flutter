// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>
#include <variant>

#include "impeller/core/device_buffer.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/compute_command.h"

namespace impeller {

class HostBuffer;
class Allocator;

//------------------------------------------------------------------------------
/// @brief      Compute passes encode compute shader into the underlying command
///             buffer.
///
/// @see        `CommandBuffer`
///
class ComputePass {
 public:
  virtual ~ComputePass();

  virtual bool IsValid() const = 0;

  void SetLabel(std::string label);

  void SetGridSize(const ISize& size);

  void SetThreadGroupSize(const ISize& size);

  HostBuffer& GetTransientsBuffer();

  //----------------------------------------------------------------------------
  /// @brief      Record a command for subsequent encoding to the underlying
  ///             command buffer. No work is encoded into the command buffer at
  ///             this time.
  ///
  /// @param[in]  command  The command
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  bool AddCommand(ComputeCommand command);

  //----------------------------------------------------------------------------
  /// @brief      Encode the recorded commands to the underlying command buffer.
  ///
  /// @param      transients_allocator  The transients allocator.
  ///
  /// @return     If the commands were encoded to the underlying command
  ///             buffer.
  ///
  bool EncodeCommands() const;

 protected:
  const std::weak_ptr<const Context> context_;
  ISize grid_size_ = ISize(32, 32);
  ISize thread_group_size_ = ISize(32, 32);
  std::shared_ptr<HostBuffer> transients_buffer_;
  std::vector<ComputeCommand> commands_;

  explicit ComputePass(std::weak_ptr<const Context> context);

  virtual void OnSetLabel(std::string label) = 0;

  virtual bool OnEncodeCommands(const Context& context,
                                const ISize& grid_size,
                                const ISize& thread_group_size) const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(ComputePass);
};

}  // namespace impeller
