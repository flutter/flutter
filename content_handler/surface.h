// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "compositor_context.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/common/surface.h"
#include "lib/fxl/macros.h"

namespace flutter {

// The interface between the Flutter rasterizer and the underlying platform. May
// be constructed on any thread but will be used by the engine only on the GPU
// thread.
class Surface final : public shell::Surface {
 public:
  Surface(std::string debug_label);

  ~Surface() override;

 private:
  const bool valid_ = CanConnectToDisplay();
  const std::string debug_label_;

  // |shell::Surface|
  bool IsValid() override;

  // |shell::Surface|
  std::unique_ptr<shell::SurfaceFrame> AcquireFrame(
      const SkISize& size) override;

  // |shell::Surface|
  GrContext* GetContext() override;

  static bool CanConnectToDisplay();

  FXL_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace flutter
