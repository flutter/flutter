// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/renderer.h"

#include <algorithm>

#include "flutter/fml/trace_event.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/surface.h"

namespace impeller {

Renderer::Renderer(std::shared_ptr<Context> context,
                   size_t max_frames_in_flight)
    : frames_in_flight_sema_(std::make_shared<fml::Semaphore>(
          std::max<std::size_t>(1u, max_frames_in_flight))),
      context_(std::move(context)) {
  if (!context_ || !context_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

Renderer::~Renderer() = default;

bool Renderer::IsValid() const {
  return is_valid_;
}

bool Renderer::Render(std::unique_ptr<Surface> surface,
                      const RenderCallback& render_callback) const {
  TRACE_EVENT0("impeller", "Renderer::Render");
  if (!IsValid()) {
    return false;
  }

  if (!surface || !surface->IsValid()) {
    return false;
  }

  RenderTarget render_target = surface->GetTargetRenderPassDescriptor();

  if (render_callback && !render_callback(render_target)) {
    return false;
  }

  if (!frames_in_flight_sema_->Wait()) {
    return false;
  }

  const auto present_result = surface->Present();

  frames_in_flight_sema_->Signal();

  return present_result;
}

std::shared_ptr<Context> Renderer::GetContext() const {
  return context_;
}

}  // namespace impeller
