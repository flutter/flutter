// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <Metal/Metal.h>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/metal/blit_command_mtl.h"
#include "impeller/renderer/blit_pass.h"

namespace impeller {

class BlitPassMTL final : public BlitPass {
 public:
  // |RenderPass|
  ~BlitPassMTL() override;

 private:
  friend class CommandBufferMTL;

  std::vector<std::unique_ptr<BlitEncodeMTL>> commands_;
  id<MTLCommandBuffer> buffer_ = nil;
  std::string label_;
  bool is_valid_ = false;

  explicit BlitPassMTL(id<MTLCommandBuffer> buffer);

  // |BlitPass|
  bool IsValid() const override;

  // |BlitPass|
  void OnSetLabel(std::string label) override;

  // |BlitPass|
  bool EncodeCommands(
      const std::shared_ptr<Allocator>& transients_allocator) const override;

  bool EncodeCommands(id<MTLBlitCommandEncoder> pass) const;

  // |BlitPass|
  bool OnCopyTextureToTextureCommand(std::shared_ptr<Texture> source,
                                     std::shared_ptr<Texture> destination,
                                     IRect source_region,
                                     IPoint destination_origin,
                                     std::string label) override;

  // |BlitPass|
  bool OnCopyTextureToBufferCommand(std::shared_ptr<Texture> source,
                                    std::shared_ptr<DeviceBuffer> destination,
                                    IRect source_region,
                                    size_t destination_offset,
                                    std::string label) override;
  // |BlitPass|
  bool OnCopyBufferToTextureCommand(BufferView source,
                                    std::shared_ptr<Texture> destination,
                                    IPoint destination_origin,
                                    std::string label) override;

  // |BlitPass|
  bool OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                               std::string label) override;

  BlitPassMTL(const BlitPassMTL&) = delete;

  BlitPassMTL& operator=(const BlitPassMTL&) = delete;
};

}  // namespace impeller
