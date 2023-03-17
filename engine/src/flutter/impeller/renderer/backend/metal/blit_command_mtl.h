// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "impeller/base/backend_cast.h"
#include "impeller/renderer/blit_command.h"

namespace impeller {

/// Mixin for dispatching Metal commands.
struct BlitEncodeMTL : BackendCast<BlitEncodeMTL, BlitCommand> {
  virtual ~BlitEncodeMTL();

  virtual std::string GetLabel() const = 0;

  [[nodiscard]] virtual bool Encode(
      id<MTLBlitCommandEncoder> encoder) const = 0;
};

struct BlitCopyTextureToTextureCommandMTL
    : public BlitCopyTextureToTextureCommand,
      public BlitEncodeMTL {
  ~BlitCopyTextureToTextureCommandMTL() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(id<MTLBlitCommandEncoder> encoder) const override;
};

struct BlitCopyTextureToBufferCommandMTL
    : public BlitCopyTextureToBufferCommand,
      public BlitEncodeMTL {
  ~BlitCopyTextureToBufferCommandMTL() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(id<MTLBlitCommandEncoder> encoder) const override;
};

struct BlitGenerateMipmapCommandMTL : public BlitGenerateMipmapCommand,
                                      public BlitEncodeMTL {
  ~BlitGenerateMipmapCommandMTL() override;

  std::string GetLabel() const override;

  [[nodiscard]] bool Encode(id<MTLBlitCommandEncoder> encoder) const override;
};

}  // namespace impeller
