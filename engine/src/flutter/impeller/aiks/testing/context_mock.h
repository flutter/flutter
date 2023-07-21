// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>
#include <vector>

#include "gmock/gmock-function-mocker.h"
#include "gmock/gmock.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_target.h"

namespace impeller {
namespace testing {

class CommandBufferMock : public CommandBuffer {
 public:
  CommandBufferMock(std::weak_ptr<const Context> context)
      : CommandBuffer(context) {}

  MOCK_CONST_METHOD0(IsValid, bool());

  MOCK_CONST_METHOD1(SetLabel, void(const std::string& label));

  MOCK_METHOD1(SubmitCommandsAsync,
               bool(std::shared_ptr<RenderPass> render_pass));

  MOCK_METHOD1(OnCreateRenderPass,
               std::shared_ptr<RenderPass>(RenderTarget render_target));

  static std::shared_ptr<RenderPass> ForwardOnCreateRenderPass(
      CommandBuffer* command_buffer,
      RenderTarget render_target) {
    return command_buffer->OnCreateRenderPass(render_target);
  }

  MOCK_METHOD0(OnCreateBlitPass, std::shared_ptr<BlitPass>());
  static std::shared_ptr<BlitPass> ForwardOnCreateBlitPass(
      CommandBuffer* command_buffer) {
    return command_buffer->OnCreateBlitPass();
  }

  MOCK_METHOD1(OnSubmitCommands, bool(CompletionCallback callback));
  static bool ForwardOnSubmitCommands(CommandBuffer* command_buffer,
                                      CompletionCallback callback) {
    return command_buffer->OnSubmitCommands(callback);
  }

  MOCK_METHOD0(OnWaitUntilScheduled, void());
  static void ForwardOnWaitUntilScheduled(CommandBuffer* command_buffer) {
    return command_buffer->OnWaitUntilScheduled();
  }

  MOCK_METHOD0(OnCreateComputePass, std::shared_ptr<ComputePass>());
  static std::shared_ptr<ComputePass> ForwardOnCreateComputePass(
      CommandBuffer* command_buffer) {
    return command_buffer->OnCreateComputePass();
  }
};

class ContextMock : public Context {
 public:
  MOCK_CONST_METHOD0(DescribeGpuModel, std::string());

  MOCK_CONST_METHOD0(GetBackendType, Context::BackendType());

  MOCK_CONST_METHOD0(IsValid, bool());

  MOCK_CONST_METHOD0(GetCapabilities,
                     const std::shared_ptr<const Capabilities>&());

  MOCK_METHOD1(UpdateOffscreenLayerPixelFormat, bool(PixelFormat format));

  MOCK_CONST_METHOD0(GetResourceAllocator, std::shared_ptr<Allocator>());

  MOCK_CONST_METHOD0(GetShaderLibrary, std::shared_ptr<ShaderLibrary>());

  MOCK_CONST_METHOD0(GetSamplerLibrary, std::shared_ptr<SamplerLibrary>());

  MOCK_CONST_METHOD0(GetPipelineLibrary, std::shared_ptr<PipelineLibrary>());

  MOCK_CONST_METHOD0(CreateCommandBuffer, std::shared_ptr<CommandBuffer>());

  MOCK_METHOD0(Shutdown, void());
};

}  // namespace testing
}  // namespace impeller
