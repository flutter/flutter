// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/renderer.h"

#include "flutter/fml/logging.h"

namespace impeller {

Renderer::Renderer(std::string shaders_directory)
    : context_(std::make_shared<Context>(std::move(shaders_directory))),
      surface_(std::make_unique<Surface>(context_)) {
  if (!context_->IsValid()) {
    return;
  }

  if (!surface_->IsValid()) {
    return;
  }

  is_valid_ = true;
}

Renderer::~Renderer() = default;

bool Renderer::IsValid() const {
  return is_valid_;
}

bool Renderer::ShouldRender() const {
  return IsValid() && !size_.IsZero();
}

bool Renderer::SurfaceSizeDidChange(Size size) {
  if (size_ == size) {
    return true;
  }

  size_ = size;

  return OnSurfaceSizeDidChange(size_);
}

bool Renderer::Render() {
  if (!ShouldRender()) {
    return false;
  }

  return surface_->Render();
}

std::shared_ptr<Context> Renderer::GetContext() const {
  return context_;
}

}  // namespace impeller
