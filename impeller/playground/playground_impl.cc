// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_impl.h"

#include "impeller/playground/backend/gles/playground_impl_gles.h"
#include "impeller/playground/backend/metal/playground_impl_mtl.h"

namespace impeller {

std::unique_ptr<PlaygroundImpl> PlaygroundImpl::Create(
    PlaygroundBackend backend) {
  switch (backend) {
    case PlaygroundBackend::kMetal:
      return std::make_unique<PlaygroundImplMTL>();
    case PlaygroundBackend::kOpenGLES:
      return std::make_unique<PlaygroundImplGLES>();
  }
  FML_UNREACHABLE();
}

PlaygroundImpl::PlaygroundImpl() = default;

PlaygroundImpl::~PlaygroundImpl() = default;

}  // namespace impeller
