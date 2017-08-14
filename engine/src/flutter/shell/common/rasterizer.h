// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_COMMON_RASTERIZER_H_
#define SHELL_COMMON_RASTERIZER_H_

#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/shell/common/surface.h"
#include "flutter/synchronization/pipeline.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "lib/ftl/synchronization/waitable_event.h"

namespace shell {

class Rasterizer {
 public:
  virtual ~Rasterizer();

  virtual void Setup(std::unique_ptr<Surface> surface_or_null,
                     ftl::Closure rasterizer_continuation,
                     ftl::AutoResetWaitableEvent* setup_completion_event) = 0;

  virtual void Teardown(
      ftl::AutoResetWaitableEvent* teardown_completion_event) = 0;

  virtual void Clear(SkColor color, const SkISize& size) = 0;

  virtual ftl::WeakPtr<Rasterizer> GetWeakRasterizerPtr() = 0;

  virtual flow::LayerTree* GetLastLayerTree() = 0;

  virtual void Draw(
      ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) = 0;

  // Set a callback to be called once when the next frame is drawn.
  virtual void AddNextFrameCallback(ftl::Closure nextFrameCallback) = 0;
};

}  // namespace shell

#endif  // SHELL_COMMON_RASTERIZER_H_
