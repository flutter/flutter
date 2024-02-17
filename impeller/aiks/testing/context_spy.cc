// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/command_queue.h"

#include "impeller/aiks/testing/context_spy.h"

namespace impeller {
namespace testing {

fml::Status NoopCommandQueue::Submit(
    const std::vector<std::shared_ptr<CommandBuffer>>& buffers,
    const CompletionCallback& completion_callback) {
  if (completion_callback) {
    completion_callback(CommandBuffer::Status::kCompleted);
  }
  return fml::Status();
}

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

  ON_CALL(*mock_context, GetBackendType)
      .WillByDefault([real_context]() -> Context::BackendType {
        return real_context->GetBackendType();
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

  ON_CALL(*mock_context, GetCommandQueue).WillByDefault([shared_this]() {
    return shared_this->command_queue_;
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

        ON_CALL(*spy, OnCreateRenderPass)
            .WillByDefault([real_buffer, shared_this,
                            real_context](const RenderTarget& render_target) {
              std::shared_ptr<RenderPass> result =
                  CommandBufferMock::ForwardOnCreateRenderPass(
                      real_buffer.get(), render_target);
              std::shared_ptr<RecordingRenderPass> recorder =
                  std::make_shared<RecordingRenderPass>(result, real_context,
                                                        render_target);
              shared_this->render_passes_.push_back(recorder);
              return recorder;
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
