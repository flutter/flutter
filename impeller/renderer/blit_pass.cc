// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/blit_pass.h"
#include <memory>

#include "impeller/base/strings.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/blit_command.h"
#include "impeller/renderer/host_buffer.h"

namespace impeller {

BlitPass::BlitPass() : transients_buffer_(HostBuffer::Create()) {}

BlitPass::~BlitPass() = default;

HostBuffer& BlitPass::GetTransientsBuffer() {
  return *transients_buffer_;
}

void BlitPass::SetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  transients_buffer_->SetLabel(SPrintF("%s Transients", label.c_str()));
  OnSetLabel(std::move(label));
}

bool BlitPass::AddCopy(std::shared_ptr<Texture> source,
                       std::shared_ptr<Texture> destination,
                       std::optional<IRect> source_region,
                       IPoint destination_origin,
                       std::string label) {
  if (!source) {
    VALIDATION_LOG << "Attempted to add a texture blit with no source.";
    return false;
  }
  if (!destination) {
    VALIDATION_LOG << "Attempted to add a texture blit with no destination.";
    return false;
  }

  if (source->GetTextureDescriptor().sample_count !=
      destination->GetTextureDescriptor().sample_count) {
    VALIDATION_LOG << SPrintF(
        "The source sample count (%d) must match the destination sample count "
        "(%d) for blits.",
        source->GetTextureDescriptor().sample_count,
        destination->GetTextureDescriptor().sample_count);
    return false;
  }

  if (!source_region.has_value()) {
    source_region = IRect::MakeSize(source->GetSize());
  }

  // Clip the source image.
  source_region =
      source_region->Intersection(IRect::MakeSize(source->GetSize()));
  if (!source_region.has_value()) {
    return true;  // Nothing to blit.
  }

  // Clip the destination image.
  source_region = source_region->Intersection(
      IRect(-destination_origin, destination->GetSize()));
  if (!source_region.has_value()) {
    return true;  // Nothing to blit.
  }

  OnCopyTextureToTextureCommand(std::move(source), std::move(destination),
                                source_region.value(), destination_origin,
                                label);
  return true;
}

bool BlitPass::GenerateMipmap(std::shared_ptr<Texture> texture,
                              std::string label) {
  if (!texture) {
    VALIDATION_LOG << "Attempted to add an invalid mipmap generation command "
                      "with no texture.";
    return false;
  }

  OnGenerateMipmapCommand(std::move(texture), label);
  return true;
}

}  // namespace impeller
