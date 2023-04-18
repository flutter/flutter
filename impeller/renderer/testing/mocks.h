// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "gmock/gmock.h"
#include "impeller/core/allocator.h"
#include "impeller/core/texture.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {
namespace testing {

class MockDeviceBuffer : public DeviceBuffer {
 public:
  MockDeviceBuffer(const DeviceBufferDescriptor& desc) : DeviceBuffer(desc) {}
  MOCK_METHOD3(CopyHostBuffer,
               bool(const uint8_t* source, Range source_range, size_t offset));

  MOCK_METHOD1(SetLabel, bool(const std::string& label));

  MOCK_METHOD2(SetLabel, bool(const std::string& label, Range range));

  MOCK_CONST_METHOD0(OnGetContents, uint8_t*());

  MOCK_METHOD3(OnCopyHostBuffer,
               bool(const uint8_t* source, Range source_range, size_t offset));
};

class MockAllocator : public Allocator {
 public:
  MOCK_CONST_METHOD0(GetMaxTextureSizeSupported, ISize());
  MOCK_METHOD1(
      OnCreateBuffer,
      std::shared_ptr<DeviceBuffer>(const DeviceBufferDescriptor& desc));
  MOCK_METHOD1(OnCreateTexture,
               std::shared_ptr<Texture>(const TextureDescriptor& desc));
};

class MockBlitPass : public BlitPass {
 public:
  MOCK_CONST_METHOD0(IsValid, bool());
  MOCK_CONST_METHOD1(
      EncodeCommands,
      bool(const std::shared_ptr<Allocator>& transients_allocator));
  MOCK_METHOD1(OnSetLabel, void(std::string label));

  MOCK_METHOD5(OnCopyTextureToTextureCommand,
               bool(std::shared_ptr<Texture> source,
                    std::shared_ptr<Texture> destination,
                    IRect source_region,
                    IPoint destination_origin,
                    std::string label));

  MOCK_METHOD5(OnCopyTextureToBufferCommand,
               bool(std::shared_ptr<Texture> source,
                    std::shared_ptr<DeviceBuffer> destination,
                    IRect source_region,
                    size_t destination_offset,
                    std::string label));
  MOCK_METHOD4(OnCopyBufferToTextureCommand,
               bool(BufferView source,
                    std::shared_ptr<Texture> destination,
                    IPoint destination_origin,
                    std::string label));
  MOCK_METHOD2(OnGenerateMipmapCommand,
               bool(std::shared_ptr<Texture> texture, std::string label));
};

class MockCommandBuffer : public CommandBuffer {
 public:
  MockCommandBuffer(std::weak_ptr<const Context> context)
      : CommandBuffer(context) {}
  MOCK_CONST_METHOD0(IsValid, bool());
  MOCK_CONST_METHOD1(SetLabel, void(const std::string& label));
  MOCK_CONST_METHOD0(OnCreateBlitPass, std::shared_ptr<BlitPass>());
  MOCK_METHOD1(OnSubmitCommands, bool(CompletionCallback callback));
  MOCK_CONST_METHOD0(OnCreateComputePass, std::shared_ptr<ComputePass>());
  MOCK_METHOD1(OnCreateRenderPass,
               std::shared_ptr<RenderPass>(RenderTarget render_target));
};

class MockImpellerContext : public Context {
 public:
  MOCK_CONST_METHOD0(DescribeGpuModel, std::string());

  MOCK_CONST_METHOD0(IsValid, bool());

  MOCK_CONST_METHOD0(GetResourceAllocator, std::shared_ptr<Allocator>());

  MOCK_CONST_METHOD0(GetShaderLibrary, std::shared_ptr<ShaderLibrary>());

  MOCK_CONST_METHOD0(GetSamplerLibrary, std::shared_ptr<SamplerLibrary>());

  MOCK_CONST_METHOD0(GetPipelineLibrary, std::shared_ptr<PipelineLibrary>());

  MOCK_CONST_METHOD0(CreateCommandBuffer, std::shared_ptr<CommandBuffer>());

  MOCK_CONST_METHOD0(GetCapabilities,
                     const std::shared_ptr<const Capabilities>&());
};

class MockTexture : public Texture {
 public:
  MockTexture(const TextureDescriptor& desc) : Texture(desc) {}
  MOCK_METHOD1(SetLabel, void(std::string_view label));
  MOCK_METHOD3(SetContents,
               bool(const uint8_t* contents, size_t length, size_t slice));
  MOCK_METHOD2(SetContents,
               bool(std::shared_ptr<const fml::Mapping> mapping, size_t slice));
  MOCK_CONST_METHOD0(IsValid, bool());
  MOCK_CONST_METHOD0(GetSize, ISize());
  MOCK_METHOD3(OnSetContents,
               bool(const uint8_t* contents, size_t length, size_t slice));
  MOCK_METHOD2(OnSetContents,
               bool(std::shared_ptr<const fml::Mapping> mapping, size_t slice));
};

}  // namespace testing
}  // namespace impeller
