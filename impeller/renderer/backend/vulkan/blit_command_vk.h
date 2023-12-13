// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BLIT_COMMAND_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BLIT_COMMAND_VK_H_

#include <memory>
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/blit_command.h"
#include "impeller/renderer/context.h"

namespace impeller {

class CommandEncoderVK;

// TODO(csg): Should these be backend castable to blit command?
/// Mixin for dispatching Vulkan commands.
struct BlitEncodeVK : BackendCast<BlitEncodeVK, BlitCommand> {
  virtual ~BlitEncodeVK();

  virtual std::string GetLabel() const = 0;

  [[nodiscard]] virtual bool Encode(CommandEncoderVK& encoder) const = 0;
};

struct BlitCopyTextureToTextureCommandVK
    : public BlitCopyTextureToTextureCommand,
      public BlitEncodeVK {
  ~BlitCopyTextureToTextureCommandVK() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(CommandEncoderVK& encoder) const override;
};

struct BlitCopyTextureToBufferCommandVK : public BlitCopyTextureToBufferCommand,
                                          public BlitEncodeVK {
  ~BlitCopyTextureToBufferCommandVK() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(CommandEncoderVK& encoder) const override;
};

struct BlitCopyBufferToTextureCommandVK : public BlitCopyBufferToTextureCommand,
                                          public BlitEncodeVK {
  ~BlitCopyBufferToTextureCommandVK() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(CommandEncoderVK& encoder) const override;
};

struct BlitGenerateMipmapCommandVK : public BlitGenerateMipmapCommand,
                                     public BlitEncodeVK {
  ~BlitGenerateMipmapCommandVK() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(CommandEncoderVK& encoder) const override;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_BLIT_COMMAND_VK_H_
