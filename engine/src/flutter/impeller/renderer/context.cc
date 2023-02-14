// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/context.h"

namespace impeller {

Context::~Context() = default;

Context::Context() = default;

std::shared_ptr<GPUTracer> Context::GetGPUTracer() const {
  return nullptr;
}

PixelFormat Context::GetColorAttachmentPixelFormat() const {
  return PixelFormat::kDefaultColor;
}

}  // namespace impeller
