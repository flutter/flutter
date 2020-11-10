// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SURFACE_FRAME_H_
#define FLUTTER_FLOW_SURFACE_FRAME_H_

#include <memory>

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {

// This class represents a frame that has been fully configured for the
// underlying client rendering API. A frame may only be submitted once.
class SurfaceFrame {
 public:
  using SubmitCallback =
      std::function<bool(const SurfaceFrame& surface_frame, SkCanvas* canvas)>;

  SurfaceFrame(sk_sp<SkSurface> surface,
               bool supports_readback,
               const SubmitCallback& submit_callback);

  SurfaceFrame(sk_sp<SkSurface> surface,
               bool supports_readback,
               const SubmitCallback& submit_callback,
               std::unique_ptr<GLContextResult> context_result);

  ~SurfaceFrame();

  bool Submit();

  bool IsSubmitted() const;

  SkCanvas* SkiaCanvas();

  sk_sp<SkSurface> SkiaSurface() const;

  bool supports_readback() { return supports_readback_; }

 private:
  bool submitted_ = false;
  sk_sp<SkSurface> surface_;
  bool supports_readback_;
  SubmitCallback submit_callback_;
  std::unique_ptr<GLContextResult> context_result_;

  bool PerformSubmit();

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceFrame);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_SURFACE_FRAME_H_
