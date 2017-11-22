// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_
#define FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_

#include "flutter/shell/common/rasterizer.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"

namespace shell {

class NullRasterizer : public Rasterizer {
 public:
  NullRasterizer();

  void Setup(std::unique_ptr<Surface> surface_or_null,
             fxl::Closure rasterizer_continuation,
             fxl::AutoResetWaitableEvent* setup_completion_event) override;

  void Teardown(
      fxl::AutoResetWaitableEvent* teardown_completion_event) override;

  void Clear(SkColor color, const SkISize& size) override;

  fml::WeakPtr<Rasterizer> GetWeakRasterizerPtr() override;

  flow::LayerTree* GetLastLayerTree() override;

  void DrawLastLayerTree() override;

  flow::TextureRegistry& GetTextureRegistry() override;

  void Draw(fxl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  void AddNextFrameCallback(fxl::Closure nextFrameCallback) override;

 private:
  std::unique_ptr<Surface> surface_;
  fml::WeakPtrFactory<NullRasterizer> weak_factory_;
  flow::TextureRegistry texture_registry_;

  FXL_DISALLOW_COPY_AND_ASSIGN(NullRasterizer);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_
