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

  MOCK_METHOD(bool, SetLabel, (const std::string& label), (override));

  MOCK_METHOD(bool,
              SetLabel,
              (const std::string& label, Range range),
              (override));

  MOCK_METHOD(uint8_t*, OnGetContents, (), (const, override));

  MOCK_METHOD(bool,
              OnCopyHostBuffer,
              (const uint8_t* source, Range source_range, size_t offset),
              (override));
};

class MockAllocator : public Allocator {
 public:
  MOCK_METHOD(ISize, GetMaxTextureSizeSupported, (), (const, override));
  MOCK_METHOD(std::shared_ptr<DeviceBuffer>,
              OnCreateBuffer,
              (const DeviceBufferDescriptor& desc),
              (override));
  MOCK_METHOD(std::shared_ptr<Texture>,
              OnCreateTexture,
              (const TextureDescriptor& desc),
              (override));
};

class MockBlitPass : public BlitPass {
 public:
  MOCK_METHOD(bool, IsValid, (), (const, override));
  MOCK_METHOD(bool,
              EncodeCommands,
              (const std::shared_ptr<Allocator>& transients_allocator),
              (const, override));
  MOCK_METHOD(void, OnSetLabel, (std::string label), (override));

  MOCK_METHOD(bool,
              OnCopyTextureToTextureCommand,
              (std::shared_ptr<Texture> source,
               std::shared_ptr<Texture> destination,
               IRect source_region,
               IPoint destination_origin,
               std::string label),
              (override));

  MOCK_METHOD(bool,
              OnCopyTextureToBufferCommand,
              (std::shared_ptr<Texture> source,
               std::shared_ptr<DeviceBuffer> destination,
               IRect source_region,
               size_t destination_offset,
               std::string label),
              (override));
  MOCK_METHOD(bool,
              OnCopyBufferToTextureCommand,
              (BufferView source,
               std::shared_ptr<Texture> destination,
               IPoint destination_origin,
               std::string label),
              (override));
  MOCK_METHOD(bool,
              OnGenerateMipmapCommand,
              (std::shared_ptr<Texture> texture, std::string label),
              (override));
};

class MockCommandBuffer : public CommandBuffer {
 public:
  MockCommandBuffer(std::weak_ptr<const Context> context)
      : CommandBuffer(context) {}
  MOCK_METHOD(bool, IsValid, (), (const, override));
  MOCK_METHOD(void, SetLabel, (const std::string& label), (const, override));
  MOCK_METHOD(std::shared_ptr<BlitPass>, OnCreateBlitPass, (), (override));
  MOCK_METHOD(bool,
              OnSubmitCommands,
              (CompletionCallback callback),
              (override));
  MOCK_METHOD(void, OnWaitUntilScheduled, (), (override));
  MOCK_METHOD(std::shared_ptr<ComputePass>,
              OnCreateComputePass,
              (),
              (override));
  MOCK_METHOD(std::shared_ptr<RenderPass>,
              OnCreateRenderPass,
              (RenderTarget render_target),
              (override));
};

class MockImpellerContext : public Context {
 public:
  MOCK_METHOD(Context::BackendType, GetBackendType, (), (const, override));

  MOCK_METHOD(std::string, DescribeGpuModel, (), (const, override));

  MOCK_METHOD(bool, IsValid, (), (const, override));

  MOCK_METHOD(void, Shutdown, (), (override));

  MOCK_METHOD(std::shared_ptr<Allocator>,
              GetResourceAllocator,
              (),
              (const, override));

  MOCK_METHOD(std::shared_ptr<ShaderLibrary>,
              GetShaderLibrary,
              (),
              (const, override));

  MOCK_METHOD(std::shared_ptr<SamplerLibrary>,
              GetSamplerLibrary,
              (),
              (const, override));

  MOCK_METHOD(std::shared_ptr<PipelineLibrary>,
              GetPipelineLibrary,
              (),
              (const, override));

  MOCK_METHOD(std::shared_ptr<CommandBuffer>,
              CreateCommandBuffer,
              (),
              (const, override));

  MOCK_METHOD(const std::shared_ptr<const Capabilities>&,
              GetCapabilities,
              (),
              (const, override));
};

class MockTexture : public Texture {
 public:
  MockTexture(const TextureDescriptor& desc) : Texture(desc) {}
  MOCK_METHOD(void, SetLabel, (std::string_view label), (override));
  MOCK_METHOD(bool, IsValid, (), (const, override));
  MOCK_METHOD(ISize, GetSize, (), (const, override));
  MOCK_METHOD(bool,
              OnSetContents,
              (const uint8_t* contents, size_t length, size_t slice),
              (override));
  MOCK_METHOD(bool,
              OnSetContents,
              (std::shared_ptr<const fml::Mapping> mapping, size_t slice),
              (override));
};

}  // namespace testing
}  // namespace impeller
