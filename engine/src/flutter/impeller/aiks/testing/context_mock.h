// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_MOCK_H_
#define FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_MOCK_H_

#include <string>
#include <utility>
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
  explicit CommandBufferMock(std::weak_ptr<const Context> context)
      : CommandBuffer(std::move(context)) {}

  MOCK_METHOD(bool, IsValid, (), (const, override));

  MOCK_METHOD(void, SetLabel, (const std::string& label), (const, override));

  MOCK_METHOD(std::shared_ptr<RenderPass>,
              OnCreateRenderPass,
              (RenderTarget render_target),
              (override));

  static std::shared_ptr<RenderPass> ForwardOnCreateRenderPass(
      CommandBuffer* command_buffer,
      const RenderTarget& render_target) {
    return command_buffer->OnCreateRenderPass(render_target);
  }

  MOCK_METHOD(std::shared_ptr<BlitPass>, OnCreateBlitPass, (), (override));
  static std::shared_ptr<BlitPass> ForwardOnCreateBlitPass(
      CommandBuffer* command_buffer) {
    return command_buffer->OnCreateBlitPass();
  }

  MOCK_METHOD(bool,
              OnSubmitCommands,
              (CompletionCallback callback),
              (override));
  static bool ForwardOnSubmitCommands(CommandBuffer* command_buffer,
                                      CompletionCallback callback) {
    return command_buffer->OnSubmitCommands(std::move(callback));
  }

  MOCK_METHOD(void, OnWaitUntilScheduled, (), (override));
  static void ForwardOnWaitUntilScheduled(CommandBuffer* command_buffer) {
    return command_buffer->OnWaitUntilScheduled();
  }

  MOCK_METHOD(std::shared_ptr<ComputePass>,
              OnCreateComputePass,
              (),
              (override));
  static std::shared_ptr<ComputePass> ForwardOnCreateComputePass(
      CommandBuffer* command_buffer) {
    return command_buffer->OnCreateComputePass();
  }
};

class ContextMock : public Context {
 public:
  MOCK_METHOD(std::string, DescribeGpuModel, (), (const, override));

  MOCK_METHOD(Context::BackendType, GetBackendType, (), (const, override));

  MOCK_METHOD(bool, IsValid, (), (const, override));

  MOCK_METHOD(const std::shared_ptr<const Capabilities>&,
              GetCapabilities,
              (),
              (const, override));

  MOCK_METHOD(bool,
              UpdateOffscreenLayerPixelFormat,
              (PixelFormat format),
              (override));

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

  MOCK_METHOD(std::shared_ptr<CommandQueue>,
              GetCommandQueue,
              (),
              (const override));

  MOCK_METHOD(void, Shutdown, (), (override));

  MOCK_METHOD(void,
              InitializeCommonlyUsedShadersIfNeeded,
              (),
              (const, override));
};

}  // namespace testing
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_TESTING_CONTEXT_MOCK_H_
