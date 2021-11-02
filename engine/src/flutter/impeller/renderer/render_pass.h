// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

#include "impeller/renderer/command.h"

namespace impeller {

class HostBuffer;
class Allocator;

class RenderPass {
 public:
  virtual ~RenderPass();

  virtual bool IsValid() const = 0;

  virtual void SetLabel(std::string label) = 0;

  virtual HostBuffer& GetTransientsBuffer() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Record a command for subsequent commit to the underlying
  ///             command buffer. No work is encoded into the command buffer at
  ///             this time.
  ///
  /// @param[in]  command  The command
  ///
  /// @return     If the command was valid for subsequent commitment.
  ///
  [[nodiscard]] virtual bool RecordCommand(Command command) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Commit the recorded commands to the underlying command buffer.
  ///
  /// @param      transients_allocator  The transients allocator.
  ///
  /// @return     If the commands were committed to the underlying command
  ///             buffer.
  ///
  [[nodiscard]] virtual bool Commit(Allocator& transients_allocator) const = 0;

 protected:
  RenderPass();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(RenderPass);
};

}  // namespace impeller
