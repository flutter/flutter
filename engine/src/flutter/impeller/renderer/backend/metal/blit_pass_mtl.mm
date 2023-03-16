// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/blit_pass_mtl.h"
#include <Metal/Metal.h>
#include <memory>
#include <variant>

#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/metal/blit_command_mtl.h"
#include "impeller/renderer/backend/metal/device_buffer_mtl.h"
#include "impeller/renderer/backend/metal/formats_mtl.h"
#include "impeller/renderer/backend/metal/pipeline_mtl.h"
#include "impeller/renderer/backend/metal/sampler_mtl.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "impeller/renderer/blit_command.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/shader_types.h"

namespace impeller {

BlitPassMTL::BlitPassMTL(id<MTLCommandBuffer> buffer) : buffer_(buffer) {
  if (!buffer_) {
    return;
  }
  is_valid_ = true;
}

BlitPassMTL::~BlitPassMTL() = default;

bool BlitPassMTL::IsValid() const {
  return is_valid_;
}

void BlitPassMTL::OnSetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  label_ = std::move(label);
}

bool BlitPassMTL::EncodeCommands(
    const std::shared_ptr<Allocator>& transients_allocator) const {
  TRACE_EVENT0("impeller", "BlitPassMTL::EncodeCommands");
  if (!IsValid()) {
    return false;
  }

  auto blit_command_encoder = [buffer_ blitCommandEncoder];

  if (!blit_command_encoder) {
    return false;
  }

  if (!label_.empty()) {
    [blit_command_encoder setLabel:@(label_.c_str())];
  }

  // Success or failure, the pass must end. The buffer can only process one pass
  // at a time.
  fml::ScopedCleanupClosure auto_end(
      [blit_command_encoder]() { [blit_command_encoder endEncoding]; });

  return EncodeCommands(blit_command_encoder);
}

bool BlitPassMTL::EncodeCommands(id<MTLBlitCommandEncoder> encoder) const {
  fml::closure pop_debug_marker = [encoder]() { [encoder popDebugGroup]; };
  for (const auto& command : commands_) {
    fml::ScopedCleanupClosure auto_pop_debug_marker(pop_debug_marker);
    auto label = command->GetLabel();
    if (!label.empty()) {
      [encoder pushDebugGroup:@(label.c_str())];
    } else {
      auto_pop_debug_marker.Release();
    }

    if (!command->Encode(encoder)) {
      return false;
    }
  }
  return true;
}

// |BlitPass|
bool BlitPassMTL::OnCopyTextureToTextureCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<Texture> destination,
    IRect source_region,
    IPoint destination_origin,
    std::string label) {
  auto command = std::make_unique<BlitCopyTextureToTextureCommandMTL>();
  command->label = label;
  command->source = std::move(source);
  command->destination = std::move(destination);
  command->source_region = source_region;
  command->destination_origin = destination_origin;

  commands_.emplace_back(std::move(command));
  return true;
}

// |BlitPass|
bool BlitPassMTL::OnCopyTextureToBufferCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<DeviceBuffer> destination,
    IRect source_region,
    size_t destination_offset,
    std::string label) {
  auto command = std::make_unique<BlitCopyTextureToBufferCommandMTL>();
  command->label = label;
  command->source = std::move(source);
  command->destination = std::move(destination);
  command->source_region = source_region;
  command->destination_offset = destination_offset;

  commands_.emplace_back(std::move(command));
  return true;
}

// |BlitPass|
bool BlitPassMTL::OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                                          std::string label) {
  auto command = std::make_unique<BlitGenerateMipmapCommandMTL>();
  command->label = label;
  command->texture = std::move(texture);

  commands_.emplace_back(std::move(command));
  return true;
}

// |BlitPass|
bool BlitPassMTL::OnOptimizeForGPUAccess(std::shared_ptr<Texture> texture,
                                         std::string label) {
  auto command = std::make_unique<BlitOptimizeGPUAccessCommandMTL>();
  command->label = label;
  command->texture = std::move(texture);

  commands_.emplace_back(std::move(command));
  return true;
}

}  // namespace impeller
