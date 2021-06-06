// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/surface.h"

#include "flutter/fml/logging.h"

namespace impeller {

Surface::Surface(RenderPassDescriptor desc) : desc_(std::move(desc)) {
  if (!desc_.HasColorAttachment(0)) {
    return;
  }
  is_valid_ = true;
}

Surface::~Surface() = default;

bool Surface::IsValid() const {
  return is_valid_;
}

const RenderPassDescriptor& Surface::GetRenderPassDescriptor() const {
  return desc_;
}

}  // namespace impeller
