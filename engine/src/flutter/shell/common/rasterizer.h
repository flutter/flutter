// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_RASTERIZER_H_
#define SHELL_COMMON_RASTERIZER_H_

#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/surface.h"
#include "flutter/synchronization/pipeline.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace shell {

class Rasterizer {
 public:
  virtual ~Rasterizer();

  virtual void Setup(std::unique_ptr<Surface> surface_or_null,
                     fxl::Closure rasterizer_continuation,
                     fxl::AutoResetWaitableEvent* setup_completion_event) = 0;

  virtual void Teardown(
      fxl::AutoResetWaitableEvent* teardown_completion_event) = 0;

  virtual void Clear(SkColor color, const SkISize& size) = 0;

  virtual fml::WeakPtr<Rasterizer> GetWeakRasterizerPtr() = 0;

  virtual flow::LayerTree* GetLastLayerTree() = 0;

  virtual void DrawLastLayerTree() = 0;

  virtual flow::TextureRegistry& GetTextureRegistry() = 0;

  virtual void Draw(
      fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) = 0;

  // Set a callback to be called once when the next frame is drawn.
  virtual void AddNextFrameCallback(fxl::Closure nextFrameCallback) = 0;

  virtual void SetTextureRegistry(flow::TextureRegistry* textureRegistry) = 0;
};

}  // namespace shell

#endif  // SHELL_COMMON_RASTERIZER_H_
