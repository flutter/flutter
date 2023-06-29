// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/testing/context_spy.h"

namespace impeller {
namespace testing {

std::shared_ptr<ContextSpy> ContextSpy::Make() {
  return std::shared_ptr<ContextSpy>(new ContextSpy());
}

std::shared_ptr<ContextMock> ContextSpy::MakeContext(
    const std::shared_ptr<Context>& real_context) {
  std::shared_ptr<ContextMock> mock_context =
      std::make_shared<::testing::NiceMock<ContextMock>>();
  std::shared_ptr<ContextSpy> shared_this = shared_from_this();

  ON_CALL(*mock_context, IsValid).WillByDefault([real_context]() {
    return real_context->IsValid();
  });

  ON_CALL(*mock_context, GetCapabilities)
      .WillByDefault(
          [real_context]() -> const std::shared_ptr<const Capabilities>& {
            return real_context->GetCapabilities();
          });

  ON_CALL(*mock_context, UpdateOffscreenLayerPixelFormat)
      .WillByDefault([real_context](PixelFormat format) {
        return real_context->UpdateOffscreenLayerPixelFormat(format);
      });

  ON_CALL(*mock_context, GetResourceAllocator).WillByDefault([real_context]() {
    return real_context->GetResourceAllocator();
  });

  ON_CALL(*mock_context, GetShaderLibrary).WillByDefault([real_context]() {
    return real_context->GetShaderLibrary();
  });

  ON_CALL(*mock_context, GetSamplerLibrary).WillByDefault([real_context]() {
    return real_context->GetSamplerLibrary();
  });

  ON_CALL(*mock_context, GetPipelineLibrary).WillByDefault([real_context]() {
    return real_context->GetPipelineLibrary();
  });

  ON_CALL(*mock_context, CreateCommandBuffer)
      .WillByDefault([real_context, shared_this]() {
        auto real_buffer = real_context->CreateCommandBuffer();
        auto spy = std::make_shared<::testing::NiceMock<CommandBufferMock>>(
            real_context);

        ON_CALL(*spy, IsValid).WillByDefault([real_buffer]() {
          return real_buffer->IsValid();
        });

        ON_CALL(*spy, SetLabel)
            .WillByDefault([real_buffer](const std::string& label) {
              return real_buffer->SetLabel(label);
            });

        ON_CALL(*spy, SubmitCommandsAsync)
            .WillByDefault([real_buffer](
                               std::shared_ptr<RenderPass> render_pass) {
              return real_buffer->SubmitCommandsAsync(std::move(render_pass));
            });

        ON_CALL(*spy, OnCreateRenderPass)
            .WillByDefault(
                [real_buffer, shared_this](const RenderTarget& render_target) {
                  std::shared_ptr<RenderPass> result =
                      CommandBufferMock::ForwardOnCreateRenderPass(
                          real_buffer.get(), render_target);
                  shared_this->render_passes_.push_back(result);
                  return result;
                });

        ON_CALL(*spy, OnCreateBlitPass).WillByDefault([real_buffer]() {
          return CommandBufferMock::ForwardOnCreateBlitPass(real_buffer.get());
        });

        ON_CALL(*spy, OnSubmitCommands)
            .WillByDefault(
                [real_buffer](CommandBuffer::CompletionCallback callback) {
                  return CommandBufferMock::ForwardOnSubmitCommands(
                      real_buffer.get(), std::move(callback));
                });

        ON_CALL(*spy, OnWaitUntilScheduled).WillByDefault([real_buffer]() {
          return CommandBufferMock::ForwardOnWaitUntilScheduled(
              real_buffer.get());
        });

        ON_CALL(*spy, OnCreateComputePass).WillByDefault([real_buffer]() {
          return CommandBufferMock::ForwardOnCreateComputePass(
              real_buffer.get());
        });

        return spy;
      });

  return mock_context;
}

}  // namespace testing

}  // namespace impeller
