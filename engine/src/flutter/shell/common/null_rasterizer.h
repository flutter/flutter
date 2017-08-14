// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_
#define FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_

#include "flutter/shell/common/rasterizer.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"

namespace shell {

class NullRasterizer : public Rasterizer {
 public:
  NullRasterizer();

  void Setup(std::unique_ptr<Surface> surface_or_null,
             ftl::Closure rasterizer_continuation,
             ftl::AutoResetWaitableEvent* setup_completion_event) override;

  void Teardown(
      ftl::AutoResetWaitableEvent* teardown_completion_event) override;

  void Clear(SkColor color, const SkISize& size) override;

  ftl::WeakPtr<Rasterizer> GetWeakRasterizerPtr() override;

  flow::LayerTree* GetLastLayerTree() override;

  void Draw(ftl::RefPtr<flutter::Pipeline<flow::LayerTree>> pipeline) override;

  void AddNextFrameCallback(ftl::Closure nextFrameCallback) override;

 private:
  std::unique_ptr<Surface> surface_;
  ftl::WeakPtrFactory<NullRasterizer> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(NullRasterizer);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_NULL_RASTERIZER_H_
