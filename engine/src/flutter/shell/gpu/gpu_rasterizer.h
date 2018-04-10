// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_GPU_DIRECT_GPU_RASTERIZER_H_
#define SHELL_GPU_DIRECT_GPU_RASTERIZER_H_

#include "flutter/flow/compositor_context.h"
#include "flutter/shell/common/rasterizer.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace shell {

class Surface;

class GPURasterizer : public Rasterizer {
 public:
  GPURasterizer(std::unique_ptr<flow::ProcessInfo> info);

  ~GPURasterizer() override;

  void Setup(std::unique_ptr<Surface> surface,
             fxl::Closure continuation,
             fxl::AutoResetWaitableEvent* setup_completion_event) override;

  void Clear(SkColor color, const SkISize& size) override;

  void Teardown(
      fxl::AutoResetWaitableEvent* teardown_completion_event) override;

  fml::WeakPtr<Rasterizer> GetWeakRasterizerPtr() override;

  flow::LayerTree* GetLastLayerTree() override;

  void DrawLastLayerTree() override;

  flow::TextureRegistry& GetTextureRegistry() override;

  void Draw(fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  // Set a callback to be called once when the next frame is drawn.
  void AddNextFrameCallback(fxl::Closure nextFrameCallback) override;

  void SetTextureRegistry(flow::TextureRegistry* textureRegistry) override;

 private:
  std::unique_ptr<Surface> surface_;
  flow::CompositorContext compositor_context_;
  std::unique_ptr<flow::LayerTree> last_layer_tree_;
  // A closure to be called when the underlaying surface presents a frame the
  // next time. NULL if there is no callback or the callback was set back to
  // NULL after being called.
  fxl::Closure nextFrameCallback_;
  fml::WeakPtrFactory<GPURasterizer> weak_factory_;

  void DoDraw(std::unique_ptr<flow::LayerTree> layer_tree);

  void DrawToSurface(flow::LayerTree& layer_tree);

  void NotifyNextFrameOnce();

  FXL_DISALLOW_COPY_AND_ASSIGN(GPURasterizer);
};

}  // namespace shell

#endif  // SHELL_GPU_DIRECT_GPU_RASTERIZER_H_
