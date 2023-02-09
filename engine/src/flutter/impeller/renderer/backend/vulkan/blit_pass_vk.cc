// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/blit_pass_vk.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

BlitPassVK::BlitPassVK(std::shared_ptr<FencedCommandBufferVK> command_buffer)
    : command_buffer_(std::move(command_buffer)) {}

BlitPassVK::~BlitPassVK() = default;

void BlitPassVK::OnSetLabel(std::string label) {
  if (label.empty()) {
    return;
  }
  label_ = std::move(label);
}

// |BlitPass|
bool BlitPassVK::IsValid() const {
  return command_buffer_ != nullptr;
}

// |BlitPass|
bool BlitPassVK::EncodeCommands(
    const std::shared_ptr<Allocator>& transients_allocator) const {
  TRACE_EVENT0("impeller", "BlitPassVK::EncodeCommands");

  if (!IsValid()) {
    return false;
  }

  for (auto& command : commands_) {
    bool encode_res = command->Encode(command_buffer_.get());
    if (!encode_res) {
      return false;
    }
  }

  return true;
}

// |BlitPass|
bool BlitPassVK::OnCopyTextureToTextureCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<Texture> destination,
    IRect source_region,
    IPoint destination_origin,
    std::string label) {
  auto command = std::make_unique<BlitCopyTextureToTextureCommandVK>();
  command->source = std::move(source);
  command->destination = std::move(destination);
  command->source_region = source_region;
  command->destination_origin = destination_origin;
  command->label = std::move(label);

  commands_.push_back(std::move(command));
  return true;
}

// |BlitPass|
bool BlitPassVK::OnCopyTextureToBufferCommand(
    std::shared_ptr<Texture> source,
    std::shared_ptr<DeviceBuffer> destination,
    IRect source_region,
    size_t destination_offset,
    std::string label) {
  auto command = std::make_unique<BlitCopyTextureToBufferCommandVK>();
  command->source = std::move(source);
  command->destination = std::move(destination);
  command->source_region = source_region;
  command->destination_offset = destination_offset;
  command->label = std::move(label);

  commands_.push_back(std::move(command));
  return true;
}

// |BlitPass|
bool BlitPassVK::OnGenerateMipmapCommand(std::shared_ptr<Texture> texture,
                                         std::string label) {
  auto command = std::make_unique<BlitGenerateMipmapCommandVK>();
  command->texture = std::move(texture);
  command->label = std::move(label);

  commands_.push_back(std::move(command));
  return true;
}

}  // namespace impeller
