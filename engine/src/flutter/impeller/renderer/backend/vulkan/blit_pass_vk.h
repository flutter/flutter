// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/blit_pass.h"

namespace impeller {

class BlitPassVK final : public BlitPass {
 public:
  // |BlitPass|
  ~BlitPassVK() override;

 private:
  friend class CommandBufferVK;

  BlitPassVK();

  // |BlitPass|
  bool IsValid() const override;

  // |BlitPass|
  void OnSetLabel(std::string label) override;

  // |BlitPass|
  bool EncodeCommands(
      const std::shared_ptr<Allocator>& transients_allocator) const override;

  // |BlitPass|
  void OnCopyTextureToTextureCommand(std::shared_ptr<Texture> source,
                                     std::shared_ptr<Texture> destination,
                                     IRect source_region,
                                     IPoint destination_origin,
                                     std::string label) override;

  // |BlitPass|
  void OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                               std::string label) override;

  FML_DISALLOW_COPY_AND_ASSIGN(BlitPassVK);
};

}  // namespace impeller
