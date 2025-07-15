// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/texture_util.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"

namespace impeller {

std::shared_ptr<Texture> CreateTexture(
    const TextureDescriptor& texture_descriptor,
    const std::vector<uint8_t>& data,
    const std::shared_ptr<impeller::Context>& context,
    std::string_view debug_label) {
  std::shared_ptr<Texture> texture =
      context->GetResourceAllocator()->CreateTexture(texture_descriptor);

  auto data_mapping =
      std::make_shared<fml::NonOwnedMapping>(data.data(), data.size());
  std::shared_ptr<DeviceBuffer> buffer =
      context->GetResourceAllocator()->CreateBufferWithCopy(*data_mapping);

  std::shared_ptr<CommandBuffer> cmd_buffer = context->CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();
  blit_pass->AddCopy(DeviceBuffer::AsBufferView(std::move(buffer)), texture);

  if (!blit_pass->EncodeCommands() ||
      !context->GetCommandQueue()->Submit({std::move(cmd_buffer)}).ok()) {
    return nullptr;
  }

  texture->SetLabel(debug_label);
  return texture;
}

fml::Status AddMipmapGeneration(
    const std::shared_ptr<CommandBuffer>& command_buffer,
    const std::shared_ptr<Context>& context,
    const std::shared_ptr<Texture>& texture) {
  std::shared_ptr<BlitPass> blit_pass = command_buffer->CreateBlitPass();
  bool success = blit_pass->GenerateMipmap(texture);
  if (!success) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  success = blit_pass->EncodeCommands();
  if (!success) {
    return fml::Status(fml::StatusCode::kUnknown, "");
  }
  return fml::Status();
}

}  // namespace impeller
