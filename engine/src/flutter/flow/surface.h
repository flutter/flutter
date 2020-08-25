// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SURFACE_H_
#define FLUTTER_FLOW_SURFACE_H_

#include <memory>

#include "flutter/flow/embedded_views.h"
#include "flutter/flow/gl_context_switch.h"
#include "flutter/flow/surface_frame.h"
#include "flutter/fml/macros.h"

namespace flutter {

/// Abstract Base Class that represents where we will be rendering content.
class Surface {
 public:
  Surface();

  virtual ~Surface();

  virtual bool IsValid() = 0;

  virtual std::unique_ptr<SurfaceFrame> AcquireFrame(const SkISize& size) = 0;

  virtual SkMatrix GetRootTransformation() const = 0;

  virtual GrDirectContext* GetContext() = 0;

  virtual flutter::ExternalViewEmbedder* GetExternalViewEmbedder();

  virtual std::unique_ptr<GLContextResult> MakeRenderContextCurrent();

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_SURFACE_H_
