// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/platform_view_mojo.h"

#include "glue/movable_wrapper.h"
#include "sky/shell/gpu/mojo/rasterizer_mojo.h"

namespace sky {
namespace shell {

PlatformViewMojo::PlatformViewMojo() : weak_factory_(this) {}

PlatformViewMojo::~PlatformViewMojo() = default;

void PlatformViewMojo::InitRasterizer(mojo::ApplicationConnectorPtr connector,
                                      mojo::gfx::composition::ScenePtr scene) {
  auto rasterizer = reinterpret_cast<RasterizerMojo*>(config_.rasterizer);
  auto wrapped_connector = glue::WrapMovable(std::move(connector));
  auto wrapped_scene = glue::WrapMovable(std::move(scene));

  NotifyCreated([rasterizer, wrapped_connector, wrapped_scene]() mutable {
    if (rasterizer)
      rasterizer->Init(wrapped_connector.Unwrap(), wrapped_scene.Unwrap());
  });
}

ftl::WeakPtr<sky::shell::PlatformView> PlatformViewMojo::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewMojo::DefaultFramebuffer() const {
  return 0;
}

bool PlatformViewMojo::ContextMakeCurrent() {
  return false;
}

bool PlatformViewMojo::ResourceContextMakeCurrent() {
  return false;
}

bool PlatformViewMojo::SwapBuffers() {
  return false;
}

}  // namespace shell
}  // namespace sky
