// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_SURFACE_H_
#define FLUTTER_SHELL_COMMON_SURFACE_H_

#include <memory>

#include "flutter/flow/compositor_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace shell {

/// Represents a Frame that has been fully configured for the underlying client
/// rendering API. A frame may only be sumitted once.
class SurfaceFrame {
 public:
  using SubmitCallback =
      std::function<bool(const SurfaceFrame& surface_frame, SkCanvas* canvas)>;

  SurfaceFrame(sk_sp<SkSurface> surface, SubmitCallback submit_callback);

  ~SurfaceFrame();

  bool Submit();

  SkCanvas* SkiaCanvas();

  sk_sp<SkSurface> SkiaSurface() const;

 private:
  bool submitted_;
  sk_sp<SkSurface> surface_;
  std::unique_ptr<SkCanvas> xform_canvas_;
  SubmitCallback submit_callback_;

  bool PerformSubmit();

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceFrame);
};

class Surface {
 public:
  Surface();

  virtual ~Surface();

  virtual bool IsValid() = 0;

  virtual std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) = 0;

  virtual SkMatrix GetRootTransformation() const = 0;

  virtual GrContext* GetContext() = 0;

  virtual flow::ExternalViewEmbedder* GetExternalViewEmbedder();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_SURFACE_H_
