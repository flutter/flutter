// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "renderer.h"

#include "flutter/fml/logging.h"

namespace impeller {

Renderer::Renderer() {
  if (!context_.IsValid()) {
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
  return true;
}

bool Renderer::Render() {
  if (!ShouldRender()) {
    return false;
  }

  return true;
}

}  // namespace impeller
