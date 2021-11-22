// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/renderer.h"

#include "flutter/fml/logging.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/surface.h"

namespace impeller {

constexpr size_t kMaxFramesInFlight = 3u;

Renderer::Renderer(std::shared_ptr<Context> context)
    : frames_in_flight_sema_(
          std::make_shared<fml::Semaphore>(kMaxFramesInFlight)),
      context_(std::move(context)) {
  if (!context_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

Renderer::~Renderer() = default;

bool Renderer::IsValid() const {
  return is_valid_;
}

bool Renderer::Render(const Surface& surface,
                      RenderCallback render_callback) const {
  if (!IsValid()) {
    return false;
  }

  if (!surface.IsValid()) {
    return false;
  }

  auto command_buffer = context_->CreateRenderCommandBuffer();

  if (!command_buffer) {
    return false;
  }

  auto render_pass =
      command_buffer->CreateRenderPass(surface.GetTargetRenderPassDescriptor());
  if (!render_pass) {
    return false;
  }

  if (render_callback && !render_callback(*render_pass)) {
    return false;
  }

  if (!render_pass->EncodeCommands(*GetContext()->GetTransientsAllocator())) {
    return false;
  }

  if (!frames_in_flight_sema_->Wait()) {
    return false;
  }

  command_buffer->SubmitCommands(
      [sema = frames_in_flight_sema_](CommandBuffer::Status result) {
        sema->Signal();
        if (result != CommandBuffer::Status::kCompleted) {
          FML_LOG(ERROR) << "Could not commit command buffer.";
        }
      });

  return true;
}

std::shared_ptr<Context> Renderer::GetContext() const {
  return context_;
}

}  // namespace impeller
