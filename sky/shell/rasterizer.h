// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_RASTERIZER_H_
#define SKY_SHELL_RASTERIZER_H_

#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/synchronization/pipeline.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "lib/ftl/synchronization/waitable_event.h"
#include "mojo/public/cpp/bindings/binding.h"

namespace sky {
namespace shell {

class PlatformView;

class Rasterizer {
 public:
  virtual ~Rasterizer();

  virtual void Setup(PlatformView* platform_view,
                     ftl::Closure rasterizer_continuation,
                     ftl::AutoResetWaitableEvent* setup_completion_event) = 0;

  virtual void Teardown(
      ftl::AutoResetWaitableEvent* teardown_completion_event) = 0;

  virtual ftl::WeakPtr<Rasterizer> GetWeakRasterizerPtr() = 0;

  virtual flow::LayerTree* GetLastLayerTree() = 0;

  virtual void Draw(
      ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) = 0;

  // Implemented by each GPU backend.
  static std::unique_ptr<Rasterizer> Create();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_RASTERIZER_H_
